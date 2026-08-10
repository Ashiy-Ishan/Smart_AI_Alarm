from __future__ import annotations

import logging
from datetime import datetime, timezone

import lightgbm as lgb
import numpy as np
import pandas as pd
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.model_selection import train_test_split

from db.collections import (
    get_collections,
    ALARM_LOGS,
    MODEL_METADATA,
)

logger = logging.getLogger(__name__)

MIN_TRAINING_SAMPLES = 8

FEATURE_COLUMNS = [
    "weather_severity",
    "traffic_condition",
    "room_temp",
    "snooze_count",
    "unlock_delay",
    "success",
    "is_holiday",
    "alarm_type_encoded",
]

TARGET_COLUMN = "buffer_minutes"


def _encode_alarm_type(value: str | None) -> int:
    mapping = {
        "custom": 0,
        "work": 1,
        "school": 2,
        "meeting": 3,
        "travel": 4,
        "exercise": 5,
    }

    return mapping.get(str(value or "custom").lower(), 0)


def _safe_float(value, default: float = 0.0) -> float:
    try:
        if value is None:
            return default
        return float(value)
    except (TypeError, ValueError):
        return default


def _safe_int(value, default: int = 0) -> int:
    try:
        if value is None:
            return default
        return int(value)
    except (TypeError, ValueError):
        return default


def _log_to_training_row(log: dict) -> dict:
    return {
        "weather_severity": _safe_float(log.get("weather_severity")),
        "traffic_condition": _safe_float(log.get("traffic_condition")),
        "room_temp": _safe_float(log.get("room_temp"), 27.0),
        "snooze_count": _safe_int(log.get("snooze_count")),
        "unlock_delay": _safe_float(log.get("unlock_delay")),
        "success": _safe_int(log.get("success"), 1),
        "is_holiday": _safe_int(log.get("is_holiday")),
        "alarm_type_encoded": _encode_alarm_type(
            log.get("alarm_type")
        ),
        TARGET_COLUMN: _safe_float(log.get(TARGET_COLUMN)),
    }


def _live_features_to_row(features: dict) -> dict:
    """
    Convert the dictionary returned by build_live_feature_vector()
    into the columns expected by the LightGBM model.

    Missing values safely fall back to defaults.
    """

    return {
        "weather_severity": _safe_float(
            features.get("weather_severity")
        ),
        "traffic_condition": _safe_float(
            features.get("traffic_condition")
        ),
        "room_temp": _safe_float(
            features.get(
                "room_temp",
                features.get("room_temperature", 27.0),
            ),
            27.0,
        ),
        "snooze_count": _safe_int(
            features.get("snooze_count")
        ),
        "unlock_delay": _safe_float(
            features.get("unlock_delay")
        ),
        "success": _safe_int(
            features.get("success"),
            1,
        ),
        "is_holiday": _safe_int(
            features.get("is_holiday")
        ),
        "alarm_type_encoded": _encode_alarm_type(
            features.get("alarm_type")
        ),
    }


def train_model(user_id: str) -> dict:
    """
    Train a LightGBM regression model for one user.

    Target:
        buffer_minutes

    Stores:
        - serialized LightGBM model
        - MAE
        - RMSE
        - R²
        - display accuracy score
        - sample count
        - training timestamp
    """

    collections = get_collections()

    logs = list(
        collections[ALARM_LOGS].find(
            {"user_id": user_id}
        ).sort("created_at", 1)
    )

    sample_count = len(logs)

    if sample_count < MIN_TRAINING_SAMPLES:
        result = {
            "trained": False,
            "user_id": user_id,
            "sample_count": sample_count,
            "minimum_samples": MIN_TRAINING_SAMPLES,
            "message": (
                f"At least {MIN_TRAINING_SAMPLES} alarm outcomes "
                "are required before model training."
            ),
            "trained_at": None,
        }

        collections[MODEL_METADATA].update_one(
            {"user_id": user_id},
            {
                "$set": {
                    **result,
                    "updated_at": datetime.now(timezone.utc),
                }
            },
            upsert=True,
        )

        return result

    rows = [_log_to_training_row(log) for log in logs]

    dataframe = pd.DataFrame(rows)

    X = dataframe[FEATURE_COLUMNS]
    y = dataframe[TARGET_COLUMN]

    # Constant targets cannot produce a useful regression model.
    if y.nunique() < 2:
        result = {
            "trained": False,
            "user_id": user_id,
            "sample_count": sample_count,
            "message": (
                "Training data does not contain enough variation "
                "in buffer_minutes."
            ),
            "trained_at": None,
        }

        collections[MODEL_METADATA].update_one(
            {"user_id": user_id},
            {
                "$set": {
                    **result,
                    "updated_at": datetime.now(timezone.utc),
                }
            },
            upsert=True,
        )

        return result

    test_size = max(2, int(round(sample_count * 0.2)))

    # Ensure training set still contains enough rows.
    if test_size >= sample_count:
        test_size = 2

    X_train, X_test, y_train, y_test = train_test_split(
        X,
        y,
        test_size=test_size,
        random_state=42,
    )

    model = lgb.LGBMRegressor(
        objective="regression",
        n_estimators=120,
        learning_rate=0.05,
        num_leaves=15,
        max_depth=5,
        random_state=42,
        verbosity=-1,
    )

    model.fit(X_train, y_train)

    predictions = np.asarray( model.predict(X_test), dtype=float, )
    y_test_array = y_test.to_numpy( dtype=float, )

    mae = float(
        mean_absolute_error(y_test_array, predictions)
    )

    rmse = float(
        np.sqrt(
            mean_squared_error(y_test_array, predictions)
        )
    )

    if len(y_test) >= 2:
        r2 = float(
            r2_score(y_test_array, predictions)
        )
    else:
        r2 = 0.0

    if not np.isfinite(r2):
        r2 = 0.0

    # UI-friendly score.
    #
    # R² itself is NOT technically an "accuracy percentage".
    # We convert it only for presentation on the Accuracy screen.
    accuracy_score = max(
        0.0,
        min(100.0, r2 * 100.0),
    )

    trained_at = datetime.now(timezone.utc)

    booster = model.booster_

    serialized_model = booster.model_to_string()

    metadata = {
        "trained": True,
        "user_id": user_id,
        "sample_count": sample_count,
        "feature_columns": FEATURE_COLUMNS,
        "target": TARGET_COLUMN,
        "mae": round(mae, 4),
        "rmse": round(rmse, 4),
        "r2": round(r2, 4),
        "accuracy_score": round(accuracy_score, 2),
        "trained_at": trained_at,
        "model_type": "LightGBMRegressor",
        "model_string": serialized_model,
        "updated_at": trained_at,
    }

    collections[MODEL_METADATA].update_one(
        {"user_id": user_id},
        {"$set": metadata},
        upsert=True,
    )

    logger.info(
        "Model trained for user %s with %d samples. "
        "MAE=%.4f RMSE=%.4f R2=%.4f",
        user_id,
        sample_count,
        mae,
        rmse,
        r2,
    )

    # Don't return the serialized model to Flutter.
    response = dict(metadata)
    response.pop("model_string", None)
    response.pop("updated_at", None)

    return response


def get_model_metadata(user_id: str) -> dict | None:
    """
    Return model metrics for the Accuracy Score screen.
    """

    metadata = get_collections()[MODEL_METADATA].find_one(
        {"user_id": user_id}
    )

    if not metadata:
        return None

    metadata["_id"] = str(metadata["_id"])

    # Never send the serialized LightGBM model to Flutter.
    metadata.pop("model_string", None)

    return metadata


def predict_buffer(
    user_id: str,
    features: dict,
) -> float:
    """
    Predict buffer minutes for a new alarm.

    Falls back to the user's historical average when no trained
    model exists.
    """

    collections = get_collections()

    metadata = collections[MODEL_METADATA].find_one(
        {
            "user_id": user_id,
            "trained": True,
        }
    )

    if metadata and metadata.get("model_string"):
        try:
            booster = lgb.Booster(
                model_str=metadata["model_string"]
            )

            row = _live_features_to_row(features)

            input_df = pd.DataFrame(
                [row],
                columns=FEATURE_COLUMNS,
            )

            raw_prediction = np.asarray( booster.predict( input_df ), dtype=float, )

            prediction = float(
                raw_prediction[0]
            )

            # Prevent unrealistic negative buffers.
            return max(0.0, prediction)

        except Exception as exc:
            logger.warning(
                "Prediction failed for user %s: %s",
                user_id,
                exc,
            )

    # Fallback: historical average buffer.
    logs = list(
        collections[ALARM_LOGS].find(
            {"user_id": user_id},
            {"buffer_minutes": 1},
        )
        .sort("created_at", -1)
        .limit(20)
    )

    values = [
        _safe_float(log.get("buffer_minutes"))
        for log in logs
        if log.get("buffer_minutes") is not None
    ]

    if values:
        return max(0.0, float(np.mean(values)))

    # New user fallback.
    return 15.0


def retrain_all() -> list[dict]:
    """
    Retrain models for all users who have alarm logs.
    """

    collections = get_collections()

    user_ids = collections[ALARM_LOGS].distinct(
        "user_id"
    )

    results: list[dict] = []

    for user_id in user_ids:
        if not user_id:
            continue

        try:
            result = train_model(str(user_id))
            results.append(result)

        except Exception as exc:
            logger.exception(
                "Failed to retrain model for user %s",
                user_id,
            )

            results.append(
                {
                    "user_id": str(user_id),
                    "trained": False,
                    "error": str(exc),
                }
            )

    return results