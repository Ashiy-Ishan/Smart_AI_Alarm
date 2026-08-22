"""Tests for Flask routes in main.py.

conftest.py patches firebase_admin.initialize_app and db.collections.ensure_indexes
at module level so that importing main.py does not fail without real Firebase credentials
or a running MongoDB.
"""
from datetime import datetime, timezone
from unittest.mock import patch

import pytest

@pytest.fixture(scope="module")
def app():
    import main  # noqa: PLC0415 — imported here so conftest patches are in place first
    main._app.config["TESTING"] = True
    return main._app

@pytest.fixture()
def client(app):
    return app.test_client()

# _parse_dt 

class TestParseDt:
    def test_none_returns_none(self):
        import main
        assert main._parse_dt(None) is None

    def test_valid_iso_z_suffix(self):
        import main
        result = main._parse_dt("2024-06-03T07:00:00Z")
        assert result is not None
        assert result.tzinfo is not None

    def test_datetime_without_tz_gets_utc(self):
        import main
        dt = datetime(2024, 6, 3, 7, 0, 0)
        result = main._parse_dt(dt)
        assert result.tzinfo is not None

    def test_datetime_with_tz_unchanged(self):
        import main
        dt = datetime(2024, 6, 3, 7, 0, 0, tzinfo=timezone.utc)
        assert main._parse_dt(dt) == dt

    def test_invalid_string_returns_none(self):
        import main
        assert main._parse_dt("not-a-date") is None

# /health 

class TestHealthRoute:
    def test_returns_ok(self, client):
        resp = client.get("/health")
        assert resp.status_code == 200
        assert resp.get_json() == {"status": "ok"}
        
# /alarms 

class TestCreateAlarmRoute:
    def test_missing_user_id(self, client):
        resp = client.post("/alarms", json={"set_time": "2024-06-03T07:00:00Z"})
        assert resp.status_code == 422

    def test_missing_set_time(self, client):
        resp = client.post("/alarms", json={"user_id": "user1"})
        assert resp.status_code == 422

    def test_invalid_set_time(self, client):
        resp = client.post("/alarms", json={"user_id": "user1", "set_time": "not-a-date"})
        assert resp.status_code == 422

    def test_success(self, client):
        alarm = {
            "_id": "alarm1",
            "user_id": "user1",
            "set_time": datetime(2024, 6, 3, 7, 0, 0, tzinfo=timezone.utc),
            "adjusted_time": datetime(2024, 6, 3, 6, 50, 0, tzinfo=timezone.utc),
            "predicted_buffer_minutes": 10.0,
            "final_buffer_minutes": 10.0,
        }
        with patch("core.alarm.create_alarm", return_value=alarm):
            resp = client.post("/alarms", json={"user_id": "user1", "set_time": "2024-06-03T07:00:00Z"})
        assert resp.status_code == 201
        data = resp.get_json()
        assert data["user_id"] == "user1"

    def test_create_alarm_exception_returns_500(self, client):
        with patch("core.alarm.create_alarm", side_effect=RuntimeError("db down")):
            resp = client.post("/alarms", json={"user_id": "user1", "set_time": "2024-06-03T07:00:00Z"})
        assert resp.status_code == 500

# /alarms/outcome 

class TestAlarmOutcomeRoute:
    def test_missing_user_id(self, client):
        resp = client.post("/alarms/outcome", json={"alarm_id": "a1", "trigger_time": "2024-06-03T07:00:00Z"})
        assert resp.status_code == 422

    def test_missing_alarm_id(self, client):
        resp = client.post("/alarms/outcome", json={"user_id": "user1", "trigger_time": "2024-06-03T07:00:00Z"})
        assert resp.status_code == 422

    def test_missing_trigger_time(self, client):
        resp = client.post("/alarms/outcome", json={"user_id": "user1", "alarm_id": "a1"})
        assert resp.status_code == 422

    def test_success(self, client):
        with patch("core.alarm.log_alarm_outcome", return_value="log_id_1"):
            resp = client.post("/alarms/outcome", json={
                "user_id": "user1",
                "alarm_id": "alarm1",
                "trigger_time": "2024-06-03T07:00:00Z",
            })
        assert resp.status_code == 201
        assert resp.get_json()["log_id"] == "log_id_1"

    def test_exception_returns_400(self, client):
        with patch("core.alarm.log_alarm_outcome", side_effect=ValueError("bad data")):
            resp = client.post("/alarms/outcome", json={
                "user_id": "user1",
                "alarm_id": "a1",
                "trigger_time": "2024-06-03T07:00:00Z",
            })
        assert resp.status_code == 400

# /calendar routes 

class TestCalendarRoutes:
    def test_oauth_start_missing_user_id(self, client):
        resp = client.get("/calendar/oauth/start")
        assert resp.status_code == 422

    def test_oauth_start_success(self, client):
        with patch("integrations.calendar.get_authorization_url", return_value="https://accounts.google.com/auth"):
            resp = client.get("/calendar/oauth/start?user_id=user1")
        assert resp.status_code == 200
        assert "login_url" in resp.get_json()

    def test_oauth_callback_missing_params(self, client):
        resp = client.get("/calendar/oauth/callback?user_id=u1")
        assert resp.status_code == 422

    def test_oauth_callback_invalid_state(self, client):
        with patch("integrations.calendar.handle_oauth_callback", return_value=(False, "Invalid or expired OAuth state")):
            resp = client.get("/calendar/oauth/callback?user_id=u1&code=code&state=bad")
        assert resp.status_code == 400

    def test_oauth_callback_success(self, client):
        with patch("integrations.calendar.handle_oauth_callback", return_value=(True, "Calendar connected successfully")):
            resp = client.get("/calendar/oauth/callback?user_id=u1&code=code&state=state")
        assert resp.status_code == 200
        assert resp.get_json()["success"] is True

    def test_calendar_status(self, client):
        with patch("integrations.calendar.get_integration_status", return_value={"connected": False}):
            resp = client.get("/calendar/status/user1")
        assert resp.status_code == 200
        assert resp.get_json()["connected"] is False

    def test_calendar_events_empty(self, client):
        with patch("integrations.calendar.get_upcoming_events", return_value=[]):
            resp = client.get("/calendar/events/user1")
        assert resp.status_code == 200
        data = resp.get_json()
        assert data["count"] == 0
        assert data["events"] == []

    def test_calendar_revoke_not_found(self, client):
        with patch("integrations.calendar.revoke_access", return_value=(False, "No calendar access found")):
            resp = client.delete("/calendar/access/user1")
        assert resp.status_code == 400

    def test_calendar_revoke_success(self, client):
        with patch("integrations.calendar.revoke_access", return_value=(True, "Calendar access revoked")):
            resp = client.delete("/calendar/access/user1")
        assert resp.status_code == 200

    def test_clear_cache_user(self, client):
        with patch("integrations.calendar.clear_cache") as mock_cc:
            resp = client.delete("/calendar/cache/user1")
        assert resp.status_code == 200
        mock_cc.assert_called_once_with("user1")

    def test_clear_cache_all(self, client):
        with patch("integrations.calendar.clear_cache") as mock_cc:
            resp = client.delete("/calendar/cache")
        assert resp.status_code == 200
        mock_cc.assert_called_once_with()

# ── /iot routes ───────────────────────────────────────────────────────────────

class TestIotRoutes:
    _FULL_PAYLOAD = {
        "user_id": "user1",
        "room_temperature": 25.0,
        "humidity": 60.0,
        "motion_detected": False,
        "light_level": "dim",
    }

    def test_missing_user_id(self, client):
        payload = {k: v for k, v in self._FULL_PAYLOAD.items() if k != "user_id"}
        resp = client.post("/iot/sensor", json=payload)
        assert resp.status_code == 422

    def test_sensor_value_error_returns_422(self, client):
        with patch("integrations.iot.store_sensor_reading", side_effect=ValueError("missing fields")):
            resp = client.post("/iot/sensor", json=self._FULL_PAYLOAD)
        assert resp.status_code == 422

    def test_sensor_success(self, client):
        doc = {
            "_id": "s1",
            "user_id": "user1",
            "room_temperature": 25.0,
            "humidity": 60.0,
            "motion_detected": False,
            "light_level": "dim",
            "timestamp": datetime.now(timezone.utc),
        }
        with patch("integrations.iot.store_sensor_reading", return_value=doc):
            resp = client.post("/iot/sensor", json=self._FULL_PAYLOAD)
        assert resp.status_code == 201

    def test_iot_latest(self, client):
        reading = {"user_id": "user1", "room_temperature": 25.0}
        with patch("integrations.iot.get_latest_reading", return_value=reading):
            resp = client.get("/iot/sensor/user1/latest")
        assert resp.status_code == 200
        assert resp.get_json()["room_temperature"] == 25.0