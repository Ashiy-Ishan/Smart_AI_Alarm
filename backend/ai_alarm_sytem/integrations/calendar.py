"""Google Calendar integration — OAuth 2.0 flow, token management, event fetching."""
from __future__ import annotations
import logging
import secrets
from datetime import date, datetime, timedelta, timezone

import requests

from config.settings import get_settings
from db.collections import get_collections, CALENDAR_CREDENTIALS, CALENDAR_EVENTS_CACHE

logger = logging.getLogger(__name__)


# OAuth credential storage 

def _get_creds(user_id: str) -> dict | None:
    return get_collections()[CALENDAR_CREDENTIALS].find_one({"user_id": user_id})


def _save_creds(user_id: str, creds: dict) -> None:
    creds["user_id"] = user_id
    creds["updated_at"] = datetime.now(timezone.utc)
    get_collections()[CALENDAR_CREDENTIALS].update_one(
        {"user_id": user_id}, {"$set": creds}, upsert=True
    )


def _is_expired(creds: dict) -> bool:
    raw = creds.get("expires_at")
    if not raw:
        return True
    exp = raw if isinstance(raw, datetime) else datetime.fromisoformat(str(raw))
    if exp.tzinfo is None:
        exp = exp.replace(tzinfo=timezone.utc)
    return datetime.now(timezone.utc) >= exp


def _refresh_token(user_id: str) -> str | None:
    creds = _get_creds(user_id)
    if not creds or not creds.get("refresh_token"):
        logger.warning("No refresh token for user %s", user_id)
        return None
    settings = get_settings()
    try:
        resp = requests.post(
            "https://oauth2.googleapis.com/token",
            data={
                "client_id": settings.google_oauth_client_id,
                "client_secret": settings.google_oauth_client_secret,
                "refresh_token": creds["refresh_token"],
                "grant_type": "refresh_token",
            },
            timeout=settings.external_api_timeout_seconds,
        )
        resp.raise_for_status()
        new = resp.json()
        _save_creds(user_id, {
            "access_token": new["access_token"],
            "expires_at": (
                datetime.now(timezone.utc) + timedelta(seconds=new.get("expires_in", 3600))
            ).isoformat(),
        })
        logger.info("Token refreshed for user %s", user_id)
        return new["access_token"]
    except requests.RequestException as exc:
        logger.error("Token refresh failed for user %s: %s", user_id, exc)
        return None


def get_access_token(user_id: str) -> str | None:
    """Return a valid access token, auto-refreshing if expired."""
    creds = _get_creds(user_id)
    if not creds:
        return None
    if _is_expired(creds):
        return _refresh_token(user_id)
    return creds.get("access_token")


# OAuth 2.0 authorization flow 

def get_authorization_url(user_id: str) -> str:
    """Generate the Google OAuth URL and store a short-lived CSRF state."""
    settings = get_settings()
    state = secrets.token_urlsafe(32)
    expires = (datetime.now(timezone.utc) + timedelta(minutes=10)).isoformat()
    get_collections()[CALENDAR_CREDENTIALS].update_one(
        {"user_id": user_id},
        {"$set": {"oauth_state": state, "oauth_state_expires_at": expires}},
        upsert=True,
    )
    return (
        "https://accounts.google.com/o/oauth2/v2/auth"
        f"?client_id={settings.google_oauth_client_id}"
        "&response_type=code"
        "&scope=https://www.googleapis.com/auth/calendar.readonly"
        f"&redirect_uri={settings.google_oauth_redirect_uri}"
        f"&state={state}"
        "&access_type=offline"
        "&prompt=consent"
    )


def _validate_state(user_id: str, state: str) -> bool:
    creds = _get_creds(user_id)
    if not creds or creds.get("oauth_state") != state:
        return False
    raw = creds.get("oauth_state_expires_at")
    if not raw:
        return False
    exp = datetime.fromisoformat(raw) if isinstance(raw, str) else raw
    if exp.tzinfo is None:
        exp = exp.replace(tzinfo=timezone.utc)
    return datetime.now(timezone.utc) < exp


def handle_oauth_callback(user_id: str, code: str, state: str) -> tuple[bool, str]:
    """Exchange the authorization code for tokens and persist credentials."""
    if not _validate_state(user_id, state):
        return False, "Invalid or expired OAuth state"
    settings = get_settings()
    try:
        resp = requests.post(
            "https://oauth2.googleapis.com/token",
            data={
                "code": code,
                "client_id": settings.google_oauth_client_id,
                "client_secret": settings.google_oauth_client_secret,
                "redirect_uri": settings.google_oauth_redirect_uri,
                "grant_type": "authorization_code",
            },
            timeout=settings.external_api_timeout_seconds,
        )
        resp.raise_for_status()
        tokens = resp.json()
    except requests.RequestException as exc:
        logger.error("Token exchange failed for user %s: %s", user_id, exc)
        return False, "Token exchange failed"

    creds: dict = {
        "access_token": tokens["access_token"],
        "expires_at": (
            datetime.now(timezone.utc) + timedelta(seconds=tokens.get("expires_in", 3600))
        ).isoformat(),
    }
    if rt := tokens.get("refresh_token"):
        creds["refresh_token"] = rt
    _save_creds(user_id, creds)
    logger.info("OAuth credentials saved for user %s", user_id)
    return True, "Calendar connected successfully"


def revoke_access(user_id: str) -> tuple[bool, str]:
    """Revoke Google Calendar access and remove stored credentials."""
    creds = _get_creds(user_id)
    if not creds or not creds.get("access_token"):
        return False, "No calendar access found"
    settings = get_settings()
    try:
        requests.post(
            f"https://oauth2.googleapis.com/revoke?token={creds['access_token']}",
            timeout=settings.external_api_timeout_seconds,
        )
    except Exception as exc:
        logger.warning("Token revocation request failed (credentials will still be removed): %s", exc)
    get_collections()[CALENDAR_CREDENTIALS].delete_one({"user_id": user_id})
    return True, "Calendar access revoked"


def get_integration_status(user_id: str) -> dict:
    creds = _get_creds(user_id)
    if not creds or not creds.get("access_token"):
        return {"connected": False, "token_expired": False, "message": "Calendar not connected"}
    if _is_expired(creds):
        return {"connected": True, "token_expired": True, "message": "Token expired — reconnect"}
    return {
        "connected": True,
        "token_expired": False,
        "updated_at": creds.get("updated_at"),
        "message": "Calendar connected and active",
    }


# Calendar event helpers 

def _to_utc(dt: datetime) -> datetime:
    return dt.replace(tzinfo=timezone.utc) if dt.tzinfo is None else dt.astimezone(timezone.utc)


def _parse_event_time(time_obj: dict) -> datetime | None:
    if dt_str := time_obj.get("dateTime"):
        try:
            return datetime.fromisoformat(dt_str.replace("Z", "+00:00"))
        except ValueError:
            return None
    if date_str := time_obj.get("date"):
        try:
            d = date.fromisoformat(date_str)
            return datetime(d.year, d.month, d.day, tzinfo=timezone.utc)
        except ValueError:
            return None
    return None


def _is_busy_event(event: dict) -> bool:
    return (
        event.get("status") != "cancelled"
        and event.get("transparency") != "transparent"
        and bool(event.get("summary"))
    )


def _build_events(items: list[dict], include_location: bool = False) -> list[dict]:
    out = []
    for event in items:
        if not _is_busy_event(event):
            continue
        start = _parse_event_time(event.get("start", {}))
        end = _parse_event_time(event.get("end", {}))
        if start is None or end is None:
            logger.debug("Skipping event with unparseable time: %s", event.get("id"))
            continue
        entry: dict = {
            "event_id": event.get("id"),
            "summary": event.get("summary", ""),
            "start_time": _to_utc(start),
            "end_time": _to_utc(end),
            "organizer": event.get("organizer", {}).get("email"),
        }
        if include_location:
            entry["location"] = event.get("location", "")
        out.append(entry)
    return out


def _calendar_request(user_id: str, params: dict) -> list[dict]:
    settings = get_settings()
    token = get_access_token(user_id)
    if not token:
        logger.warning("No valid access token for user %s", user_id)
        return []
    url = f"{settings.google_calendar_api_url}/calendars/primary/events"
    try:
        resp = requests.get(
            url,
            headers={"Authorization": f"Bearer {token}"},
            params=params,
            timeout=settings.external_api_timeout_seconds,
        )
        if resp.status_code == 401:
            logger.warning("Calendar API 401 for user %s — token may be invalid", user_id)
            return []
        resp.raise_for_status()
        data = resp.json()
        return data.get("items", []) if isinstance(data, dict) else []
    except requests.RequestException as exc:
        logger.warning("Calendar API request failed: %s", exc)
        return []


# Cache helpers 

def _read_cache(user_id: str) -> list[dict] | None:
    doc = get_collections()[CALENDAR_EVENTS_CACHE].find_one({
        "user_id": user_id,
        "expires_at": {"$gt": datetime.now(timezone.utc)},
    })
    return doc.get("events") if doc else None


def _write_cache(user_id: str, events: list[dict], ttl_minutes: int) -> None:
    expires = datetime.now(timezone.utc) + timedelta(minutes=ttl_minutes)
    get_collections()[CALENDAR_EVENTS_CACHE].update_one(
        {"user_id": user_id},
        {"$set": {"events": events, "cached_at": datetime.now(timezone.utc), "expires_at": expires}},
        upsert=True,
    )


# Public API 

def get_busy_events(user_id: str, reference_time: datetime, window_minutes: int) -> list[dict]:
    """Return busy calendar events in the window, using cache when available."""
    settings = get_settings()
    cached = _read_cache(user_id)
    if cached is not None:
        return cached
    start = _to_utc(reference_time)
    items = _calendar_request(user_id, {
        "timeMin": start.isoformat(),
        "timeMax": (start + timedelta(minutes=window_minutes)).isoformat(),
        "singleEvents": "true",
        "orderBy": "startTime",
        "showDeleted": "false",
    })
    events = _build_events(items)
    _write_cache(user_id, events, settings.calendar_cache_ttl_minutes)
    logger.info("Fetched %d busy events for user %s", len(events), user_id)
    return events


def get_upcoming_events(user_id: str, hours_ahead: int = 24) -> list[dict]:
    """Return upcoming calendar events for a user (includes location field)."""
    start = datetime.now(timezone.utc)
    items = _calendar_request(user_id, {
        "timeMin": start.isoformat(),
        "timeMax": (start + timedelta(hours=hours_ahead)).isoformat(),
        "singleEvents": "true",
        "orderBy": "startTime",
        "maxResults": 10,
    })
    return _build_events(items, include_location=True)


def adjust_buffer_for_calendar(
    user_id: str,
    reference_time: datetime,
    predicted_buffer: float,
) -> tuple[float, dict]:
    """Add prep time to the wake-up buffer when a calendar event is imminent."""
    settings = get_settings()
    try:
        busy = get_busy_events(user_id, reference_time, settings.calendar_busy_threshold_minutes)
    except Exception as exc:
        logger.error("Calendar buffer adjustment error: %s", exc)
        return float(predicted_buffer), {"calendar_adjustment_applied": False, "error": str(exc)}

    if not busy:
        return float(predicted_buffer), {"calendar_adjustment_applied": False}

    next_event = busy[0]
    minutes_until = (_to_utc(next_event["start_time"]) - _to_utc(reference_time)).total_seconds() / 60.0
    if minutes_until < 0:
        return float(predicted_buffer), {"calendar_adjustment_applied": False}

    extra = max(0.0, float(settings.calendar_prep_minutes) - minutes_until)
    return float(predicted_buffer) + extra, {
        "calendar_adjustment_applied": extra > 0,
        "next_event_id": next_event["event_id"],
        "next_event_summary": next_event["summary"],
        "minutes_until_event": round(minutes_until, 2),
        "additional_buffer_minutes": round(extra, 2),
    }


def clear_cache(user_id: str | None = None) -> None:
    col = get_collections()[CALENDAR_EVENTS_CACHE]
    col.delete_many({"user_id": user_id} if user_id else {})
