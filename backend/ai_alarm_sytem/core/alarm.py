from __future__ import annotations
from datetime import datetime, timedelta, timezone

from db.collections import get_collections, ALARM_LOGS, ALARMS
from core.features import build_live_feature_vector
from core.model import predict_buffer
from integrations.calendar import adjust_buffer_for_calendar
from integrations.iot import get_latest_reading, get_recent_readings
from integrations.weather import fetch_weather
from integrations.traffic import fetch_traffic
from notifications.email import notify_buffer_change


import logging

logger = logging.getLogger(__name__)


def _user_logs(user_id: str, limit: int = 50) -> list[dict]:
    try:
        cursor = get_collections()[ALARM_LOGS].find(
            {"user_id": user_id}, sort=[("created_at", -1)]
        ).limit(limit)
        docs = list(cursor)
        for d in docs:
            d["_id"] = str(d["_id"])
        docs.reverse()
        return docs
    except Exception as exc:
        logger.warning("Database error fetching logs for user %s: %s", user_id, exc)
        return []


def create_alarm(
    user_id: str,
    set_time: datetime,
    alarm_type: str = "custom",
    is_active: bool = True,
    latitude: float = 0.0,
    longitude: float = 0.0,
    dest_latitude: float | None = None,
    dest_longitude: float | None = None,
    is_holiday: int = 0,
) -> dict:
    """Create an alarm with AI-adjusted trigger time based on all contextual factors."""
    weather = fetch_weather(latitude, longitude)
    traffic = fetch_traffic(latitude, longitude, dest_latitude, dest_longitude)
    sensor = get_latest_reading(user_id)
    sensor_logs = get_recent_readings(user_id)
    logs = _user_logs(user_id)

    features = build_live_feature_vector(
        user_logs=logs,
        set_time=set_time,
        alarm_type=alarm_type,
        weather_severity=weather["severity"],
        traffic_condition=traffic["congestion_index"],
        is_holiday=is_holiday,
        latest_sensor_context=sensor,
        sensor_logs=sensor_logs,
    )
    predicted_buffer = predict_buffer(user_id, features)
    final_buffer, calendar_ctx = adjust_buffer_for_calendar(user_id, set_time, predicted_buffer)

    notify_buffer_change(
        user_id=user_id,
        set_time=set_time,
        predicted_buffer_minutes=predicted_buffer,
        final_buffer_minutes=final_buffer,
        reason="calendar event proximity",
    )

    doc = {
        "user_id": user_id,
        "set_time": set_time,
        "adjusted_time": set_time - timedelta(minutes=final_buffer),
        "alarm_type": alarm_type,
        "is_active": bool(is_active),
        "is_holiday": is_holiday,
        "created_at": datetime.now(timezone.utc),
        "external_context": {
            "weather": weather,
            "traffic": traffic,
        },
        "sensor_context": {
            "timestamp": sensor.get("timestamp"),
            "room_temperature": sensor.get("room_temperature"),
            "humidity": sensor.get("humidity"),
            "motion_detected": sensor.get("motion_detected"),
            "light_level": sensor.get("light_level"),
        },
        "predicted_buffer_minutes": float(predicted_buffer),
        "final_buffer_minutes": float(final_buffer),
        "calendar_context": calendar_ctx,
    }
    try:
        result = get_collections()[ALARMS].insert_one(doc)
        doc["_id"] = str(result.inserted_id)
    except Exception as exc:
        logger.warning("Database error storing alarm for user %s: %s", user_id, exc)
        doc["_id"] = "offline_alarm_id"
    return doc


def log_alarm_outcome(
    user_id: str,
    alarm_id: str,
    trigger_time: datetime,
    weather_severity: float,
    traffic_condition: float,
    room_temp: float,
    snooze_count: int,
    unlock_delay: float,
    success: int,
    alarm_type: str = "custom",
    is_holiday: int = 0,
    buffer_minutes: float = 0.0,
    actual_buffer_minutes: float | None = None,
) -> str:
    """Log the actual outcome of an alarm ring — used as training data for the model."""

    from bson import ObjectId

    collections = get_collections()

    alarm = None

    try:
        if ObjectId.is_valid(str(alarm_id)):
            alarm = collections[ALARMS].find_one(
                {
                    "_id": ObjectId(str(alarm_id)),
                    "user_id": user_id,
                }
            )
    except Exception as exc:
        logger.warning(
            "Failed to find alarm %s: %s",
            alarm_id,
            exc,
        )

    if alarm is None:
        raise ValueError(
            f"Alarm {alarm_id} was not found for this user."
        )

    external_context = alarm.get(
        "external_context",
        {},
    )

    weather = external_context.get(
        "weather",
        {},
    )

    traffic = external_context.get(
        "traffic",
        {},
    )

    sensor_context = alarm.get(
        "sensor_context",
        {},
    )

    # Use actual observed buffer if supplied.
    #
    # Otherwise use final_buffer_minutes as a temporary
    # fallback so the target is not always zero.
    #
    # Later, when you measure real preparation time,
    # send actual_buffer_minutes from Flutter.
    if actual_buffer_minutes is None:
        buffer_minutes = float(
            alarm.get(
                "final_buffer_minutes",
                0.0,
            )
        )
    else:
        buffer_minutes = float(
            actual_buffer_minutes
        )

    doc = {
        "user_id": user_id,
        "alarm_id": alarm_id,
        "trigger_time": trigger_time,
        "weather_severity": float(weather.get("severity", 0.0)),
        "traffic_condition": float(traffic.get("congestion_index", 0.0)),
        "room_temp": float(sensor_context.get("room_temperature", 27.0) or 27.0),
        "snooze_count": int(snooze_count),
        "unlock_delay": float(unlock_delay),
        "success": int(success),
        "alarm_type": alarm.get("alarm_type", "custom"),
        "is_holiday": int(alarm.get("is_holiday", 0)),
        "buffer_minutes": float(buffer_minutes),
        "created_at": datetime.now(timezone.utc),
        "humidity": float(sensor_context.get("humidity", 0.0) or 0.0),
        "motion_detected": bool(sensor_context.get("motion_detected", False)),
        "light_level": float(sensor_context.get("light_level", "normal")),
        "predicted_buffer_minutes": float(alarm.get("predicted_buffer_minutes", 0.0)),
        "final_buffer_minutes": float(alarm.get("final_buffer_minutes", 0.0)),
    }
    try:
        result = (collections[ALARM_LOGS].insert_one(doc))
        logger.info(
            "Alarm outcome stored: "
            "user=%s alarm=%s log=%s",
            user_id,
            alarm_id,
            result.inserted_id,
        )
        return str(result.inserted_id)
    except Exception as exc:
        logger.warning("Database error logging alarm outcome: %s", exc)
        raise RuntimeError("Failed to log alarm outcome") from exc
        

