import logging
import os
import sys

from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    insidan_api_url: str
    insidan_token_url: str
    insidan_client_id: str
    insidan_client_secret: SecretStr
    google_spreadsheet_id: str
    google_application_credentials: str
    google_sheet_tab: str = "Skywin"
    poll_interval: int = 30
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

logger = logging.getLogger("ellen")
