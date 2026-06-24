import json
from unittest.mock import AsyncMock, patch

import pytest

import app.auth
import app.insidan
from app.auth import get_access_token
from app.insidan import Skyview, get_skyview


SKYVIEW_PAYLOAD = {
    "jumpDate": "2026-06-23",
    "location": "Bjärred",
    "jumpQueueCount": 1,
    "loads": [
        {
            "loadId": 1,
            "loadNo": 1,
            "loadStatus": 2,
            "loadStatusName": "Open",
            "planeReg": "SE-ABC",
            "maxPass": 14,
            "maxWeight": 1700,
            "children": [
                {
                    "childType": "Jump",
                    "jumpNo": 1,
                    "internalNo": 100,
                    "jumptype": "FS",
                    "jumptypeName": "Formation Skydive",
                    "altitude": 4000,
                    "weight": 80,
                    "member": {"name": "Bob"},
                }
            ],
        }
    ],
}


class DummyResponse:
    def __init__(self, status_code, text):
        self.status_code = status_code
        self.text = text


@pytest.mark.asyncio
async def test_get_skyview_success():
    response = DummyResponse(200, json.dumps(SKYVIEW_PAYLOAD))
    with patch.object(app.insidan.niquests, "aget", AsyncMock(return_value=response)) as mock_aget:
        sv = await get_skyview("https://example.test/api", "token")
        assert sv is not None
        assert isinstance(sv, Skyview)
        assert sv.jump_date == "2026-06-23"
        assert sv.loads[0].load_no == 1
        mock_aget.assert_awaited_once()
        headers = mock_aget.call_args.kwargs["headers"]
        assert headers["Authorization"] == "Bearer token"


@pytest.mark.asyncio
async def test_get_skyview_non_200_returns_none():
    response = DummyResponse(401, "unauthorized")
    with patch.object(app.insidan.niquests, "aget", AsyncMock(return_value=response)):
        sv = await get_skyview("https://example.test/api", "token")
        assert sv is None


TOKEN_PAYLOAD = {
    "access_token": "abc123",
    "token_type": "Bearer",
    "expires_in": 3600,
}


@pytest.mark.asyncio
async def test_get_access_token_success():
    app.auth._cached_token = None
    app.auth._cached_token_expiry = 0
    response = DummyResponse(200, json.dumps(TOKEN_PAYLOAD))
    with patch.object(app.auth.niquests, "apost", AsyncMock(return_value=response)) as mock_apost:
        token = await get_access_token("https://auth.test/token", "client", "secret")
        assert token == "abc123"
        mock_apost.assert_awaited_once()
        data = mock_apost.call_args.kwargs["data"]
        assert data["grant_type"] == "client_credentials"
        assert data["scope"] == "groups"
        auth = mock_apost.call_args.kwargs["auth"]
        assert auth == ("client", "secret")


@pytest.mark.asyncio
async def test_get_access_token_failure_returns_none():
    app.auth._cached_token = None
    app.auth._cached_token_expiry = 0
    response = DummyResponse(401, "unauthorized")
    with patch.object(app.auth.niquests, "apost", AsyncMock(return_value=response)):
        token = await get_access_token("https://auth.test/token", "client", "secret")
        assert token is None
