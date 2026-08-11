from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone

import numpy as np
from bson import ObjectId

from db.collections import (
    get_collections,
    ALARMS,
    ALARM_LOGS,
    MODEL_METADATA,
    SLEEP_SESSIONS,
)

logger = logging.getLogger(__name__)


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


# ============================================================
# SLEEP
# ============================================================


def create_sleep_session(
    user_id: str,
    sleep_start: datetime,
    sleep_end: datetime,
    awakenings: int = 0,
    motion_events: int = 0,
    source: str = "mobile",
) -> dict:
    """
    Store one sleep session.

    The session can later be created from:
    - Flutter
    - ESP32 sleep-detection logic
    - wearable integration
    """

    if not user_id:
        raise ValueError("user_id is required")

    if sleep_end <= sleep_start:
        raise ValueError(
            "sleep_end must be after sleep_start"
        )

    duration_minutes = (
        sleep_end - sleep_start
    ).total_seconds() / 60.0

    duration_hours = (
        duration_minutes / 60.0
    )

    # ----------------------------------------
    # Basic quality score
    # ----------------------------------------

    score = 100.0

    # Ideal range for this first implementation:
    # roughly 7-9 hours.
    if duration_hours < 7:
        score -= (
            7 - duration_hours
        ) * 15.0

    elif duration_hours > 9:
        score -= (
            duration_hours - 9
        ) * 10.0

    # Penalize repeated awakenings.
    score -= max(
        0,
        int(awakenings),
    ) * 5.0

    sleep_score = max(
        0.0,
        min(
            100.0,
            score,
        ),
    )

    doc = {
        "user_id": user_id,
        "sleep_start": sleep_start,
        "sleep_end": sleep_end,
        "duration_minutes": round(
            duration_minutes,
            2,
        ),
        "duration_hours": round(
            duration_hours,
            2,
        ),
        "awakenings": int(
            awakenings
        ),
        "motion_events": int(
            motion_events
        ),
        "sleep_score": round(
            sleep_score,
            2,
        ),
        "source": source,
        "created_at": datetime.now(
            timezone.utc
        ),
    }

    logger.info(
        (
            "Saving sleep session | "
            "user=%s | "
            "start=%s | "
            "end=%s | "
            "duration=%.2f hours"
        ),
        user_id,
        sleep_start,
        sleep_end,
        duration_hours,
    )

    try:
        collections = get_collections()

        logger.info(
            "Mongo collections loaded for sleep session"
        )

        collection = collections[
            SLEEP_SESSIONS
        ]

        logger.info(
            "Writing sleep session to MongoDB..."
        )

        result = collection.insert_one(
            doc
        )

        logger.info(
            (
                "Sleep session successfully saved | "
                "user=%s | id=%s"
            ),
            user_id,
            result.inserted_id,
        )

    except Exception as exc:
        logger.exception(
            (
                "MongoDB error while saving "
                "sleep session for user %s"
            ),
            user_id,
        )

        raise RuntimeError(
            (
                "Sleep session database error: "
                f"{exc}"
            )
        ) from exc

    doc["_id"] = str(
        result.inserted_id
    )

    return doc


def get_sleep_insights(
    user_id: str,
    days: int = 7,
) -> dict:
    collections = get_collections()

    since = (
        datetime.now(timezone.utc)
        - timedelta(days=days)
    )

    sessions = list(
        collections[SLEEP_SESSIONS]
        .find(
            {
                "user_id": user_id,
                "sleep_start": {
                    "$gte": since,
                },
            }
        )
        .sort(
            "sleep_start",
            1,
        )
    )

    if not sessions:
        return {
            "available": False,
            "session_count": 0,
            "average_sleep_hours": None,
            "total_sleep_hours": 0.0,
            "average_sleep_score": None,
            "average_awakenings": None,
            "trend": "not_enough_data",
            "message": (
                "No sleep sessions recorded yet."
            ),
            "daily": [],
        }

    durations = [
        _safe_float(
            session.get(
                "duration_hours"
            )
        )
        for session in sessions
    ]

    scores = [
        _safe_float(
            session.get(
                "sleep_score"
            )
        )
        for session in sessions
    ]

    awakening_values = [
        int(
            session.get(
                "awakenings",
                0,
            )
        )
        for session in sessions
    ]

    average_sleep = float(
        np.mean(durations)
    )

    total_sleep = float(
        np.sum(durations)
    )

    average_score = float(
        np.mean(scores)
    )

    average_awakenings = float(
        np.mean(
            awakening_values
        )
    )

    # ----------------------------------------
    # Trend
    # ----------------------------------------

    trend = "stable"

    if len(durations) >= 4:
        midpoint = (
            len(durations) // 2
        )

        previous = float(
            np.mean(
                durations[:midpoint]
            )
        )

        recent = float(
            np.mean(
                durations[midpoint:]
            )
        )

        if recent >= previous + 0.5:
            trend = "up"

        elif recent <= previous - 0.5:
            trend = "down"

    daily = []

    for session in sessions:
        sleep_start = session.get(
            "sleep_start"
        )

        daily.append(
            {
                "date": (
                    sleep_start.strftime(
                        "%Y-%m-%d"
                    )
                    if isinstance(
                        sleep_start,
                        datetime,
                    )
                    else None
                ),
                "sleep_start": (
                    _serialize_datetime(
                        sleep_start
                    )
                ),
                "sleep_end": (
                    _serialize_datetime(
                        session.get(
                            "sleep_end"
                        )
                    )
                ),
                "hours": _safe_float(
                    session.get(
                        "duration_hours"
                    )
                ),
                "score": _safe_float(
                    session.get(
                        "sleep_score"
                    )
                ),
                "awakenings": int(
                    session.get(
                        "awakenings",
                        0,
                    )
                ),
            }
        )

    return {
        "available": True,
        "session_count": len(
            sessions
        ),
        "average_sleep_hours": round(
            average_sleep,
            2,
        ),
        "total_sleep_hours": round(
            total_sleep,
            2,
        ),
        "average_sleep_score": round(
            average_score,
            1,
        ),
        "average_awakenings": round(
            average_awakenings,
            1,
        ),
        "trend": trend,
        "message": _sleep_message(
            average_sleep
        ),
        "daily": daily,
    }


def _sleep_message(
    average_hours: float,
) -> str:
    if average_hours < 6:
        return (
            "Your recent sleep duration "
            "has been quite short."
        )

    if average_hours < 7:
        return (
            "Your recent average is below "
            "7 hours per night."
        )

    if average_hours <= 9:
        return (
            "Your recent sleep duration "
            "is within the target range."
        )

    return (
        "Your recent sleep duration "
        "is above 9 hours per night."
    )


# ============================================================
# HABIT LEARNING
# ============================================================


def _find_alarm(
    alarm_id,
) -> dict | None:
    if not alarm_id:
        return None

    collection = (
        get_collections()[ALARMS]
    )

    alarm_id_str = str(
        alarm_id
    )

    # Normal Mongo ObjectId.
    if ObjectId.is_valid(
        alarm_id_str
    ):
        alarm = collection.find_one(
            {
                "_id": ObjectId(
                    alarm_id_str
                )
            }
        )

        if alarm:
            return alarm

    # Optional fallback in case an alarm id
    # was stored as a string.
    return collection.find_one(
        {
            "_id": alarm_id_str,
        }
    )


def get_habit_insights(
    user_id: str,
    days: int = 7,
) -> dict:
    """
    Compare:
      AI predicted buffer
        alarms.predicted_buffer_minutes

    with:
      actual observed/user outcome buffer
        alarm_logs.buffer_minutes
    """

    collections = get_collections()

    since = (
        datetime.now(timezone.utc)
        - timedelta(days=days)
    )

    logs = list(
        collections[ALARM_LOGS]
        .find(
            {
                "user_id": user_id,
                "created_at": {
                    "$gte": since,
                },
            }
        )
        .sort(
            "created_at",
            1,
        )
    )

    history = []

    ai_values = []
    actual_values = []
    errors = []

    snooze_values = []
    success_values = []

    for log in logs:
        alarm = _find_alarm(
            log.get(
                "alarm_id"
            )
        )

        if not alarm:
            continue

        # Your create_alarm() already stores this.
        ai_prediction = _safe_float(
            alarm.get(
                "predicted_buffer_minutes"
            )
        )

        # Your log_alarm_outcome() already stores this.
        actual_buffer = _safe_float(
            log.get(
                "buffer_minutes"
            )
        )

        difference = abs(
            ai_prediction
            - actual_buffer
        )

        ai_values.append(
            ai_prediction
        )

        actual_values.append(
            actual_buffer
        )

        errors.append(
            difference
        )

        snooze_values.append(
            int(
                log.get(
                    "snooze_count",
                    0,
                )
            )
        )

        success_values.append(
            int(
                log.get(
                    "success",
                    0,
                )
            )
        )

        created_at = log.get(
            "created_at"
        )

        history.append(
            {
                "date": (
                    created_at.strftime(
                        "%Y-%m-%d"
                    )
                    if isinstance(
                        created_at,
                        datetime,
                    )
                    else None
                ),
                "alarm_id": str(
                    log.get(
                        "alarm_id"
                    )
                ),
                "actual_buffer_minutes": round(
                    actual_buffer,
                    2,
                ),
                "ai_buffer_minutes": round(
                    ai_prediction,
                    2,
                ),
                "difference_minutes": round(
                    difference,
                    2,
                ),
                "snooze_count": int(
                    log.get(
                        "snooze_count",
                        0,
                    )
                ),
                "success": int(
                    log.get(
                        "success",
                        0,
                    )
                ),
            }
        )

    if not history:
        return {
            "available": False,
            "sample_count": 0,
            "average_actual_buffer": None,
            "average_ai_buffer": None,
            "average_error_minutes": None,
            "average_snooze": None,
            "success_rate": None,
            "trend": "not_enough_data",
            "message": (
                "Complete more alarms so the "
                "AI can learn your routine."
            ),
            "daily": [],
        }

    average_actual = float(
        np.mean(
            actual_values
        )
    )

    average_ai = float(
        np.mean(
            ai_values
        )
    )

    average_error = float(
        np.mean(
            errors
        )
    )

    average_snooze = float(
        np.mean(
            snooze_values
        )
    )

    success_rate = float(
        np.mean(
            success_values
        ) * 100.0
    )

    # ----------------------------------------
    # Is AI prediction error improving?
    # ----------------------------------------

    trend = "stable"

    if len(errors) >= 4:
        midpoint = (
            len(errors) // 2
        )

        older_error = float(
            np.mean(
                errors[:midpoint]
            )
        )

        recent_error = float(
            np.mean(
                errors[midpoint:]
            )
        )

        if recent_error <= (
            older_error - 1.0
        ):
            trend = "improving"

        elif recent_error >= (
            older_error + 1.0
        ):
            trend = "declining"

    return {
        "available": True,
        "sample_count": len(
            history
        ),
        "average_actual_buffer": round(
            average_actual,
            2,
        ),
        "average_ai_buffer": round(
            average_ai,
            2,
        ),
        "average_error_minutes": round(
            average_error,
            2,
        ),
        "average_snooze": round(
            average_snooze,
            2,
        ),
        "success_rate": round(
            success_rate,
            1,
        ),
        "trend": trend,
        "message": _habit_message(
            average_error
        ),
        "daily": history,
    }


def _habit_message(
    average_error: float,
) -> str:
    if average_error <= 3:
        return (
            "The AI is closely matching "
            "your real preparation-time habit."
        )

    if average_error <= 7:
        return (
            "The AI is learning your routine "
            "and prediction error is moderate."
        )

    return (
        "Your routine is still variable. "
        "More completed alarms should improve learning."
    )


# ============================================================
# MODEL ACCURACY
# ============================================================


def get_accuracy_insight(
    user_id: str,
) -> dict:
    metadata = (
        get_collections()[
            MODEL_METADATA
        ].find_one(
            {
                "user_id": user_id,
            }
        )
    )

    if not metadata:
        return {
            "available": False,
            "trained": False,
            "accuracy_score": None,
            "r2": None,
            "mae": None,
            "rmse": None,
            "sample_count": 0,
            "trained_at": None,
            "message": (
                "Model has not been trained yet."
            ),
        }

    return {
        "available": bool(
            metadata.get(
                "trained",
                False,
            )
        ),
        "trained": bool(
            metadata.get(
                "trained",
                False,
            )
        ),
        "accuracy_score": (
            metadata.get(
                "accuracy_score"
            )
        ),
        "r2": metadata.get(
            "r2"
        ),
        "mae": metadata.get(
            "mae"
        ),
        "rmse": metadata.get(
            "rmse"
        ),
        "sample_count": int(
            metadata.get(
                "sample_count",
                0,
            )
        ),
        "trained_at": (
            _serialize_datetime(
                metadata.get(
                    "trained_at"
                )
            )
        ),
        "message": metadata.get(
            "message"
        ),
    }


# ============================================================
# COMPLETE INSIGHT SCREEN RESPONSE
# ============================================================


def get_user_insights(
    user_id: str,
    days: int = 7,
) -> dict:
    days = max(
        1,
        min(
            int(days),
            30,
        ),
    )

    return {
        "user_id": user_id,
        "period_days": days,
        "generated_at": datetime.now(
            timezone.utc
        ),
        "sleep": get_sleep_insights(
            user_id,
            days,
        ),
        "habit": get_habit_insights(
            user_id,
            days,
        ),
        "accuracy": get_accuracy_insight(
            user_id
        ),
    }