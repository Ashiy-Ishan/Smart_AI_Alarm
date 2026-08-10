from pymongo.database import Database
from db.mongo import get_database

USERS = "users"
ALARMS = "alarms"
ALARM_LOGS = "alarm_logs"
MODEL_METADATA = "model_metadata"
IOT_SENSOR_LOGS = "iot_sensor_logs"
CALENDAR_CREDENTIALS = "calendar_credentials"
CALENDAR_EVENTS_CACHE = "calendar_events_cache"
SLEEP_SESSIONS = "sleep_sessions"

def get_collections(db: Database | None = None) -> dict:
    if db is None:
        db = get_database()
    return {
        USERS: db[USERS],
        ALARMS: db[ALARMS],
        ALARM_LOGS: db[ALARM_LOGS],
        MODEL_METADATA: db[MODEL_METADATA],
        IOT_SENSOR_LOGS: db[IOT_SENSOR_LOGS],
        CALENDAR_CREDENTIALS: db[CALENDAR_CREDENTIALS],
        CALENDAR_EVENTS_CACHE: db[CALENDAR_EVENTS_CACHE],
        SLEEP_SESSIONS: db[SLEEP_SESSIONS],
    }

def ensure_indexes(db: Database | None = None) -> None:
    db = db or get_database()
    cols = get_collections(db)
    cols[USERS].create_index("email", unique=True, sparse=True)
    cols[ALARMS].create_index([("user_id", 1), ("set_time", 1)])
    cols[ALARM_LOGS].create_index([("user_id", 1), ("created_at", 1)])
    cols[ALARM_LOGS].create_index("alarm_id")
    cols[MODEL_METADATA].create_index("user_id", unique=True)
    cols[IOT_SENSOR_LOGS].create_index([("user_id", 1), ("timestamp", -1)])
    cols[CALENDAR_CREDENTIALS].create_index("user_id", unique=True)
    cols[CALENDAR_EVENTS_CACHE].create_index([("user_id", 1), ("expires_at", 1)])
    cols[CALENDAR_EVENTS_CACHE].create_index("expires_at", expireAfterSeconds=0)
    cols[SLEEP_SESSIONS].create_index([("user_id", 1), ("sleep_start", 1)])


