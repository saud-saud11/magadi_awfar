import os
from pydantic import BaseModel

class Settings(BaseModel):
    APP_NAME: str = "مقاضي أوفر - Magadi Awfar"
    API_V1_STR: str = "/api/v1"
    SECRET_KEY: str = os.getenv("SECRET_KEY", "")
    DEFAULT_CITY: str = "المدينة المنورة"
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./magadi_awfar.db")
    
    ADMIN_TOKEN: str = os.getenv('ADMIN_TOKEN', '')
    VAPID_PUBLIC_KEY: str = os.getenv('VAPID_PUBLIC_KEY', '')
    VAPID_PRIVATE_KEY: str = os.getenv('VAPID_PRIVATE_KEY', '')
    VAPID_SUBJECT: str = os.getenv('VAPID_SUBJECT', '')
    PUBLIC_APP_URL: str = os.getenv('PUBLIC_APP_URL', 'https://saud-saud11.github.io/magadi_awfar/')
    CORS_ORIGINS: str = os.getenv('CORS_ORIGINS', 'https://saud-saud11.github.io,http://localhost:8080')

    # Cache and Stale Thresholds
    ACTIVE_CACHE_MINUTES: int = 30
    STALE_THRESHOLD_HOURS: int = 24  # Exclude from active ranking if older than 24 hours
    
    # Store settings
    DEFAULT_UPDATE_INTERVAL_MINUTES: int = 60
    
    # AI and Voice Service Configuration
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
    STT_SERVICE_PROVIDER: str = os.getenv("STT_SERVICE_PROVIDER", "google_speech")

settings = Settings()

