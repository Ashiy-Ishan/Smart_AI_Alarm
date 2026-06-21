"""ESP32 IoT sensor integration."""
from __future__ import annotations
from datetime import datetime, timezone
from config.settings import get_settings
from db.collections import get_collections, IOT_SENSOR_LOGS


_REQUIRED_FIELDS = {"room_temperature", "humidity", "motion_detected", "light_level"}
_VALID_LIGHT_LEVELS = {"dark", "dim", "normal", "bright"}

#convert value into decimal number, and fallback
def _coerce_float(value, fallback: float) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return float(fallback)
#check light condition and validate
def _coerce_light_level(value, fallback: str = "normal") -> str:
    if isinstance(value, str) and value.strip().lower() in _VALID_LIGHT_LEVELS:
        return value.strip().lower()
    return fallback if fallback in _VALID_LIGHT_LEVELS else "normal"
  
#boolean check
def _coerce_bool(value) -> bool:
    if isinstance(value, bool):
        return value
    if isinstance(value, (int, float)):
        return bool(value)
    if isinstance(value, str):
        return value.strip().lower() in {"1", "true", "yes", "on"}
    return False
  
#time validate
def _coerce_timestamp(value) -> datetime:
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    if isinstance(value, str):
        try:
            parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
            return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)
        except ValueError:
            pass
    return datetime.now(timezone.utc)
  
#store esp32 reading in db
def store_sensor_reading(user_id: str, payload: dict) -> dict:
    """Validate and persist an ESP32 sensor payload. Raises ValueError on bad input."""
    if not user_id:
        raise ValueError("user_id is required")
    missing = sorted(_REQUIRED_FIELDS - set(payload.keys()))
    if missing:
        raise ValueError(f"Missing sensor fields: {', '.join(missing)}")

    settings = get_settings()
    doc = {
        "user_id": user_id,
        "timestamp": _coerce_timestamp(payload.get("timestamp")),
        "room_temperature": _coerce_float(payload.get("room_temperature"), settings.default_room_temperature),
        "humidity": _coerce_float(payload.get("humidity"), settings.default_humidity),
        "motion_detected": _coerce_bool(payload.get("motion_detected")),
        "light_level": _coerce_light_level(payload.get("light_level"), settings.default_light_level),
    }
    result = get_collections()[IOT_SENSOR_LOGS].insert_one(doc)
    doc["_id"] = str(result.inserted_id)
    return doc

#latest readings
def get_latest_reading(user_id: str) -> dict:
    """Return the most recent sensor reading, or configured defaults if none exist."""
    settings = get_settings()
    doc = get_collections()[IOT_SENSOR_LOGS].find_one(
        {"user_id": user_id}, sort=[("timestamp", -1)]
    )
    if doc:
        doc["_id"] = str(doc["_id"])
        return doc
    return {
        "user_id": user_id,
        "timestamp": datetime.now(timezone.utc),
        "room_temperature": settings.default_room_temperature,
        "humidity": settings.default_humidity,
        "motion_detected": bool(settings.default_motion_detected),
        "light_level": settings.default_light_level,
    }

#get recent readings
def get_recent_readings(user_id: str, limit: int = 300) -> list[dict]:
    """Return recent sensor readings in ascending time order."""
    cursor = get_collections()[IOT_SENSOR_LOGS].find(
        {"user_id": user_id}, sort=[("timestamp", -1)]
    ).limit(limit)
    docs = list(cursor)
    for d in docs:
        d["_id"] = str(d["_id"])
    docs.reverse()
    return docs
