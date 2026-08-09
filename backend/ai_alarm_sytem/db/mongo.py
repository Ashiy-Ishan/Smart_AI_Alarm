import logging
from threading import Lock
from pymongo import MongoClient
from pymongo.database import Database
from config.settings import get_settings

logger = logging.getLogger(__name__)

_client: MongoClient | None = None
_lock = Lock()

def get_mongo_client() -> MongoClient:
    global _client
    if _client is None:
        with _lock:
            if _client is None:
                uri = get_settings().mongo_uri
                if "<db_password>" in uri:
                    logger.warning(
                        "MONGO_URI contains placeholder '<db_password>'. "
                        "Please update .env with your actual database password. "
                        "Falling back to local MongoDB connection."
                    )
                    uri = "mongodb://localhost:27017"
                _client = MongoClient(uri, serverSelectionTimeoutMS=3000)
    return _client

def get_database() -> Database:
    return get_mongo_client()[get_settings().mongo_db_name]