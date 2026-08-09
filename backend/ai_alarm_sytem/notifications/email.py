from __future__ import annotations
import smtplib
from email.mime.text import MIMEText

import importlib
from config.settings import get_settings
from db.collections import get_collections, USERS


def _resolve_email(user_id: str) -> str | None:
    if "@" in user_id:
        return user_id
    try:
        users = get_collections()[USERS]
        doc = users.find_one({"user_id": user_id})
        if not doc:
            try:
                object_id_cls = getattr(importlib.import_module("bson.objectid"), "ObjectId", None)
                if object_id_cls and object_id_cls.is_valid(user_id):
                    doc = users.find_one({"_id": object_id_cls(user_id)})
            except Exception:
                pass
        return str(doc["email"]) if doc and doc.get("email") else None
    except Exception as exc:
        import logging
        logging.getLogger(__name__).warning("Database error resolving email for user %s: %s", user_id, exc)
        return None





def send_email(to_email: str, subject: str, body: str) -> bool:
    settings = get_settings()
    if not settings.email_notifications_enabled:
        return False
    if not (settings.smtp_host and settings.smtp_from_email and to_email):
        return False

    msg = MIMEText(body, "plain", "utf-8")
    msg["Subject"] = subject
    msg["From"] = settings.smtp_from_email
    msg["To"] = to_email

    try:
        with smtplib.SMTP(settings.smtp_host, int(settings.smtp_port), timeout=10) as server:
            if bool(settings.smtp_use_tls):
                server.starttls()
            if settings.smtp_username and settings.smtp_password:
                server.login(settings.smtp_username, settings.smtp_password)
            server.sendmail(settings.smtp_from_email, [to_email], msg.as_string())
        return True
    except (smtplib.SMTPException, OSError):
        return False


def notify_training_completed(user_id: str, result: dict) -> bool:
    to_email = _resolve_email(user_id)
    if not to_email:
        return False

    if result.get("trained"):
        m = result.get("metrics", {})
        subject = "AI Alarm — Model Retrained"
        body = (
            f"Your alarm model was retrained successfully.\n\n"
            f"Data points: {m.get('data_points', '?')}\n"
            f"MAE:  {m.get('mae', 0):.4f} min\n"
            f"RMSE: {m.get('rmse', 0):.4f} min\n"
            f"R²:   {m.get('r2', 0):.4f}\n\n"
            "AI Alarm System"
        )
    else:
        subject = "AI Alarm — Model Training Skipped"
        body = (
            f"Scheduled training was skipped.\n"
            f"Reason: {result.get('reason', 'unknown')}\n\n"
            "AI Alarm System"
        )
    return send_email(to_email, subject, body)


def notify_buffer_change(
    user_id: str,
    set_time,
    predicted_buffer_minutes: float,
    final_buffer_minutes: float,
    reason: str = "context update",
) -> bool:
    to_email = _resolve_email(user_id)
    if not to_email:
        return False

    delta = float(final_buffer_minutes) - float(predicted_buffer_minutes)
    if abs(delta) < 1e-6:
        return False

    direction = "increased" if delta > 0 else "reduced"
    subject = f"Alarm Buffer {direction.capitalize()} ({abs(delta):.1f} min)"
    body = (
        f"Your alarm buffer was {direction} due to {reason}.\n\n"
        f"Alarm time:       {set_time}\n"
        f"Predicted buffer: {float(predicted_buffer_minutes):.2f} min\n"
        f"Final buffer:     {float(final_buffer_minutes):.2f} min\n"
        f"Change:           {delta:+.2f} min\n\n"
        "AI Alarm System"
    )
    return send_email(to_email, subject, body)
