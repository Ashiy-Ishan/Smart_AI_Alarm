from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo

from db.collections import (
    get_collections,
    ALARM_LOGS,
    IOT_SENSOR_LOGS,
    SLEEP_SESSIONS,
    MODEL_METADATA,
)

logger = logging.getLogger(__name__)

LOCAL_TIMEZONE = ZoneInfo("Asia/Colombo")


def _safe_float(
    value,
    default: float = 0.0,
) -> float:
    try:
        if value is None:
            return default

        return float(value)

    except (TypeError, ValueError):
        return default


def _serialize_datetime(value):
    if isinstance(value, datetime):
        return value.isoformat()

    return value


def _today_bounds_utc() -> tuple[datetime, datetime]:
    """
    Get the beginning and end of today in Sri Lanka time,
    converted to UTC for MongoDB queries.
    """

    now_local = datetime.now(
        LOCAL_TIMEZONE
    )

    start_local = now_local.replace(
        hour=0,
        minute=0,
        second=0,
        microsecond=0,
    )

    end_local = (
        start_local
        + timedelta(days=1)
    )

    return (
        start_local.astimezone(timezone.utc),
        end_local.astimezone(timezone.utc),
    )


# ============================================================
# ACTIVITY / IOT SUMMARY
# ============================================================


def _get_activity_summary(
    user_id: str,
) -> dict:
    collections = get_collections()

    start, end = _today_bounds_utc()

    try:
        readings = list(
            collections[IOT_SENSOR_LOGS]
            .find(
                {
                    "user_id": user_id,
                    "timestamp": {
                        "$gte": start,
                        "$lt": end,
                    },
                }
            )
            .sort(
                "timestamp",
                1,
            )
        )

    except Exception as exc:
        logger.exception(
            "Failed to load IoT summary for user %s",
            user_id,
        )

        raise RuntimeError(
            f"Failed to load activity data: {exc}"
        ) from exc

    if not readings:
        return {
            "available": False,
            "room_temperature": None,
            "humidity": None,
            "motion_detected": False,
            "light_level": None,
            "motion_events": 0,
            "movement_minutes": 0.0,
            "steps": None,
            "calories": None,
            "latest_reading_at": None,
            "message": (
                "No sensor activity recorded today."
            ),
        }

    latest = readings[-1]

    motion_events = sum(
        1
        for reading in readings
        if bool(
            reading.get(
                "motion_detected",
                False,
            )
        )
    )

    # Estimate movement duration using
    # consecutive ESP32 readings.
    movement_minutes = 0.0

    for index in range(
        len(readings) - 1
    ):
        current = readings[index]
        following = readings[index + 1]

        if not bool(
            current.get(
                "motion_detected",
                False,
            )
        ):
            continue

        current_time = current.get(
            "timestamp"
        )

        next_time = following.get(
            "timestamp"
        )

        if not (
            isinstance(current_time, datetime)
            and isinstance(next_time, datetime)
        ):
            continue

        difference = (
            next_time - current_time
        ).total_seconds() / 60.0

        # Prevent a long sensor gap being
        # counted as continuous movement.
        movement_minutes += min(
            max(
                difference,
                0.0,
            ),
            5.0,
        )

    return {
        "available": True,

        "room_temperature": _safe_float(
            latest.get(
                "room_temperature"
            )
        ),

        "humidity": _safe_float(
            latest.get(
                "humidity"
            )
        ),

        "motion_detected": bool(
            latest.get(
                "motion_detected",
                False,
            )
        ),

        "light_level": latest.get(
            "light_level"
        ),

        "motion_events": int(
            motion_events
        ),

        "movement_minutes": round(
            movement_minutes,
            1,
        ),

        # Not currently collected by your ESP32.
        "steps": None,

        # Not currently collected by your ESP32.
        "calories": None,

        "latest_reading_at": (
            _serialize_datetime(
                latest.get(
                    "timestamp"
                )
            )
        ),

        "message": (
            "Sensor activity available."
        ),
    }


# ============================================================
# SLEEP SUMMARY
# ============================================================


def _get_sleep_summary(
    user_id: str,
) -> dict:
    collections = get_collections()

    try:
        session = (
            collections[SLEEP_SESSIONS]
            .find_one(
                {
                    "user_id": user_id,
                },
                sort=[
                    (
                        "sleep_end",
                        -1,
                    )
                ],
            )
        )

    except Exception as exc:
        logger.exception(
            "Failed to load latest sleep for %s",
            user_id,
        )

        raise RuntimeError(
            f"Failed to load sleep summary: {exc}"
        ) from exc

    if not session:
        return {
            "available": False,
            "duration_hours": None,
            "sleep_score": None,
            "awakenings": None,
            "sleep_start": None,
            "sleep_end": None,
            "message": (
                "No sleep session recorded yet."
            ),
        }

    duration_hours = _safe_float(
        session.get(
            "duration_hours"
        )
    )

    sleep_score = _safe_float(
        session.get(
            "sleep_score"
        )
    )

    awakenings = int(
        session.get(
            "awakenings",
            0,
        )
    )

    if sleep_score >= 80:
        message = (
            "Your latest recorded sleep "
            "quality was good."
        )

    elif sleep_score >= 60:
        message = (
            "Your latest sleep quality "
            "was moderate."
        )

    else:
        message = (
            "Your latest sleep session "
            "could be improved."
        )

    return {
        "available": True,

        "duration_hours": round(
            duration_hours,
            2,
        ),

        "sleep_score": round(
            sleep_score,
            1,
        ),

        "awakenings": awakenings,

        "sleep_start": _serialize_datetime(
            session.get(
                "sleep_start"
            )
        ),

        "sleep_end": _serialize_datetime(
            session.get(
                "sleep_end"
            )
        ),

        "message": message,
    }


# ============================================================
# ALARM SUMMARY
# ============================================================


def _get_alarm_summary(
    user_id: str,
) -> dict:
    collections = get_collections()

    start, end = _today_bounds_utc()

    try:
        logs = list(
            collections[ALARM_LOGS]
            .find(
                {
                    "user_id": user_id,
                    "created_at": {
                        "$gte": start,
                        "$lt": end,
                    },
                }
            )
        )

    except Exception as exc:
        logger.exception(
            "Failed to load alarm summary for %s",
            user_id,
        )

        raise RuntimeError(
            f"Failed to load alarm summary: {exc}"
        ) from exc

    if not logs:
        return {
            "completed": 0,
            "snoozes": 0,
            "success_rate": None,
            "average_unlock_delay": None,
        }

    total_snoozes = sum(
        int(
            log.get(
                "snooze_count",
                0,
            )
        )
        for log in logs
    )

    successes = [
        int(
            log.get(
                "success",
                0,
            )
        )
        for log in logs
    ]

    unlock_delays = [
        _safe_float(
            log.get(
                "unlock_delay"
            )
        )
        for log in logs
    ]

    success_rate = (
        sum(successes)
        / len(successes)
        * 100.0
    )

    average_unlock_delay = (
        sum(unlock_delays)
        / len(unlock_delays)
    )

    return {
        "completed": len(logs),

        "snoozes": total_snoozes,

        "success_rate": round(
            success_rate,
            1,
        ),

        "average_unlock_delay": round(
            average_unlock_delay,
            2,
        ),
    }


# ============================================================
# AI MODEL SUMMARY
# ============================================================


def _get_ai_summary(
    user_id: str,
) -> dict:
    collections = get_collections()

    try:
        metadata = (
            collections[MODEL_METADATA]
            .find_one(
                {
                    "user_id": user_id,
                }
            )
        )

    except Exception as exc:
        logger.exception(
            "Failed to load model metadata for %s",
            user_id,
        )

        raise RuntimeError(
            f"Failed to load AI summary: {exc}"
        ) from exc

    if not metadata:
        return {
            "trained": False,
            "accuracy_score": None,
            "sample_count": 0,
        }

    return {
        "trained": bool(
            metadata.get(
                "trained",
                False,
            )
        ),

        "accuracy_score": metadata.get(
            "accuracy_score"
        ),

        "sample_count": int(
            metadata.get(
                "sample_count",
                0,
            )
        ),
    }


# ============================================================
# COMPLETE TODAY SUMMARY
# ============================================================


def get_today_summary(
    user_id: str,
) -> dict:
    if not user_id:
        raise ValueError(
            "user_id is required"
        )

    logger.info(
        "Generating today's summary for user %s",
        user_id,
    )

    activity = _get_activity_summary(
        user_id
    )

    sleep = _get_sleep_summary(
        user_id
    )

    alarms = _get_alarm_summary(
        user_id
    )

    ai = _get_ai_summary(
        user_id
    )

    if sleep.get("available"):
        health_insight = sleep.get(
            "message"
        )
    elif activity.get("available"):
        health_insight = (
            "Activity data is available, "
            "but no sleep session has been recorded yet."
        )
    else:
        health_insight = (
            "Record sleep and sensor activity "
            "to generate health insights."
        )

    now_local = datetime.now(
        LOCAL_TIMEZONE
    )

    return {
        "user_id": user_id,

        "date": (
            now_local.date().isoformat()
        ),

        "generated_at": (
            datetime.now(
                timezone.utc
            )
        ),

        "activity": activity,

        "sleep": sleep,

        "alarms": alarms,

        "ai": ai,

        "health_insight": health_insight,
    }