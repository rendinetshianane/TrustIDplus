# encryption_tool.py
import os
from cryptography.fernet import Fernet
from dotenv import load_dotenv, set_key

# Load environment variables from .env
load_dotenv()

# Path to .env
ENV_FILE = ".env"

# Check if ENCRYPTION_KEY exists
key = os.getenv("ENCRYPTION_KEY")

if not key:
    key = Fernet.generate_key().decode()
    set_key(ENV_FILE, "ENCRYPTION_KEY", key)
    print("✅ New ENCRYPTION_KEY generated and saved to .env")
else:
    print("🔑 Using existing ENCRYPTION_KEY from .env")

# Keep ENV intact (just confirm)
env = os.getenv("ENV", "production")
set_key(ENV_FILE, "ENV", env)


class EncryptionTool:
    def __init__(self):
        self.key = self._load_key()
        self.cipher = Fernet(self.key)

    def _load_key(self):
        """
        Load the Fernet encryption key from .env.
        If the key is invalid or missing, generate a new one and save it.
        """
        key = os.getenv("ENCRYPTION_KEY")

        if key:
            try:
                # Ensure the key is valid
                Fernet(key.encode())
                return key.encode()
            except Exception:
                print("⚠️ Invalid ENCRYPTION_KEY found in .env, generating a new one...")
        
        # If key not found or invalid, generate a new one
        new_key = Fernet.generate_key()
        self._save_key_to_env(new_key)
        print("✅ New ENCRYPTION_KEY generated and saved to .env")
        return new_key

    def _save_key_to_env(self, key: bytes):
        """
        Save the new key into .env file safely.
        """
        env_path = ".env"
        lines = []
        found = False

        if os.path.exists(env_path):
            with open(env_path, "r") as f:
                lines = f.readlines()

        with open(env_path, "w") as f:
            for line in lines:
                if line.startswith("ENCRYPTION_KEY="):
                    f.write(f"ENCRYPTION_KEY={key.decode()}\n")
                    found = True
                else:
                    f.write(line)
            if not found:
                f.write(f"ENCRYPTION_KEY={key.decode()}\n")

    def encrypt(self, data: str) -> str:
        """Encrypt plain text string."""
        return self.cipher.encrypt(data.encode()).decode()

    def decrypt(self, token: str) -> str:
        """Decrypt encrypted string."""
        return self.cipher.decrypt(token.encode()).decode()