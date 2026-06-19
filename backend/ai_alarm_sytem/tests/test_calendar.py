"""Tests for integrations/calendar.py."""
from datetime import date, datetime, timedelta, timezone
from unittest.mock import MagicMock, patch

import pytest

from integrations.calendar import (
    _build_events,
    _is_busy_event,
    _is_expired,
    _parse_event_time,
    _validate_state,
    adjust_buffer_for_calendar,
    get_integration_status,
)


# ── _is_expired ───────────────────────────────────────────────────────────────

class TestIsExpired:
    def test_no_expires_at_is_expired(self):
        assert _is_expired({}) is True

    def test_past_datetime_is_expired(self):
        past = (datetime.now(timezone.utc) - timedelta(hours=1)).isoformat()
        assert _is_expired({"expires_at": past}) is True

    def test_future_datetime_not_expired(self):
        future = (datetime.now(timezone.utc) + timedelta(hours=1)).isoformat()
        assert _is_expired({"expires_at": future}) is False

    def test_naive_datetime_treated_as_utc(self):
        # Stored without tz info — should be treated as UTC
        past = (datetime.now(timezone.utc) - timedelta(hours=1)).replace(tzinfo=None)
        assert _is_expired({"expires_at": past}) is True


# ── _parse_event_time ─────────────────────────────────────────────────────────

class TestParseEventTime:
    def test_datetime_with_offset(self):
        result = _parse_event_time({"dateTime": "2024-06-03T09:00:00+05:30"})
        assert result is not None
        assert result.tzinfo is not None

    def test_datetime_z_suffix(self):
        result = _parse_event_time({"dateTime": "2024-06-03T09:00:00Z"})
        assert result is not None

    def test_date_only_returns_midnight_utc(self):
        result = _parse_event_time({"date": "2024-06-03"})
        assert result is not None
        assert result.date() == date(2024, 6, 3)
        assert result.tzinfo is not None

    def test_empty_dict_returns_none(self):
        assert _parse_event_time({}) is None

    def test_invalid_datetime_returns_none(self):
        assert _parse_event_time({"dateTime": "not-a-date"}) is None

    def test_invalid_date_returns_none(self):
        assert _parse_event_time({"date": "32-13-2024"}) is None


# ── _is_busy_event ────────────────────────────────────────────────────────────

class TestIsBusyEvent:
    def test_normal_confirmed_event(self):
        event = {"status": "confirmed", "summary": "Team meeting"}
        assert _is_busy_event(event) is True

    def test_cancelled_not_busy(self):
        assert _is_busy_event({"status": "cancelled", "summary": "X"}) is False

    def test_transparent_not_busy(self):
        assert _is_busy_event({"transparency": "transparent", "summary": "X"}) is False

    def test_no_summary_not_busy(self):
        assert _is_busy_event({"status": "confirmed"}) is False

    def test_opaque_is_busy(self):
        assert _is_busy_event({"status": "confirmed", "summary": "X", "transparency": "opaque"}) is True


# ── _build_events ─────────────────────────────────────────────────────────────

class TestBuildEvents:
    def _event(
        self,
        start: str = "2024-06-03T09:00:00Z",
        end: str = "2024-06-03T10:00:00Z",
        summary: str = "Meeting",
        status: str = "confirmed",
        event_id: str = "evt1",
    ) -> dict:
        return {
            "id": event_id,
            "summary": summary,
            "status": status,
            "start": {"dateTime": start},
            "end": {"dateTime": end},
            "organizer": {"email": "host@example.com"},
        }

    def test_single_valid_event(self):
        result = _build_events([self._event()])
        assert len(result) == 1
        assert result[0]["summary"] == "Meeting"
        assert result[0]["event_id"] == "evt1"

    def test_skips_cancelled(self):
        assert _build_events([self._event(status="cancelled")]) == []

    def test_skips_missing_time(self):
        e = {"id": "x", "summary": "Y", "status": "confirmed", "start": {}, "end": {}}
        assert _build_events([e]) == []

    def test_times_converted_to_utc(self):
        result = _build_events([self._event()])
        assert result[0]["start_time"].tzinfo is not None
        assert result[0]["end_time"].tzinfo is not None

    def test_include_location_flag(self):
        e = self._event()
        e["location"] = "Conference Room A"
        result = _build_events([e], include_location=True)
        assert result[0]["location"] == "Conference Room A"

    def test_no_location_field_without_flag(self):
        result = _build_events([self._event()])
        assert "location" not in result[0]

    def test_multiple_events_ordered(self):
        events = [
            self._event(start="2024-06-03T10:00:00Z", end="2024-06-03T11:00:00Z", event_id="e2"),
            self._event(start="2024-06-03T09:00:00Z", end="2024-06-03T10:00:00Z", event_id="e1"),
        ]
        result = _build_events(events)
        assert len(result) == 2


# ── _validate_state ───────────────────────────────────────────────────────────

class TestValidateState:
    def _creds_col(self, state: str, expires: datetime) -> MagicMock:
        col = MagicMock()
        col.find_one.return_value = {
            "user_id": "user1",
            "oauth_state": state,
            "oauth_state_expires_at": expires.isoformat(),
        }
        return col

    def test_valid_state(self):
        future = datetime.now(timezone.utc) + timedelta(minutes=5)
        col = self._creds_col("valid_state", future)
        with patch("integrations.calendar.get_collections", return_value={"calendar_credentials": col}):
            assert _validate_state("user1", "valid_state") is True

    def test_wrong_state(self):
        future = datetime.now(timezone.utc) + timedelta(minutes=5)
        col = self._creds_col("correct_state", future)
        with patch("integrations.calendar.get_collections", return_value={"calendar_credentials": col}):
            assert _validate_state("user1", "wrong_state") is False

    def test_expired_state(self):
        past = datetime.now(timezone.utc) - timedelta(minutes=1)
        col = self._creds_col("state", past)
        with patch("integrations.calendar.get_collections", return_value={"calendar_credentials": col}):
            assert _validate_state("user1", "state") is False

    def test_no_credentials(self):
        col = MagicMock()
        col.find_one.return_value = None
        with patch("integrations.calendar.get_collections", return_value={"calendar_credentials": col}):
            assert _validate_state("user1", "anything") is False


# ── get_integration_status ────────────────────────────────────────────────────

class TestGetIntegrationStatus:
    def _col(self, doc) -> MagicMock:
        col = MagicMock()
        col.find_one.return_value = doc
        return col

    def test_no_credentials_not_connected(self):
        with patch("integrations.calendar.get_collections",
                   return_value={"calendar_credentials": self._col(None)}):
            result = get_integration_status("user1")
        assert result["connected"] is False

    def test_expired_token_shows_expired(self):
        past = (datetime.now(timezone.utc) - timedelta(hours=1)).isoformat()
        creds = {"access_token": "tok", "expires_at": past}
        with patch("integrations.calendar.get_collections",
                   return_value={"calendar_credentials": self._col(creds)}):
            result = get_integration_status("user1")
        assert result["connected"] is True
        assert result["token_expired"] is True

    def test_valid_token_connected_and_active(self):
        future = (datetime.now(timezone.utc) + timedelta(hours=1)).isoformat()
        creds = {"access_token": "tok", "expires_at": future, "updated_at": datetime.now(timezone.utc)}
        with patch("integrations.calendar.get_collections",
                   return_value={"calendar_credentials": self._col(creds)}):
            result = get_integration_status("user1")
        assert result["connected"] is True
        assert result["token_expired"] is False


# ── adjust_buffer_for_calendar ────────────────────────────────────────────────

class TestAdjustBufferForCalendar:
    def _settings(self, prep: int = 45, threshold: int = 120) -> MagicMock:
        m = MagicMock()
        m.calendar_busy_threshold_minutes = threshold
        m.calendar_prep_minutes = prep
        m.calendar_cache_ttl_minutes = 30
        return m

    def _event(self, minutes_from_now: float) -> dict:
        now = datetime.now(timezone.utc)
        start = now + timedelta(minutes=minutes_from_now)
        return {
            "event_id": "evt1",
            "summary": "Stand-up",
            "start_time": start,
            "end_time": start + timedelta(hours=1),
            "organizer": "host@example.com",
        }

    def test_no_events_returns_predicted_unchanged(self):
        with patch("integrations.calendar.get_settings", return_value=self._settings()), \
             patch("integrations.calendar.get_busy_events", return_value=[]):
            buffer, ctx = adjust_buffer_for_calendar("user1", datetime.now(timezone.utc), 10.0)
        assert buffer == 10.0
        assert ctx["calendar_adjustment_applied"] is False

    def test_imminent_event_increases_buffer(self):
        # Event in 10 min, prep time = 45 → extra = 45 - 10 = 35
        with patch("integrations.calendar.get_settings", return_value=self._settings(prep=45)), \
             patch("integrations.calendar.get_busy_events", return_value=[self._event(10)]):
            buffer, ctx = adjust_buffer_for_calendar("user1", datetime.now(timezone.utc), 5.0)
        assert buffer > 5.0
        assert ctx["calendar_adjustment_applied"] is True
        assert ctx["additional_buffer_minutes"] == pytest.approx(35.0, abs=1.0)

    def test_event_beyond_prep_window_no_extra(self):
        # Event in 60 min, prep time = 45 → extra = max(0, 45-60) = 0
        with patch("integrations.calendar.get_settings", return_value=self._settings(prep=45)), \
             patch("integrations.calendar.get_busy_events", return_value=[self._event(60)]):
            buffer, ctx = adjust_buffer_for_calendar("user1", datetime.now(timezone.utc), 10.0)
        assert buffer == 10.0
        assert ctx["calendar_adjustment_applied"] is False

    def test_past_event_ignored(self):
        with patch("integrations.calendar.get_settings", return_value=self._settings()), \
             patch("integrations.calendar.get_busy_events", return_value=[self._event(-30)]):
            buffer, ctx = adjust_buffer_for_calendar("user1", datetime.now(timezone.utc), 10.0)
        assert buffer == 10.0
        assert ctx["calendar_adjustment_applied"] is False

    def test_calendar_error_returns_predicted_buffer(self):
        with patch("integrations.calendar.get_settings", return_value=self._settings()), \
             patch("integrations.calendar.get_busy_events", side_effect=RuntimeError("DB error")):
            buffer, ctx = adjust_buffer_for_calendar("user1", datetime.now(timezone.utc), 10.0)
        assert buffer == 10.0
        assert ctx["calendar_adjustment_applied"] is False
        assert "error" in ctx
