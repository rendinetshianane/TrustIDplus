from cryptography.hazmat.primitives.ciphers.aead import AESGCM
import os, base64

key = base64.b64decode("yYlpuPzXYKJ+sNlNY+jMqFH79uIIMZ5rEKO1SOdsCBc=")
aesgcm = AESGCM(key)
nonce = os.urandom(12)
message = b"Hello phishing test"

encrypted = aesgcm.encrypt(nonce, message, None)
combined = nonce + encrypted
print("Encrypted base64:", base64.b64encode(combined).decode())

# Decrypt
enc = base64.b64decode(base64.b64encode(combined))
nonce2 = enc[:12]
ciphertext = enc[12:]
decrypted = aesgcm.decrypt(nonce2, ciphertext, None)
print("Decrypted:", decrypted.decode())