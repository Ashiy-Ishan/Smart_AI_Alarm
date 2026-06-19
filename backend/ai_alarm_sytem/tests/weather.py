from unittest.mock import MagicMock, patch

from integrations.weather import _code_to_severity, fetch_weather

class TestCodeToSeverity:
    def test_clear_sky(self):
        assert _code_to_severity(0) == 0.0

    def test_partly_cloudy(self):
        assert _code_to_severity(1) == 0.5
        assert _code_to_severity(3) == 0.5

    def test_fog(self):
        assert _code_to_severity(45) == 1.5

    def test_drizzle(self):
        assert _code_to_severity(51) == 2.0
        assert _code_to_severity(67) == 2.0

    def test_snow(self):
        assert _code_to_severity(71) == 3.0

    def test_rain_showers(self):
        assert _code_to_severity(80) == 2.5

    def test_snow_showers(self):
        assert _code_to_severity(85) == 3.5

    def test_thunderstorm(self):
        assert _code_to_severity(95) == 5.0
        assert _code_to_severity(99) == 5.0

    def test_unknown_code_returns_default(self):
        assert _code_to_severity(200) == 1.0
        assert _code_to_severity(-1) == 1.0

class TestFetchWeather:
    def _mock_response(self, weathercode: int, temperature: float, windspeed: float) -> MagicMock:
        resp = MagicMock()
        resp.json.return_value = {
            "current_weather": {
                "weathercode": weathercode,
                "temperature": temperature,
                "windspeed": windspeed,
            }
        }
        resp.raise_for_status.return_value = None
        return resp

    def test_clear_weather(self):
        with patch("integrations.weather.requests.get", return_value=self._mock_response(0, 30.0, 5.0)):
            result = fetch_weather(6.9, 79.8)
        assert result["weathercode"] == 0
        assert result["severity"] == 0.0
        assert result["temperature"] == 30.0
        assert result["windspeed"] == 5.0

    def test_thunderstorm(self):
        with patch("integrations.weather.requests.get", return_value=self._mock_response(95, 28.0, 40.0)):
            result = fetch_weather(6.9, 79.8)
        assert result["severity"] == 5.0

    def test_api_failure_returns_safe_defaults(self):
        with patch("integrations.weather.requests.get", side_effect=Exception("timeout")):
            result = fetch_weather(0.0, 0.0)
        assert result["severity"] == 0.0
        assert result["weathercode"] == 0
        assert result["temperature"] is None
        assert result["windspeed"] is None

    def test_missing_current_weather_key(self):
        resp = MagicMock()
        resp.json.return_value = {}
        resp.raise_for_status.return_value = None
        with patch("integrations.weather.requests.get", return_value=resp):
            result = fetch_weather(0.0, 0.0)
        assert result["severity"] == 0.0  # weathercode defaults to 0
