# api_server.py
import json
import base64
from fastapi import FastAPI
from pydantic import BaseModel
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from dotenv import load_dotenv
import os

load_dotenv()

app = FastAPI(title="Banking Cybersecurity API")

# Load 32-byte AES key from .env
AES_KEY = base64.b64decode(os.getenv("AES_KEY_B64"))

class MessageRequest(BaseModel):
    message: str  # Encrypted message in base64

@app.post("/phishing")
def check_phishing(request: MessageRequest):
    try:
        # Decode the base64 encrypted payload
        encrypted = base64.b64decode(request.message)
        # AESGCM expects: first 12 bytes = nonce, rest = ciphertext + tag
        nonce = encrypted[:12]
        ciphertext = encrypted[12:]
        aesgcm = AESGCM(AES_KEY)
        decrypted_message = aesgcm.decrypt(nonce, ciphertext, None).decode()

        # Dummy phishing logic
        flags = []
        score = 0
        if "bank" in decrypted_message.lower() or "password" in decrypted_message.lower():
            flags.append("Contains sensitive keyword")
            score = 85
        else:
            score = 10

        # Prepare response
        response = {"score": score, "flags": flags}
        # Encrypt response
        aesgcm_resp = AESGCM(AES_KEY)
        resp_nonce = AESGCM.generate_key(bit_length=96)  # 12 bytes nonce
        resp_nonce_bytes = os.urandom(12)
        ciphertext_resp = aesgcm_resp.encrypt(resp_nonce_bytes, json.dumps(response).encode(), None)
        resp_b64 = base64.b64encode(resp_nonce_bytes + ciphertext_resp).decode()

        return {"encrypted": resp_b64}
    except Exception as e:
        return {"error": str(e)}