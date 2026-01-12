import logging
import os
import sys

from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    holfuy_api_key: SecretStr
    lfv_url: str
    postgres_url: SecretStr
    log_level: str = "INFO"

    model_config = SettingsConfigDict(
        env_file=os.path.join(os.path.dirname(__file__), ".env"), case_sensitive=False
    )


settings = Settings()

LOG_FORMAT = "%(asctime)s %(levelname)s [%(name)s] %(message)s"
logging.basicConfig(
    level=getattr(logging, settings.log_level.upper(), logging.INFO),
    format=LOG_FORMAT,
    stream=sys.stdout,
)

logger = logging.getLogger("weather_app")
