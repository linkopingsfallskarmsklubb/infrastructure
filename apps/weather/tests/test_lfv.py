from datetime import datetime

import pytest

import app.lfv
from app.lfv import get_altitude_winds

# Example snippet from Delområde 2 for testing
EXAMPLE_HTML = """
Delområde 2
PROGNOS FÖR OMRÅDE se32 UTFÄRDAD 091234
GÄLLANDE DEN 9 JANUARI 2026 MELLAN 13 OCH 21 UTC

Genomsnittlig vind och temperatur för området

2000ft:
13-15UTC: 80/25kt -6.
15-17UTC: 70/28kt -7.

FL050:
13-15UTC: 80/28kt -12.
15-17UTC: 80/31kt -12.

FL100:
13-15UTC: 90/21kt -18.
15-19UTC: 80/22kt -18.
19-21UTC: 70/24kt -18.
"""


@pytest.mark.asyncio
async def test_fetch_and_parse(monkeypatch):
    class DummyResponse:
        def __init__(self, text):
            self.text = text

        def raise_for_status(self):
            pass

    class DummySession:
        async def __aenter__(self):
            return self

        async def __aexit__(self, exc_type, exc, tb):
            pass

        async def get(self, url):
            return DummyResponse(EXAMPLE_HTML)

    monkeypatch.setattr(app.lfv, "AsyncSession", lambda: DummySession())
    data_points = await get_altitude_winds("dummy_url")
    # Debug print all parsed data points
    for dp in data_points:
        print(dp)
    # Check there is at least 1 point for each flight level
    levels = [2000, 5000, 10000]
    for level in levels:
        assert sum(dp.flight_level == level for dp in data_points) >= 1

    for dp in data_points:
        assert isinstance(dp.flight_level, int)
        assert isinstance(dp.start_time, datetime)
        assert isinstance(dp.interval_hours, int)
        assert isinstance(dp.wind_direction, int)
        assert isinstance(dp.wind_speed, int)
        assert isinstance(dp.temperature, int)
