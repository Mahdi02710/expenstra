import os
from functools import lru_cache

from dotenv import load_dotenv

load_dotenv()


class Settings:
    api_title: str = os.getenv("API_TITLE", "ExpensTra Backend")
    api_version: str = os.getenv("API_VERSION", "1.0.0")
    cors_origins: list[str] = (
        [origin.strip() for origin in os.getenv("CORS_ORIGINS", "*").split(",")]
        if os.getenv("CORS_ORIGINS")
        else ["*"]
    )
    firebase_project_id: str | None = os.getenv("FIREBASE_PROJECT_ID")
    firebase_credentials_path: str | None = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    firebase_credentials_json: str | None = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")
    admin_collection: str = os.getenv("ADMIN_COLLECTION", "users")
    admin_role_field: str = os.getenv("ADMIN_ROLE_FIELD", "role")
    admin_status_field: str = os.getenv("ADMIN_STATUS_FIELD", "status")


@lru_cache
def get_settings() -> Settings:
    return Settings()
