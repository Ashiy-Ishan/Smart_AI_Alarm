"""Tests for notifications/email.py."""
import smtplib
from datetime import datetime, timezone
from unittest.mock import MagicMock, call, patch

from notifications.email import notify_buffer_change, notify_training_completed, send_email


def _settings(enabled: int = 1, host: str = "smtp.example.com", from_email: str = "no-reply@example.com") -> MagicMock:
    m = MagicMock()
    m.email_notifications_enabled = enabled
    m.smtp_host = host
    m.smtp_port = 587
    m.smtp_username = "smtp_user"
    m.smtp_password = "smtp_pass"
    m.smtp_from_email = from_email
    m.smtp_use_tls = 1
    return m


def _smtp_mock() -> MagicMock:
    smtp = MagicMock()
    smtp.__enter__ = MagicMock(return_value=smtp)
    smtp.__exit__ = MagicMock(return_value=False)
    return smtp


# ── send_email ────────────────────────────────────────────────────────────────

class TestSendEmail:
    def test_disabled_via_setting(self):
        with patch("notifications.email.get_settings", return_value=_settings(enabled=0)):
            assert send_email("to@example.com", "Subject", "Body") is False

    def test_missing_smtp_host(self):
        with patch("notifications.email.get_settings", return_value=_settings(host="")):
            assert send_email("to@example.com", "Subject", "Body") is False

    def test_missing_from_email(self):
        with patch("notifications.email.get_settings", return_value=_settings(from_email="")):
            assert send_email("to@example.com", "Subject", "Body") is False

    def test_missing_to_email(self):
        with patch("notifications.email.get_settings", return_value=_settings()):
            assert send_email("", "Subject", "Body") is False

    def test_successful_send(self):
        smtp = _smtp_mock()
        with patch("notifications.email.get_settings", return_value=_settings()), \
             patch("notifications.email.smtplib.SMTP", return_value=smtp):
            result = send_email("to@example.com", "Subject", "Body")
        assert result is True
        smtp.starttls.assert_called_once()
        smtp.login.assert_called_once_with("smtp_user", "smtp_pass")
        smtp.sendmail.assert_called_once()

    def test_smtp_exception_returns_false(self):
        with patch("notifications.email.get_settings", return_value=_settings()), \
             patch("notifications.email.smtplib.SMTP", side_effect=smtplib.SMTPException("refused")):
            assert send_email("to@example.com", "Subject", "Body") is False

    def test_os_error_returns_false(self):
        with patch("notifications.email.get_settings", return_value=_settings()), \
             patch("notifications.email.smtplib.SMTP", side_effect=OSError("network")):
            assert send_email("to@example.com", "Subject", "Body") is False


# ── notify_training_completed ─────────────────────────────────────────────────

class TestNotifyTrainingCompleted:
    def _col(self, email: str | None) -> MagicMock:
        col = MagicMock()
        col.find_one.return_value = {"email": email} if email else None
        return col

    def test_no_user_record_skips(self):
        with patch("notifications.email.get_collections",
                   return_value={"users": self._col(None)}):
            assert notify_training_completed("user1", {"trained": True, "metrics": {}}) is False

    def test_email_as_user_id_used_directly(self):
        with patch("notifications.email.send_email", return_value=True) as mock_send:
            notify_training_completed("user@example.com", {"trained": True, "metrics": {"data_points": 50, "mae": 1.0, "rmse": 1.5, "r2": 0.9}})
        mock_send.assert_called_once()
        assert mock_send.call_args[0][0] == "user@example.com"

    def test_success_email_subject_contains_retrained(self):
        metrics = {"data_points": 50, "mae": 2.5, "rmse": 3.1, "r2": 0.85}
        with patch("notifications.email.get_collections",
                   return_value={"users": self._col("u@example.com")}), \
             patch("notifications.email.send_email", return_value=True) as mock_send:
            result = notify_training_completed("user1", {"trained": True, "metrics": metrics})
        assert result is True
        subject = mock_send.call_args[0][1]
        assert "Retrained" in subject

    def test_skipped_email_subject_contains_skipped(self):
        with patch("notifications.email.get_collections",
                   return_value={"users": self._col("u@example.com")}), \
             patch("notifications.email.send_email", return_value=True) as mock_send:
            notify_training_completed("user1", {"trained": False, "reason": "too few data points"})
        subject = mock_send.call_args[0][1]
        assert "Skipped" in subject

    def test_skipped_body_contains_reason(self):
        with patch("notifications.email.get_collections",
                   return_value={"users": self._col("u@example.com")}), \
             patch("notifications.email.send_email", return_value=True) as mock_send:
            notify_training_completed("user1", {"trained": False, "reason": "need 14 data points"})
        body = mock_send.call_args[0][2]
        assert "need 14 data points" in body


# ── notify_buffer_change ──────────────────────────────────────────────────────

class TestNotifyBufferChange:
    _NOW = datetime(2024, 6, 3, 7, 0, 0, tzinfo=timezone.utc)

    def test_no_change_sends_nothing(self):
        assert notify_buffer_change("u@example.com", self._NOW, 10.0, 10.0) is False

    def test_tiny_change_below_threshold_sends_nothing(self):
        assert notify_buffer_change("u@example.com", self._NOW, 10.0, 10.0 + 1e-7) is False

    def test_buffer_increased_subject(self):
        with patch("notifications.email.send_email", return_value=True) as mock_send:
            notify_buffer_change("u@example.com", self._NOW, 10.0, 15.0)
        subject = mock_send.call_args[0][1]
        assert "Increased" in subject

    def test_buffer_reduced_subject(self):
        with patch("notifications.email.send_email", return_value=True) as mock_send:
            notify_buffer_change("u@example.com", self._NOW, 15.0, 10.0)
        subject = mock_send.call_args[0][1]
        assert "Reduced" in subject

    def test_body_contains_buffer_values(self):
        with patch("notifications.email.send_email", return_value=True) as mock_send:
            notify_buffer_change("u@example.com", self._NOW, 10.0, 15.0)
        body = mock_send.call_args[0][2]
        assert "10.00" in body
        assert "15.00" in body

    def test_no_email_for_unresolvable_user(self):
        col = MagicMock()
        col.find_one.return_value = None
        with patch("notifications.email.get_collections", return_value={"users": col}):
            result = notify_buffer_change("user_with_no_email", self._NOW, 5.0, 10.0)
        assert result is False
