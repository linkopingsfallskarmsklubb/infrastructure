from datetime import datetime

import pytest
import pytest_asyncio
import pytz

from app.config import settings
from app.holfuy import Measurement, Wind
from app.lfv import WindDataPoint
from app.pgsql import PgClient

db = PgClient()


@pytest_asyncio.fixture
async def db_pool():
    await db.connect()
    yield
    await db.close()


@pytest.mark.asyncio
async def test_insert_holfuy_measurements(db_pool):
    test_table = "test_wind_holfuy"
    await db.create_holfuy_table(test_table)

    # Ensure holfuy_api_key is SecretStr and can be used as a string
    api_key = settings.holfuy_api_key.get_secret_value()
    assert isinstance(api_key, str)

    station_id = 999
    cet = pytz.timezone("Europe/Stockholm")
    measurement = Measurement(
        dateTime=cet.localize(datetime(2024, 1, 1, 12, 0, 0)),
        dataCount=1,
        secondsBack=10,
        wind=Wind(speed=1.1, gust=2.2, min=0.9, direction=180),
        temperature=20.5,
        humidity=50.0,
        pressure=1013.2,
    )

    # Insert once
    await db.insert_holfuy_measurements(
        station_id, [measurement], table_name=test_table
    )
    # Insert again (should not duplicate)
    await db.insert_holfuy_measurements(
        station_id, [measurement], table_name=test_table
    )
    async with db.pool.acquire() as conn:
        rows = await conn.fetch(
            f"SELECT COUNT(*) FROM {test_table} WHERE station_id=$1 AND datetime=$2",
            station_id,
            measurement.dateTime,
        )
        assert rows[0][0] == 1
    await db.drop_table(test_table)


@pytest.mark.asyncio
async def test_upsert_lfv_data_points(db_pool):
    test_table = "test_wind_lfv"
    await db.create_lfv_table(test_table)

    cet = pytz.timezone("Europe/Stockholm")

    data_point = WindDataPoint(
        flight_level=1234,
        start_time=cet.localize(datetime(2024, 1, 1, 10, 0, 0)),
        interval_hours=2,
        wind_direction=90,
        wind_speed=15,
        temperature=5,
    )

    # Insert
    await db.upsert_lfv_data_points([data_point], table_name=test_table)

    # Update
    updated = data_point.model_copy(update={"wind_speed": 20, "temperature": 7})
    await db.upsert_lfv_data_points([updated], table_name=test_table)
    async with db.pool.acquire() as conn:
        row = await conn.fetchrow(
            f"SELECT wind_speed, temperature FROM {test_table} WHERE flight_level=$1 AND start_time=$2",
            data_point.flight_level,
            data_point.start_time,
        )

        assert row["wind_speed"] == 20
        assert row["temperature"] == 7
    await db.drop_table(test_table)
