from __future__ import annotations
import logging
import requests
from config.settings import get_settings

logger = logging.getLogger(__name__)

# WMO weather interpretation codes mapped to a severity index (0 = clear, 5 = severe)
_CODE_SEVERITY: list[tuple[range, float]] = [
    (range(0, 1),    0.0),   # Clear sky
    (range(1, 4),    0.5),   # Partly cloudy
    (range(45, 49),  1.5),   # Fog
    (range(51, 68),  2.0),   # Drizzle / light rain
    (range(71, 78),  3.0),   # Snow
    (range(80, 83),  2.5),   # Rain showers
    (range(85, 87),  3.5),   # Snow showers
    (range(95, 100), 5.0),   # Thunderstorm
]

def _code_to_severity(code: int) -> float:
    for r, sev in _CODE_SEVERITY:
        if code in r:
            return sev
    return 1.0

def fetch_weather(latitude: float, longitude: float) -> dict:
    """Fetch current conditions from Open-Meteo (free, no API key required)."""
    settings = get_settings()
    try:
        resp = requests.get(
            settings.weather_api_url,
            params={
                "latitude": latitude,
                "longitude": longitude,
                "current_weather": True,
            },
            timeout=settings.external_api_timeout_seconds,
        )
        resp.raise_for_status()
        current = resp.json().get("current_weather", {})
        code = int(current.get("weathercode", 0))
        return {
            "weathercode": code,
            "temperature": current.get("temperature"),
            "windspeed": current.get("windspeed"),
            "severity": _code_to_severity(code),
        }
    except Exception as exc:
        logger.warning("Weather API failed: %s", exc)
        return {"weathercode": 0, "temperature": None, "windspeed": None, "severity": 0.0}
