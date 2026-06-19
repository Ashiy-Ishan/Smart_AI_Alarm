from __future__ import annotations
from datetime import datetime, timezone

import numpy as np
import pandas as pd

from config.settings import get_settings

# Base features fed to the model
FEATURE_COLS = [
    "alarm_hour",
    "is_weekday",
    "is_holiday",
    "alarm_type_enc",
    "weather_severity",
    "traffic_condition",
    "hours_since_last_alarm",
    "avg_snooze",
    "avg_unlock_delay",
    "avg_success_rate",
    "room_temperature",
    "humidity",
    "motion_detected",
    "light_level",
]

ROLLING_WINDOWS = (3, 7, 14)

_ROLLING_METRICS = [
    ("snooze_mean",       "snooze_count",     0.0),
    ("unlock_delay_mean", "unlock_delay",     0.0),
    ("success_rate",      "success",          0.0),
    ("temp_mean",         "room_temperature", None),
    ("humidity_mean",     "humidity",         None),
    ("motion_frequency",  "motion_detected",  None),
    ("light_level_mean",  "light_level",      None),
]

def get_feature_columns() -> list[str]:
    return FEATURE_COLS + [
        f"{name}_{w}"
        for name, _, _ in _ROLLING_METRICS
        for w in ROLLING_WINDOWS
    ]

def encode_alarm_type(value: str | None) -> int:
    mapping = {"work": 0, "study": 1, "gym": 2, "custom": 3}
    return mapping.get(str(value).lower() if value else "custom", mapping["custom"])

_LIGHT_LEVEL_ENCODING = {"dark": 0, "dim": 1, "normal": 2, "bright": 3}

def encode_light_level(value) -> int:
    if isinstance(value, str):
        return _LIGHT_LEVEL_ENCODING.get(value.strip().lower(), 2)
    if isinstance(value, (int, float)) and not pd.isna(value):
        return int(value)
    return 2

def _sensor_defaults() -> dict:
    s = get_settings()
    return {
        "room_temperature": float(s.default_room_temperature),
        "humidity": float(s.default_humidity),
        "motion_detected": float(s.default_motion_detected),
        "light_level": encode_light_level(s.default_light_level),
    }

def _safe_numeric(df: pd.DataFrame, col: str, default: float = 0.0) -> pd.Series:
    if col not in df.columns:
        return pd.Series([default] * len(df), index=df.index, dtype=float)
    return pd.to_numeric(df[col], errors="coerce").fillna(default)

def _safe_datetime(df: pd.DataFrame, col: str) -> pd.Series:
    if col not in df.columns:
        return pd.Series([pd.NaT] * len(df), index=df.index)
    return pd.to_datetime(df[col], errors="coerce", utc=True)

def _add_rolling(df: pd.DataFrame, col: str, prefix: str, fillna: float) -> None:
    shifted = df[col].shift(1)
    for w in ROLLING_WINDOWS:
        df[f"{prefix}_{w}"] = shifted.rolling(w, min_periods=1).mean().fillna(fillna)

def _prepare_sensor_df(sensor_logs: list[dict]) -> pd.DataFrame:
    if not sensor_logs:
        return pd.DataFrame(columns=["sensor_ts", "room_temperature", "humidity", "motion_detected", "light_level"])
    defaults = _sensor_defaults()
    sdf = pd.DataFrame(sensor_logs).copy()
    sdf["sensor_ts"] = _safe_datetime(sdf, "timestamp")
    sdf = sdf.sort_values("sensor_ts").reset_index(drop=True)
    sdf["room_temperature"] = _safe_numeric(sdf, "room_temperature", defaults["room_temperature"])
    sdf["humidity"] = _safe_numeric(sdf, "humidity", defaults["humidity"])
    sdf["motion_detected"] = _safe_numeric(sdf, "motion_detected", defaults["motion_detected"]).clip(0, 1).astype(int)
    if "light_level" in sdf.columns:
        sdf["light_level"] = sdf["light_level"].map(encode_light_level).fillna(defaults["light_level"]).astype(int)
    else:
        sdf["light_level"] = defaults["light_level"]
    return sdf[["sensor_ts", "room_temperature", "humidity", "motion_detected", "light_level"]]

def build_feature_dataframe(raw_logs: list[dict], sensor_logs: list[dict] | None = None) -> pd.DataFrame:
    if not raw_logs:
        return pd.DataFrame()

    defaults = _sensor_defaults()
    df = pd.DataFrame(raw_logs).copy()
    df["created_at"] = _safe_datetime(df, "created_at")
    df["trigger_time"] = _safe_datetime(df, "trigger_time")
    df = df.sort_values("created_at").reset_index(drop=True)

    sensor_df = _prepare_sensor_df(sensor_logs or [])
    if not sensor_df.empty:
        df = pd.merge_asof(
            df.sort_values("created_at"),
            sensor_df,
            left_on="created_at",
            right_on="sensor_ts",
            direction="backward",
        ).sort_values("created_at")

    for col, key in [("room_temperature", "room_temperature"), ("humidity", "humidity")]:
        df[col] = _safe_numeric(df, col, defaults[key])
    if "light_level" in df.columns:
        df["light_level"] = df["light_level"].map(encode_light_level).fillna(defaults["light_level"]).astype(int)
    else:
        df["light_level"] = defaults["light_level"]
    df["motion_detected"] = _safe_numeric(df, "motion_detected", defaults["motion_detected"]).clip(0, 1).astype(int)

    df["alarm_hour"] = df["trigger_time"].dt.hour.fillna(0).astype(int)
    df["is_weekday"] = (df["trigger_time"].dt.weekday < 5).fillna(False).astype(int)
    df["is_holiday"] = _safe_numeric(df, "is_holiday").astype(int)
    df["alarm_type_enc"] = df.get("alarm_type", pd.Series(["custom"] * len(df))).map(encode_alarm_type)
    df["weather_severity"] = _safe_numeric(df, "weather_severity")
    df["traffic_condition"] = _safe_numeric(df, "traffic_condition")
    df["hours_since_last_alarm"] = (
        (df["created_at"] - df["created_at"].shift(1)).dt.total_seconds() / 3600.0
    ).fillna(24.0).clip(lower=0.0)

    df["snooze_count"] = _safe_numeric(df, "snooze_count")
    df["unlock_delay"] = _safe_numeric(df, "unlock_delay")
    df["success"] = _safe_numeric(df, "success").clip(0.0, 1.0)
    df["buffer_minutes"] = _safe_numeric(df, "buffer_minutes")

    for name, col, fillna in _ROLLING_METRICS:
        actual_fill = fillna if fillna is not None else defaults.get(col, 0.0)
        _add_rolling(df, col, name, actual_fill)

    df["avg_snooze"] = df[[f"snooze_mean_{w}" for w in ROLLING_WINDOWS]].mean(axis=1)
    df["avg_unlock_delay"] = df[[f"unlock_delay_mean_{w}" for w in ROLLING_WINDOWS]].mean(axis=1)
    df["avg_success_rate"] = df[[f"success_rate_{w}" for w in ROLLING_WINDOWS]].mean(axis=1)

    return df.replace([np.inf, -np.inf], 0.0).fillna(0.0)

def build_live_feature_vector(
    user_logs: list[dict],
    set_time: datetime,
    alarm_type: str,
    weather_severity: float,
    traffic_condition: float,
    is_holiday: int = 0,
    latest_sensor_context: dict | None = None,
    sensor_logs: list[dict] | None = None,
) -> pd.DataFrame:
    logs_df = build_feature_dataframe(user_logs, sensor_logs=sensor_logs)
    defaults = _sensor_defaults()
    ctx = latest_sensor_context or defaults

    row: dict = {
        "alarm_hour": set_time.hour,
        "is_weekday": int(set_time.weekday() < 5),
        "is_holiday": int(is_holiday),
        "alarm_type_enc": encode_alarm_type(alarm_type),
        "weather_severity": float(weather_severity),
        "traffic_condition": float(traffic_condition),
        "hours_since_last_alarm": 24.0,
        "avg_snooze": 0.0,
        "avg_unlock_delay": 0.0,
        "avg_success_rate": 0.0,
        "room_temperature": float(ctx.get("room_temperature", defaults["room_temperature"])),
        "humidity": float(ctx.get("humidity", defaults["humidity"])),
        "motion_detected": int(bool(ctx.get("motion_detected", defaults["motion_detected"]))),
        "light_level": encode_light_level(ctx.get("light_level", defaults["light_level"])),
    }

    for name, col, fillna in _ROLLING_METRICS:
        fill = fillna if fillna is not None else defaults.get(col, 0.0)
        for w in ROLLING_WINDOWS:
            row[f"{name}_{w}"] = fill

    if not logs_df.empty:
        last = logs_df.iloc[-1]
        for name, col, fillna in _ROLLING_METRICS:
            for w in ROLLING_WINDOWS:
                key = f"{name}_{w}"
                row[key] = float(last.get(key, row[key]))
        row["avg_snooze"] = float(last.get("avg_snooze", 0.0))
        row["avg_unlock_delay"] = float(last.get("avg_unlock_delay", 0.0))
        row["avg_success_rate"] = float(last.get("avg_success_rate", 0.0))

        last_created = last.get("created_at")
        if pd.notna(last_created):
            lc = pd.Timestamp(last_created).to_pydatetime()
            if lc.tzinfo is None:
                lc = lc.replace(tzinfo=timezone.utc)
            st = set_time if set_time.tzinfo else set_time.replace(tzinfo=timezone.utc)
            row["hours_since_last_alarm"] = float(max((st - lc).total_seconds() / 3600.0, 0.0))

    return pd.DataFrame([row])[get_feature_columns()]


