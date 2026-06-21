"""Tests for integrations/iot.py."""
from datetime import datetime, timezone
from unittest.mock import MagicMock, patch

import pytest

from integrations.iot import (
    _coerce_bool,
    _coerce_float,
    _coerce_light_level,
    _coerce_timestamp,
    get_latest_reading,
    get_recent_readings,
    store_sensor_reading,
)


# pure helper functions


class TestCoerceFloat:
    def test_int(self):
        assert _coerce_float(25, 0.0) == 25.0

    def test_float_string(self):
        assert _coerce_float("22.5", 0.0) == 22.5

    def test_none_uses_fallback(self):
        assert _coerce_float(None, 27.0) == 27.0

    def test_invalid_string_uses_fallback(self):
        assert _coerce_float("abc", 5.0) == 5.0

    def test_zero(self):
        assert _coerce_float(0, 99.0) == 0.0


class TestCoerceBool:
    def test_true_bool(self):
        assert _coerce_bool(True) is True

    def test_false_bool(self):
        assert _coerce_bool(False) is False

    def test_one_int(self):
        assert _coerce_bool(1) is True

    def test_zero_int(self):
        assert _coerce_bool(0) is False

    def test_truthy_strings(self):
        for s in ["1", "true", "yes", "on"]:
            assert _coerce_bool(s) is True, f"Expected True for {s!r}"

    def test_falsy_string(self):
        assert _coerce_bool("false") is False
        assert _coerce_bool("no") is False

    def test_none_is_false(self):
        assert _coerce_bool(None) is False

    def test_float_one(self):
        assert _coerce_bool(1.0) is True


class TestCoerceLightLevel:
    def test_valid_levels(self):
        for v in ("dark", "dim", "normal", "bright"):
            assert _coerce_light_level(v) == v

    def test_strips_whitespace(self):
        assert _coerce_light_level("  dim  ") == "dim"

    def test_case_insensitive(self):
        assert _coerce_light_level("DARK") == "dark"
        assert _coerce_light_level("Bright") == "bright"

    def test_invalid_returns_fallback(self):
        assert _coerce_light_level("foggy", "dim") == "dim"

    def test_invalid_no_fallback_returns_normal(self):
        assert _coerce_light_level("foggy") == "normal"

    def test_invalid_fallback_also_invalid_returns_normal(self):
        assert _coerce_light_level("foggy", "also_invalid") == "normal"


class TestCoerceTimestamp:
    def test_datetime_with_tz(self):
        dt = datetime(2024, 1, 1, 12, 0, tzinfo=timezone.utc)
        assert _coerce_timestamp(dt) == dt

    def test_datetime_without_tz_gets_utc(self):
        dt = datetime(2024, 1, 1, 12, 0)
        result = _coerce_timestamp(dt)
        assert result.tzinfo is not None

    def test_iso_string_z_suffix(self):
        result = _coerce_timestamp("2024-01-01T12:00:00Z")
        assert result.year == 2024
        assert result.tzinfo is not None

    def test_iso_string_offset(self):
        result = _coerce_timestamp("2024-01-01T12:00:00+05:30")
        assert result.tzinfo is not None

    def test_invalid_string_returns_now(self):
        before = datetime.now(timezone.utc)
        result = _coerce_timestamp("not-a-date")
        after = datetime.now(timezone.utc)
        assert before <= result <= after


# DB-backed functions


def _mock_settings() -> MagicMock:
    m = MagicMock()
    m.default_room_temperature = 27.0
    m.default_humidity = 65.0
    m.default_motion_detected = 0
    m.default_light_level = "normal"
    return m


def _sensor_col(find_one_result=None, recent_docs=None):
    col = MagicMock()
    col.find_one.return_value = find_one_result
    mock_cursor = MagicMock()
    mock_cursor.__iter__ = MagicMock(return_value=iter(recent_docs or []))
    mock_cursor.limit.return_value = mock_cursor
    col.find.return_value = mock_cursor
    return col


class TestStoreSensorReading:
    _VALID_PAYLOAD = {
        "room_temperature": 25.0,
        "humidity": 60.0,
        "motion_detected": True,
        "light_level": "dim",
    }

    def test_empty_user_id_raises(self):
        with pytest.raises(ValueError, match="user_id is required"):
            store_sensor_reading("", self._VALID_PAYLOAD.copy())

    def test_missing_required_field_raises(self):
        payload = {k: v for k, v in self._VALID_PAYLOAD.items() if k != "humidity"}
        with pytest.raises(ValueError, match="Missing sensor fields"):
            store_sensor_reading("user1", payload)

    def test_missing_multiple_fields_listed(self):
        with pytest.raises(ValueError, match="Missing sensor fields"):
            store_sensor_reading("user1", {})

    def test_valid_payload_returns_doc(self):
        inserted_id = "507f1f77bcf86cd799439011"
        mock_result = MagicMock()
        mock_result.inserted_id = inserted_id

        col = MagicMock()
        col.insert_one.return_value = mock_result

        with patch("integrations.iot.get_settings", return_value=_mock_settings()), \
             patch("integrations.iot.get_collections", return_value={"iot_sensor_logs": col}):
            doc = store_sensor_reading("user1", self._VALID_PAYLOAD.copy())

        assert doc["user_id"] == "user1"
        assert doc["room_temperature"] == 25.0
        assert doc["motion_detected"] is True
        assert doc["light_level"] == "dim"
        assert doc["_id"] == inserted_id

    def test_coerces_string_temperature(self):
        payload = {**self._VALID_PAYLOAD, "room_temperature": "22.5"}
        mock_result = MagicMock()
        mock_result.inserted_id = "id1"
        col = MagicMock()
        col.insert_one.return_value = mock_result

        with patch("integrations.iot.get_settings", return_value=_mock_settings()), \
             patch("integrations.iot.get_collections", return_value={"iot_sensor_logs": col}):
            doc = store_sensor_reading("user1", payload)

        assert doc["room_temperature"] == 22.5

    def test_adds_timestamp_if_missing(self):
        mock_result = MagicMock()
        mock_result.inserted_id = "id1"
        col = MagicMock()
        col.insert_one.return_value = mock_result

        with patch("integrations.iot.get_settings", return_value=_mock_settings()), \
             patch("integrations.iot.get_collections", return_value={"iot_sensor_logs": col}):
            doc = store_sensor_reading("user1", self._VALID_PAYLOAD.copy())

        assert isinstance(doc["timestamp"], datetime)


class TestGetLatestReading:
    def test_no_doc_returns_defaults(self):
        col = _sensor_col(find_one_result=None)
        with patch("integrations.iot.get_settings", return_value=_mock_settings()), \
             patch("integrations.iot.get_collections", return_value={"iot_sensor_logs": col}):
            result = get_latest_reading("user1")

        assert result["user_id"] == "user1"
        assert result["room_temperature"] == 27.0
        assert result["humidity"] == 65.0

    def test_existing_doc_returned(self):
        stored = {
            "_id": MagicMock(__str__=lambda s: "doc_id"),
            "user_id": "user1",
            "room_temperature": 22.0,
            "humidity": 55.0,
            "motion_detected": False,
            "light_level": "bright",
        }
        col = _sensor_col(find_one_result=stored)
        with patch("integrations.iot.get_settings", return_value=_mock_settings()), \
             patch("integrations.iot.get_collections", return_value={"iot_sensor_logs": col}):
            result = get_latest_reading("user1")

        assert result["room_temperature"] == 22.0
        assert result["_id"] == "doc_id"


class TestGetRecentReadings:
    def test_returns_list_in_ascending_order(self):
        # DB returns newest-first (ts=2, ts=1, ts=0); get_recent_readings reverses → oldest first.
        docs = [
            {"_id": MagicMock(__str__=lambda s: f"id{i}"), "ts": i}
            for i in range(3)
        ]
        col = _sensor_col(recent_docs=docs[::-1])  # newest-first from DB
        with patch("integrations.iot.get_collections", return_value={"iot_sensor_logs": col}):
            result = get_recent_readings("user1")

        assert result[0]["ts"] == 0  # oldest first after reverse

    def test_empty_returns_empty_list(self):
        col = _sensor_col(recent_docs=[])
        with patch("integrations.iot.get_collections", return_value={"iot_sensor_logs": col}):
            result = get_recent_readings("user1")
        assert result == []
