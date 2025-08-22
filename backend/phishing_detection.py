# phishing_detection.py
import os
import re
import json
import base64
import ipaddress
from typing import List, Dict, Any, Tuple
import requests

URL_REGEX = re.compile(r'(https?://[^\s<>"\'\)]{3,})', re.IGNORECASE)

SUSPICIOUS_KEYWORDS = [
    "login", "verify", "update", "reset", "bank", "secure", "password",
    "unlock", "support", "confirm", "credential", "invoice", "wallet"
]

def extract_urls(text: str) -> List[str]:
    urls = URL_REGEX.findall(text or "")
    # Normalize basic trailing punctuation
    cleaned = []
    for u in urls:
        cleaned.append(u.rstrip('.,);:!?"\''))
    return list(dict.fromkeys(cleaned))  # dedupe, preserve order

def looks_like_ip(host: str) -> bool:
    try:
        ipaddress.ip_address(host)
        return True
    except ValueError:
        return False

def host_from_url(url: str) -> str:
    try:
        # Avoid importing urllib for speed; simple parse
        no_scheme = url.split("://", 1)[-1]
        host_port = no_scheme.split("/", 1)[0]
        host = host_port.split("@")[-1].split(":")[0]
        return host.lower()
    except Exception:
        return ""

def has_punycode(host: str) -> bool:
    return "xn--" in host

def mixed_script(host: str) -> bool:
    # Very simple check: if there are characters outside basic ASCII
    return any(ord(c) > 127 for c in host)

def suspicious_heuristics(url: str) -> Tuple[bool, List[str]]:
    reasons = []
    host = host_from_url(url)

    # Suspicious keywords in URL path or domain
    lower_url = url.lower()
    if any(k in lower_url for k in SUSPICIOUS_KEYWORDS):
        reasons.append("suspicious_keywords")

    # IP address instead of domain (often used by phishers)
    if looks_like_ip(host):
        reasons.append("ip_in_host")

    # Punycode or mixed scripts (IDN homograph)
    if has_punycode(host):
        reasons.append("punycode_host")
    if mixed_script(host):
        reasons.append("non_ascii_host")

    # Excessive subdomains (e.g., bank.secure.account.verify.example.com)
    if host.count(".") >= 4:
        reasons.append("many_subdomains")

    # URL has @ which can hide real destination (user@host)
    if "@" in url.split("://", 1)[-1].split("/")[0]:
        reasons.append("at_symbol_in_authority")

    return (len(reasons) > 0, reasons)

def check_urls_gsb(urls: List[str]) -> Dict[str, Any]:
    """
    Google Safe Browsing v4 lookup.
    Requires env var: GSB_API_KEY
    Returns dict { "supported": bool, "matches": {url: threat_type list}, "error": str|None }
    """
    api_key = os.getenv("GSB_API_KEY")
    if not api_key:
        return {"supported": False, "matches": {}, "error": None}

    endpoint = f"https://safebrowsing.googleapis.com/v4/threatMatches:find?key={api_key}"
    body = {
        "client": {"clientId": "trustid-demo", "clientVersion": "1.0"},
        "threatInfo": {
            "threatTypes": [
                "MALWARE",
                "SOCIAL_ENGINEERING",
                "UNWANTED_SOFTWARE",
                "POTENTIALLY_HARMFUL_APPLICATION",
                "THREAT_TYPE_UNSPECIFIED"
            ],
            "platformTypes": ["ANY_PLATFORM"],
            "threatEntryTypes": ["URL"],
            "threatEntries": [{"url": u} for u in urls]
        }
    }

    try:
        resp = requests.post(endpoint, json=body, timeout=6)
        resp.raise_for_status()
        data = resp.json()
        matches_by_url: Dict[str, List[str]] = {}
        for m in data.get("matches", []):
            url = m.get("threat", {}).get("url")
            ttype = m.get("threatType")
            if url:
                matches_by_url.setdefault(url, []).append(ttype)
        return {"supported": True, "matches": matches_by_url, "error": None}
    except requests.RequestException as e:
        return {"supported": True, "matches": {}, "error": str(e)}

def score_message(text: str) -> Dict[str, Any]:
    """
    Returns a structured assessment with:
      - urls found
      - per-url heuristic flags
      - GSB matches (if available)
      - overall_risk (LOW/MEDIUM/HIGH)
    """
    urls = extract_urls(text)
    url_results = []
    heuristic_hits_total = 0

    # Heuristic checks per URL
    for u in urls:
        flagged, reasons = suspicious_heuristics(u)
        if flagged:
            heuristic_hits_total += 1
        url_results.append({
            "url": u,
            "heuristics_flagged": flagged,
            "heuristic_reasons": reasons
        })

    # Google Safe Browsing check
    gsb = check_urls_gsb(urls) if urls else {"supported": False, "matches": {}, "error": None}
    gsb_hits_total = sum(len(v) for v in gsb.get("matches", {}).values())

    # Simple risk policy (tune as needed)
    if gsb_hits_total > 0:
        overall_risk = "HIGH"
    elif heuristic_hits_total >= 2:
        overall_risk = "MEDIUM"
    elif heuristic_hits_total == 1:
        overall_risk = "LOW"
    else:
        overall_risk = "LOW"

    # Merge GSB matches back into per-url results
    for r in url_results:
        r["gsb_matches"] = gsb.get("matches", {}).get(r["url"], [])

    return {
        "found_urls": urls,
        "url_assessments": url_results,
        "gsb_supported": gsb.get("supported", False),
        "gsb_error": gsb.get("error"),
        "overall_risk": overall_risk,
        "is_phishing": overall_risk in ("MEDIUM", "HIGH")
    }

if __name__ == "__main__":
    sample = "Dear user, verify your account: http://fakebank-login.com and https://accounts.example.com/reset"
    print(json.dumps(score_message(sample), indent=2))