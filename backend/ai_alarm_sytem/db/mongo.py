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
                settings = get_settings()
                _client = MongoClient(settings.mongo_uri, tls=True, 
                                      serverSelectionTimeoutMS=5000)
    return _client

def get_database() -> Database:
    settings = get_settings()
    return get_mongo_client()[settings.mongo_db_name]