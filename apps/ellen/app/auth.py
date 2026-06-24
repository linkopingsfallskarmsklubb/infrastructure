import time

import niquests
from pydantic import BaseModel

from app.config import logger


class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    expires_in: int | None = None


_cached_token: str | None = None
_cached_token_expiry: float = 0


async def get_access_token(
    token_url: str, client_id: str, client_secret: str
) -> str | None:
    global _cached_token, _cached_token_expiry

    now = time.monotonic()
    if _cached_token and now < _cached_token_expiry:
        return _cached_token

    logger.debug("Requesting access token from %s for client %s", token_url, client_id)
    r = await niquests.apost(
        token_url,
        auth=(client_id, client_secret),
        data={
            "grant_type": "client_credentials",
            "scope": "groups",
        },
        headers={"Accept": "application/json"},
        timeout=30,
    )
    if r.status_code != 200:
        logger.error("Failed to get access token (%s): %s", r.status_code, r.text)
        return None

    token = TokenResponse.model_validate_json(r.text)
    expires_in = token.expires_in or 3600
    _cached_token = token.access_token
    _cached_token_expiry = now + expires_in - 60
    logger.debug("Got access token (expires_in=%s)", expires_in)
    return _cached_token
