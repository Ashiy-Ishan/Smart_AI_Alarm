"""LightGBM model — daily batch training with early stopping.

Models are stored in Firebase Storage at models/{user_id}.txt and cached
locally in /tmp/ for the lifetime of the Cloud Function instance.
"""
from __future__ import annotations
import logging
import os
from datetime import datetime, timezone
from pathlib import Path

import lightgbm as lgb
import numpy as np
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.model_selection import train_test_split

from config.settings import get_settings
from db.collections import get_collections, ALARM_LOGS, IOT_SENSOR_LOGS, MODEL_METADATA
from core.features import build_feature_dataframe, get_feature_columns
from notifications.email import notify_training_completed

logger = logging.getLogger(__name__)

_booster_cache: dict[str, lgb.Booster] = {}


# Firebase Storage helpers

def _tmp_path(user_id: str) -> str:
    return f"/tmp/{user_id}.txt"


def _upload_model(user_id: str) -> None:
    from firebase_admin import storage
    storage.bucket().blob(f"models/{user_id}.txt").upload_from_filename(_tmp_path(user_id))


def _download_model(user_id: str) -> bool:
    from firebase_admin import storage
    blob = storage.bucket().blob(f"models/{user_id}.txt")
    if not blob.exists():
        return False
    blob.download_to_filename(_tmp_path(user_id))
    return True


def invalidate_cache(user_id: str) -> None:
    _booster_cache.pop(user_id, None)
    tmp = _tmp_path(user_id)
    if os.path.exists(tmp):
        os.remove(tmp)


# Prediction

def predict_buffer(user_id: str, feature_frame) -> float:
    """Predict wake-up buffer minutes. Returns 0.0 if no trained model exists."""
    meta = get_collections()[MODEL_METADATA].find_one({"user_id": user_id})
    if not meta:
        return 0.0

    if user_id not in _booster_cache:
        if not os.path.exists(_tmp_path(user_id)):
            if not _download_model(user_id):
                return 0.0
        _booster_cache[user_id] = lgb.Booster(model_file=_tmp_path(user_id))

    settings = get_settings()
    raw = float(_booster_cache[user_id].predict(feature_frame)[0])
    return max(0.0, min(raw, float(settings.max_buffer_minutes)))


# Training

def train_model(user_id: str) -> dict:
    """Train (or retrain) the alarm buffer model for a single user."""
    settings = get_settings()

    cols = get_collections()
    raw_logs = list(cols[ALARM_LOGS].find({"user_id": user_id}).sort("created_at", 1))
    sensor_logs = list(cols[IOT_SENSOR_LOGS].find({"user_id": user_id}).sort("timestamp", 1))

    if len(raw_logs) < settings.min_training_points:
        result = {
            "trained": False,
            "reason": f"need {settings.min_training_points} data points, have {len(raw_logs)}",
        }
        notify_training_completed(user_id, result)
        return result

    df = build_feature_dataframe(raw_logs, sensor_logs=sensor_logs)
    if df.empty:
        result = {"trained": False, "reason": "empty feature frame after preprocessing"}
        notify_training_completed(user_id, result)
        return result

    X = df[get_feature_columns()]
    y = df["buffer_minutes"].clip(lower=0.0)

    if len(X) >= 50:
        X_tr, X_val, y_tr, y_val = train_test_split(X, y, test_size=0.15, random_state=42)
        fit_kwargs: dict = {
            "eval_set": [(X_val, y_val)],
            "callbacks": [lgb.early_stopping(20, verbose=False), lgb.log_evaluation(period=-1)],
        }
    else:
        X_tr, y_tr = X, y
        fit_kwargs = {"callbacks": [lgb.log_evaluation(period=-1)]}

    model = lgb.LGBMRegressor(
        n_estimators=300,
        learning_rate=0.05,
        num_leaves=31,
        min_child_samples=5,
        random_state=42,
    )
    model.fit(X_tr, y_tr, **fit_kwargs)

    preds = model.predict(X)
    metrics = {
        "mae": float(mean_absolute_error(y, preds)),
        "rmse": float(np.sqrt(mean_squared_error(y, preds))),
        "r2": float(r2_score(y, preds)) if len(y) > 1 else 0.0,
        "data_points": len(raw_logs),
    }

    model.booster_.save_model(_tmp_path(user_id))
    _upload_model(user_id)

    get_collections()[MODEL_METADATA].update_one(
        {"user_id": user_id},
        {"$set": {
            "user_id": user_id,
            "last_trained_at": datetime.now(timezone.utc),
            "model_version": datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S"),
            "metrics": metrics,
        }},
        upsert=True,
    )

    invalidate_cache(user_id)
    result = {"trained": True, "metrics": metrics}
    notify_training_completed(user_id, result)
    logger.info("Model trained for user %s — MAE %.2f min, %d points", user_id, metrics["mae"], len(raw_logs))
    return result


def retrain_all() -> list[dict]:
    """Retrain models for every user that has alarm log data. Called by the daily scheduler."""
    user_ids: set[str] = set(get_collections()[ALARM_LOGS].distinct("user_id"))

    results = []
    for uid in user_ids:
        try:
            results.append({"user_id": uid, **train_model(uid)})
        except Exception as exc:
            logger.error("Retrain failed for user %s: %s", uid, exc)
            results.append({"user_id": uid, "trained": False, "reason": str(exc)})
    return results
