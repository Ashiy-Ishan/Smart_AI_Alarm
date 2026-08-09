from functools import lru_cache
from dotenv import load_dotenv
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict

load_dotenv()


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = Field(default="AI Alarm System", alias="APP_NAME")
    timezone: str = Field(default="Asia/Colombo", alias="TIMEZONE")

    # MongoDB
    mongo_uri: str = Field(default="mongodb://localhost:27017", alias="MONGO_URI")
    mongo_db_name: str = Field(default="ai_alarm", alias="DB_NAME")

    # Firebase Storage — auto-detected inside Cloud Functions
    # Set FIREBASE_STORAGE_BUCKET for local de
    storage_bucket: str = Field(default="", alias="FIREBASE_STORAGE_BUCKET")

    # Shared HTTP timeout for all external APIs
    external_api_timeout_seconds: int = 5

    # Weather — Open-Meteo (free, no API key required)
    weather_api_url: str = "https://api.open-meteo.com/v1/forecast"

    # Traffic — Google Maps Distance Matrix API
    google_maps_api_key: str = Field(default="", alias="GOOGLE_MAPS_API_KEY")
    google_maps_api_url: str = "https://maps.googleapis.com/maps/api/distancematrix/json"
    default_dest_latitude: float = Field(default=0.0, alias="DEFAULT_DEST_LATITUDE")
    default_dest_longitude: float = Field(default=0.0, alias="DEFAULT_DEST_LONGITUDE")

    # Google Calendar OAuth 2.0
    google_calendar_api_url: str = "https://www.googleapis.com/calendar/v3"
    google_oauth_client_id: str = Field(default="", alias="GOOGLE_OAUTH_CLIENT_ID")
    google_oauth_client_secret: str = Field(default="", alias="GOOGLE_OAUTH_CLIENT_SECRET")
    google_oauth_redirect_uri: str = Field(
        default="http://localhost:8080/calendar/oauth/callback",
        alias="GOOGLE_OAUTH_REDIRECT_URI",
    )
    calendar_busy_threshold_minutes: int = 120
    calendar_prep_minutes: int = 45
    calendar_cache_ttl_minutes: int = 30

    # Email notifications
    email_notifications_enabled: int = Field(default=1, alias="EMAIL_NOTIFICATIONS_ENABLED")
    smtp_host: str = Field(default="", alias="SMTP_HOST")
    smtp_port: int = Field(default=587, alias="SMTP_PORT")
    smtp_username: str = Field(default="", alias="SMTP_USERNAME")
    smtp_password: str = Field(default="", alias="SMTP_PASSWORD")
    smtp_from_email: str = Field(default="", alias="SMTP_FROM_EMAIL")
    smtp_use_tls: int = Field(default=1, alias="SMTP_USE_TLS")

    # ML model
    min_training_points: int = 14
    max_buffer_minutes: int = 120

    # Daily retrain schedule
    retrain_cron_hour: int = 2
    retrain_cron_minute: int = 0

    # IoT sensor defaults (when no ESP32 data is available)
    default_room_temperature: float = 27.0
    default_humidity: float = 65.0
    default_motion_detected: int = 0
    default_light_level: str = "normal"


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
