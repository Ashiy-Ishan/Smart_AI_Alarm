from __future__ import annotations
import logging
import requests
from config.settings import get_settings

logger = logging.getLogger(__name__)

def fetch_traffic(
    origin_lat: float,
    origin_lng: float,
    dest_lat: float | None = None,
    dest_lng: float | None = None,
) -> dict:
    """Fetch real-time traffic via Google Maps Distance Matrix API.

    Returns a congestion_index on a 0-10 scale:
      0   = no delay vs. free-flow travel time
      10  = 100%+ longer than free-flow
    """
    settings = get_settings()

    if not settings.google_maps_api_key:
        logger.warning("GOOGLE_MAPS_API_KEY not configured — skipping traffic fetch")
        return {"congestion_index": 0.0, "duration_seconds": None, "duration_in_traffic_seconds": None}

    d_lat = dest_lat if dest_lat is not None else settings.default_dest_latitude
    d_lng = dest_lng if dest_lng is not None else settings.default_dest_longitude

    if d_lat == 0.0 and d_lng == 0.0:
        logger.warning("No destination coordinates set — skipping traffic fetch")
        return {"congestion_index": 0.0, "duration_seconds": None, "duration_in_traffic_seconds": None}

    try:
        resp = requests.get(
            settings.google_maps_api_url,
            params={
                "origins": f"{origin_lat},{origin_lng}",
                "destinations": f"{d_lat},{d_lng}",
                "departure_time": "now",
                "traffic_model": "best_guess",
                "key": settings.google_maps_api_key,
            },
            timeout=settings.external_api_timeout_seconds,
        )
        resp.raise_for_status()
        data = resp.json()

        element = data["rows"][0]["elements"][0]
        if element.get("status") != "OK":
            logger.warning("Google Maps element status: %s", element.get("status"))
            return {"congestion_index": 0.0, "duration_seconds": None, "duration_in_traffic_seconds": None}

        normal = element["duration"]["value"]                               # free-flow seconds
        in_traffic = element.get("duration_in_traffic", {}).get("value", normal)  # actual seconds
        # Delay ratio scaled to 0–10 (10 = 100% longer than free-flow)
        congestion = min(max(0.0, (in_traffic - normal) / max(normal, 1) * 10), 10.0)

        return {
            "congestion_index": round(congestion, 3),
            "duration_seconds": normal,
            "duration_in_traffic_seconds": in_traffic,
        }
    except Exception as exc:
        logger.warning("Traffic API failed: %s", exc)
        return {"congestion_index": 0.0, "duration_seconds": None, "duration_in_traffic_seconds": None}
