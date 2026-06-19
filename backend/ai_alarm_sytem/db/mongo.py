from threading import Lock
from pymongo import MongoClient
from pymongo.database import Database
from config.settings import get_settings

_client: MongoClient | None = None
_lock = Lock()

def get_mongo_client() -> MongoClient:
    global _client
    if _client is None:
        with _lock:
            if _client is None:
                _client = MongoClient(get_settings().mongo_uri)
    return _client

def get_database() -> Database:
    return get_mongo_client()[get_settings().mongo_db_name]