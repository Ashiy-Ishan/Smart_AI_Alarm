from __future__ import annotations
import logging
from datetime import datetime, timezone
from io import BytesIO
import firebase_admin
import flask
from firebase_functions import https_fn, scheduler_fn
from firebase_functions.options import MemoryOption

from config.settings import get_settings

# Firebase initialization
_settings = get_settings()
_firebase_opts: dict = {}
if _settings.storage_bucket:
    _firebase_opts["storageBucket"] = _settings.storage_bucket
    if not firebase_admin._apps:
        firebase_admin.initialize_app(options=_firebase_opts or None)

#from db.collections import ensure_indexes
#ensure_indexes()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s: %(message)s",
)
logger = logging.getLogger(__name__)

# Internal Flask app

_app = flask.Flask(__name__)


def _parse_dt(value) -> datetime | None:
    """Parse an ISO datetime string or pass through a datetime object."""
    if value is None:
        return None
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    try:
        dt = datetime.fromisoformat(str(value).replace("Z", "+00:00"))
        return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)
    except (ValueError, AttributeError):
        return None


def _jsonify(data) -> flask.Response:
    """flask.jsonify that serializes datetime objects as ISO strings."""
    def _conv(obj):
        if isinstance(obj, datetime):
            return obj.isoformat()
        if isinstance(obj, dict):
            return {k: _conv(v) for k, v in obj.items()}
        if isinstance(obj, list):
            return [_conv(i) for i in obj]
        return obj
    return flask.jsonify(_conv(data))


# Health check route 

@_app.get("/health")
def health():
    return flask.jsonify({"status": "ok"})


# Alarm routes

@_app.post("/alarms")
def create_alarm_route():
    from core.alarm import create_alarm

    body = flask.request.get_json(force=True) or {}
    set_time = _parse_dt(body.get("set_time"))
    if not body.get("user_id") or set_time is None:
        return flask.jsonify({"error": "user_id and set_time are required"}), 422
    try:
        alarm = create_alarm(
            user_id=body["user_id"],
            set_time=set_time,
            alarm_type=body.get("alarm_type", "custom"),
            is_active=bool(body.get("is_active", True)),
            latitude=float(body.get("latitude", 0.0)),
            longitude=float(body.get("longitude", 0.0)),
            dest_latitude=body.get("dest_latitude"),
            dest_longitude=body.get("dest_longitude"),
            is_holiday=int(body.get("is_holiday", 0)),
        )
        return _jsonify(alarm), 201
    except Exception as exc:
        logger.exception("create_alarm failed")
        return flask.jsonify({"error": str(exc)}), 500


@_app.post("/alarms/outcome")
def alarm_outcome_route():
    from core.alarm import log_alarm_outcome

    body = flask.request.get_json(force=True) or {}
    trigger_time = _parse_dt(body.get("trigger_time"))
    if not (body.get("user_id") and body.get("alarm_id") and trigger_time):
        return flask.jsonify({"error": "user_id, alarm_id, and trigger_time are required"}), 422
    try:
        raw_actual_buffer = body.get(
            "actual_buffer_minutes"
        )

        actual_buffer = (
            float(raw_actual_buffer)
            if raw_actual_buffer is not None
            else None
        )
        log_id = log_alarm_outcome(
            user_id=body["user_id"],
            alarm_id=body["alarm_id"],
            trigger_time=trigger_time,
            weather_severity=float(body.get("weather_severity", 0.0)),
            traffic_condition=float(body.get("traffic_condition", 0.0)),
            room_temp=float(body.get("room_temp", 27.0)),
            snooze_count=int(body.get("snooze_count", 0)),
            unlock_delay=float(body.get("unlock_delay", 0.0)),
            success=int(body.get("success", 1)),
            alarm_type=body.get("alarm_type", "custom"),
            is_holiday=int(body.get("is_holiday", 0)),
            buffer_minutes=float(body.get("buffer_minutes", 0.0)),
            actual_buffer_minutes=actual_buffer,
        )
        return flask.jsonify({"success": True, "log_id": log_id}), 201
    except ValueError as exc:
        return flask.jsonify(
            {
                "error": str(exc),
            }
        ), 422

    except Exception as exc:
        logger.exception(
            "alarm_outcome failed"
        )

        return flask.jsonify(
            {
                "error": str(exc),
            }
        ), 500


@_app.post("/alarms/<user_id>/retrain")
def retrain_route(user_id: str):
    from core.model import train_model

    try:
        return _jsonify(train_model(user_id))
    except Exception as exc:
        return flask.jsonify({"error": str(exc)}), 500

@_app.get("/alarms/<user_id>/accuracy")
def accuracy_route(user_id: str):
    from core.model import get_model_metadata

    try:
        metadata = get_model_metadata(user_id)

        if metadata is None:
            return _jsonify({
                "trained": False,
                "user_id": user_id,
                "sample_count": 0,
                "message": "No model has been trained yet.",
                "trained_at": None,
            })

        return _jsonify(metadata)

    except Exception as exc:
        logger.exception(
            "Failed to get accuracy for user %s",
            user_id,
        )

        return flask.jsonify({
            "error": str(exc)
        }), 500


# Calendar routes

@_app.get("/calendar/oauth/start")
def calendar_oauth_start():
    from integrations.calendar import get_authorization_url

    user_id = flask.request.args.get("user_id")
    if not user_id:
        return flask.jsonify({"error": "user_id required"}), 422
    try:
        return flask.jsonify({"login_url": get_authorization_url(user_id)})
    except Exception as exc:
        return flask.jsonify({"error": str(exc)}), 500


@_app.get("/calendar/oauth/callback")
def calendar_oauth_callback():
    from integrations.calendar import handle_oauth_callback
    user_id = flask.request.args.get("user_id")
    code = flask.request.args.get("code")
    state = flask.request.args.get("state")
    if not (user_id and code and state):
        return flask.jsonify({"error": "user_id, code, and state are required"}), 422
    success, message = handle_oauth_callback(user_id, code, state)
    if not success:
        return flask.jsonify({"error": message}), 400
    return flask.jsonify({"success": True, "message": message})


@_app.get("/calendar/status/<user_id>")
def calendar_status(user_id: str):
    from integrations.calendar import get_integration_status
    return _jsonify(get_integration_status(user_id))


@_app.get("/calendar/events/<user_id>")
def calendar_events(user_id: str):
    from integrations.calendar import get_upcoming_events

    try:
        hours_ahead = min(max(int(flask.request.args.get("hours_ahead", 24)), 1), 168)
        events = get_upcoming_events(user_id, hours_ahead=hours_ahead)
        return _jsonify({"count": len(events), "events": events})
    except Exception as exc:
        logger.error("Error fetching calendar events for user %s: %s", user_id, exc)
        return _jsonify({"count": 0, "events": []})



@_app.delete("/calendar/access/<user_id>")
def calendar_revoke(user_id: str):
    from integrations.calendar import revoke_access

    success, message = revoke_access(user_id)
    if not success:
        return flask.jsonify({"error": message}), 400
    return flask.jsonify({"success": True, "message": message})


@_app.delete("/calendar/cache/<user_id>")
def calendar_cache_user(user_id: str):
    from integrations.calendar import clear_cache
    
    clear_cache(user_id)
    return flask.jsonify({"success": True})


@_app.delete("/calendar/cache")
def calendar_cache_all():
    from integrations.calendar import clear_cache
    clear_cache()
    return flask.jsonify({"success": True})


# IoT sensor routes

@_app.post("/iot/sensor")
def iot_sensor():
    from integrations.iot import store_sensor_reading
    body = flask.request.get_json(force=True) or {}
    user_id = body.pop("user_id", None)
    if not user_id:
        return flask.jsonify({"error": "user_id is required"}), 422
    try:
        return _jsonify(store_sensor_reading(user_id, body)), 201
    except ValueError as exc:
        return flask.jsonify({"error": str(exc)}), 422
    except Exception as exc:
        return flask.jsonify({"error": str(exc)}), 500


@_app.get("/iot/sensor/<user_id>/latest")
def iot_latest(user_id: str):
    from integrations.iot import get_latest_reading
    return _jsonify(get_latest_reading(user_id))


# Firebase Cloud Functions 

@https_fn.on_request(memory=MemoryOption.MB_512)
def api(req: https_fn.Request) -> https_fn.Response:
    """
    Single HTTP entry point — all routes handled internally by Flask.

    Cache the original Firebase request body and give the internal
    Flask app its own copy of the request stream.
    """

    # Read and cache the original request body.
    body = req.get_data(cache=True)

    # Copy the request environment.
    environ = req.environ.copy()

    # Give the nested Flask app its own readable request body.
    environ["wsgi.input"] = BytesIO(body)
    environ["CONTENT_LENGTH"] = str(len(body))

    with _app.request_context(environ):
        return _app.full_dispatch_request()


@scheduler_fn.on_schedule(
    schedule="0 2 * * *",
    timezone=scheduler_fn.Timezone("Asia/Colombo"),
    memory=MemoryOption.GB_1,
)
def daily_retrain(event: scheduler_fn.ScheduledEvent) -> None:
    """Retrain all user models daily at 02:00."""
    from core.model import retrain_all
    results = retrain_all()
    trained = sum(1 for r in results if r.get("trained"))
    logger.info("Daily retrain complete: %d/%d users trained", trained, len(results))

# Insight routes

@_app.get("/insights/<user_id>")
def user_insights_route(user_id: str):
    from core.insights import get_user_insights

    try:
        days = int(
            flask.request.args.get(
                "days",
                7,
            )
        )

        return _jsonify(
            get_user_insights(
                user_id=user_id,
                days=days,
            )
        )

    except Exception as exc:
        logger.exception(
            "Failed to load insights "
            "for user %s",
            user_id,
        )

        return flask.jsonify(
            {
                "error": str(exc),
            }
        ), 500


@_app.get("/insights/<user_id>/habit")
def habit_insights_route(user_id: str):
    from core.insights import get_habit_insights

    try:
        days = int(
            flask.request.args.get(
                "days",
                7,
            )
        )

        return _jsonify(
            get_habit_insights(
                user_id,
                days,
            )
        )

    except Exception as exc:
        logger.exception(
            "Failed to load habit insights"
        )

        return flask.jsonify(
            {
                "error": str(exc),
            }
        ), 500


@_app.get("/insights/<user_id>/sleep")
def sleep_insights_route(user_id: str):
    from core.insights import get_sleep_insights

    try:
        days = int(
            flask.request.args.get(
                "days",
                7,
            )
        )

        return _jsonify(
            get_sleep_insights(
                user_id,
                days,
            )
        )

    except Exception as exc:
        logger.exception(
            "Failed to load sleep insights"
        )

        return flask.jsonify(
            {
                "error": str(exc),
            }
        ), 500

@_app.post("/sleep/session")
def create_sleep_session_route():
    from core.insights import create_sleep_session

    body = (
        flask.request.get_json(
            force=True
        )
        or {}
    )

    user_id = body.get(
        "user_id"
    )

    sleep_start = _parse_dt(
        body.get(
            "sleep_start"
        )
    )

    sleep_end = _parse_dt(
        body.get(
            "sleep_end"
        )
    )

    if not user_id:
        return flask.jsonify(
            {
                "error": (
                    "user_id is required"
                ),
            }
        ), 422

    if (
        sleep_start is None
        or sleep_end is None
    ):
        return flask.jsonify(
            {
                "error": (
                    "sleep_start and "
                    "sleep_end are required"
                ),
            }
        ), 422

    try:
        result = create_sleep_session(
            user_id=user_id,
            sleep_start=sleep_start,
            sleep_end=sleep_end,
            awakenings=int(
                body.get(
                    "awakenings",
                    0,
                )
            ),
            motion_events=int(
                body.get(
                    "motion_events",
                    0,
                )
            ),
            source=str(
                body.get(
                    "source",
                    "mobile",
                )
            ),
        )

        return _jsonify(
            result
        ), 201

    except ValueError as exc:
        return flask.jsonify(
            {
                "error": str(exc),
            }
        ), 422

    except Exception as exc:
        logger.exception(
            "Failed to save sleep session"
        )

        return flask.jsonify(
            {
                "error": str(exc),
            }
        ), 500

# ============================================================
# TODAY SUMMARY ROUTE
# ============================================================


@_app.get("/summary/<user_id>/today")
def today_summary_route(
    user_id: str,
):
    from core.today_summary import (
        get_today_summary,
    )

    try:
        summary = get_today_summary(
            user_id
        )

        return _jsonify(
            summary
        )

    except ValueError as exc:
        return flask.jsonify(
            {
                "error": str(exc),
            }
        ), 422

    except Exception as exc:
        logger.exception(
            "Failed to load today's summary "
            "for user %s",
            user_id,
        )

        return flask.jsonify(
            {
                "error": str(exc),
            }
        ), 500