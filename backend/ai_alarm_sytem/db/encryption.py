import os
from cryptography.fernet import Fernet


def _get_cypher() -> Fernet:
    key = os.environ["DB_ENCRYPTION_KEY"].encode()  # Ensure the key is in bytes
    return Fernet(key)


def encrypt_data(data: str) -> str:
    if not data:
        return data

    cypher = _get_cypher()
    encrypted_data = cypher.encrypt(data.encode())
    return encrypted_data.decode()  # Return as string


def decrypt_data(data: str) -> str:
    if not data:
        return data

    cypher = _get_cypher()
    decrypted_bytes = cypher.decrypt(data.encode())
    return decrypted_bytes.decode()  # Return as string




