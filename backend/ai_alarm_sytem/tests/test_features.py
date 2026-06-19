"""Tests for core/features.py — all pure functions, no external dependencies."""
from datetime import datetime, timezone

import numpy as np
import pytest

from core.features import (
    FEATURE_COLS,
    ROLLING_WINDOWS,
    build_feature_dataframe,
    build_live_feature_vector,
    encode_alarm_type,
    encode_light_level,
    get_feature_columns,
)

# ── encode_alarm_type ─────────────────────────────────────────────────────────

class TestEncodeAlarmType:
    def test_known_types(self):
        assert encode_alarm_type("work") == 0
        assert encode_alarm_type("study") == 1
        assert encode_alarm_type("gym") == 2
        assert encode_alarm_type("custom") == 3

    def test_case_insensitive(self):
        assert encode_alarm_type("WORK") == 0
        assert encode_alarm_type("Study") == 1

    def test_unknown_defaults_to_custom(self):
        assert encode_alarm_type("meeting") == 3

    def test_none_defaults_to_custom(self):
        assert encode_alarm_type(None) == 3

# ── encode_light_level ────────────────────────────────────────────────────────

class TestEncodeLightLevel:
    def test_string_values(self):
        assert encode_light_level("dark") == 0
        assert encode_light_level("dim") == 1
        assert encode_light_level("normal") == 2
        assert encode_light_level("bright") == 3

    def test_int_passthrough(self):
        assert encode_light_level(0) == 0
        assert encode_light_level(3) == 3

    def test_unknown_string_returns_normal(self):
        assert encode_light_level("foggy") == 2

    def test_nan_returns_normal(self):
        assert encode_light_level(float("nan")) == 2

# ── get_feature_columns ───────────────────────────────────────────────────────

class TestGetFeatureColumns:
    def test_includes_base_cols(self):
        cols = get_feature_columns()
        for base in FEATURE_COLS:
            assert base in cols

    def test_includes_rolling_variants(self):
        cols = get_feature_columns()
        for window in ROLLING_WINDOWS:
            assert f"snooze_mean_{window}" in cols
            assert f"success_rate_{window}" in cols
            assert f"temp_mean_{window}" in cols

    def test_no_duplicates(self):
        cols = get_feature_columns()
        assert len(cols) == len(set(cols))

# ── helpers ───────────────────────────────────────────────────────────────────

def _make_log(
    hour: int = 7,
    alarm_type: str = "work",
    snooze: int = 0,
    success: int = 1,
    buffer: float = 10.0,
    date: str = "2024-06-03",
) -> dict:
    base = datetime.fromisoformat(f"{date}T{hour:02d}:00:00+00:00")
    return {
        "created_at": base,
        "trigger_time": base,
        "alarm_type": alarm_type,
        "is_holiday": 0,
        "weather_severity": 1.0,
        "traffic_condition": 2.0,
        "snooze_count": snooze,
        "unlock_delay": 5.0,
        "success": success,
        "buffer_minutes": buffer,
        # Sensor fields are not stored in alarm logs; they come via sensor_logs merge.
    }

# ── build_feature_dataframe ───────────────────────────────────────────────────

class TestBuildFeatureDataframe:
    def test_empty_logs_returns_empty_dataframe(self):
        df = build_feature_dataframe([])
        assert df.empty

    def test_single_row_shape(self):
        df = build_feature_dataframe([_make_log()])
        assert len(df) == 1
        assert all(col in df.columns for col in get_feature_columns())

    def test_alarm_hour_extracted(self):
        df = build_feature_dataframe([_make_log(hour=8)])
        assert df["alarm_hour"].iloc[0] == 8

    def test_is_weekday_monday(self):
        df = build_feature_dataframe([_make_log(date="2024-06-03")])  # Monday
        assert df["is_weekday"].iloc[0] == 1

    def test_alarm_type_encoded(self):
        df = build_feature_dataframe([_make_log(alarm_type="gym")])
        assert df["alarm_type_enc"].iloc[0] == 2

    def test_multiple_rows_all_feature_cols_present(self):
        logs = [_make_log(buffer=float(b)) for b in range(5)]
        df = build_feature_dataframe(logs)
        assert len(df) == 5
        assert all(col in df.columns for col in get_feature_columns())

    def test_no_inf_or_nan_in_features(self):
        logs = [_make_log() for _ in range(10)]
        df = build_feature_dataframe(logs)[get_feature_columns()]
        assert not np.isinf(df.values).any()
        assert not np.isnan(df.values).any()

    def test_rolling_snooze_first_row_uses_fill(self):
        logs = [_make_log(snooze=i) for i in range(5)]
        df = build_feature_dataframe(logs)
        # First row: shifted value is NaN → rolling mean fills with 0.0
        assert df["snooze_mean_3"].iloc[0] == 0.0

    def test_buffer_minutes_preserved(self):
        log = _make_log(buffer=25.0)
        df = build_feature_dataframe([log])
        assert df["buffer_minutes"].iloc[0] == 25.0

    def test_with_sensor_logs_merges_temperature(self):
        import pandas as pd
        log = _make_log()
        sensor = {
            "timestamp": log["created_at"],
            "room_temperature": 22.0,
            "humidity": 55.0,
            "motion_detected": 1,
            "light_level": "bright",
        }
        df = build_feature_dataframe([log], sensor_logs=[sensor])
        assert df["room_temperature"].iloc[0] == 22.0

# ── build_live_feature_vector ─────────────────────────────────────────────────

class TestBuildLiveFeatureVector:
    _SET_TIME = datetime(2024, 6, 3, 7, 30, 0, tzinfo=timezone.utc)

    def test_output_shape(self):
        result = build_live_feature_vector(
            user_logs=[],
            set_time=self._SET_TIME,
            alarm_type="work",
            weather_severity=1.0,
            traffic_condition=2.0,
        )
        assert result.shape == (1, len(get_feature_columns()))

    def test_output_columns_ordered(self):
        result = build_live_feature_vector(
            user_logs=[],
            set_time=self._SET_TIME,
            alarm_type="gym",
            weather_severity=0.5,
            traffic_condition=1.5,
        )
        assert list(result.columns) == get_feature_columns()

    def test_alarm_hour_correct(self):
        result = build_live_feature_vector(
            user_logs=[],
            set_time=self._SET_TIME,
            alarm_type="work",
            weather_severity=0.0,
            traffic_condition=0.0,
        )
        assert result["alarm_hour"].iloc[0] == 7

    def test_alarm_type_encoded(self):
        result = build_live_feature_vector(
            user_logs=[],
            set_time=self._SET_TIME,
            alarm_type="study",
            weather_severity=0.0,
            traffic_condition=0.0,
        )
        assert result["alarm_type_enc"].iloc[0] == 1

    def test_sensor_context_applied(self):
        sensor = {
            "room_temperature": 20.0,
            "humidity": 50.0,
            "motion_detected": 1,
            "light_level": "bright",
        }
        result = build_live_feature_vector(
            user_logs=[],
            set_time=self._SET_TIME,
            alarm_type="custom",
            weather_severity=0.0,
            traffic_condition=0.0,
            latest_sensor_context=sensor,
        )
        assert result["room_temperature"].iloc[0] == 20.0
        assert result["light_level"].iloc[0] == 3  # bright → 3

    def test_rolling_stats_from_logs(self):
        logs = [_make_log(snooze=3, buffer=20.0) for _ in range(7)]
        set_time = datetime(2024, 6, 10, 8, 0, 0, tzinfo=timezone.utc)
        result = build_live_feature_vector(
            user_logs=logs,
            set_time=set_time,
            alarm_type="work",
            weather_severity=0.0,
            traffic_condition=0.0,
        )
        assert result["avg_snooze"].iloc[0] > 0

    def test_is_weekday_flag(self):
        # 2024-06-03 is Monday → is_weekday = 1
        result = build_live_feature_vector(
            user_logs=[],
            set_time=self._SET_TIME,
            alarm_type="work",
            weather_severity=0.0,
            traffic_condition=0.0,
        )
        assert result["is_weekday"].iloc[0] == 1
