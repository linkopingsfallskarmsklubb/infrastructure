import asyncpg
import pytz
from app.config import settings, logger


class PgClient:
    def __init__(self):
        self._pool = None

    async def connect(self):
        if not self._pool:
            logger.debug("Connecting to PostgreSQL...")
            self._pool = await asyncpg.create_pool(
                settings.postgres_url.get_secret_value()
            )
            logger.debug("Connected to PostgreSQL.")

    async def close(self):
        if self._pool:
            logger.debug("Closing PostgreSQL connection pool...")
            await self._pool.close()
            self._pool = None
            logger.debug("PostgreSQL connection pool closed.")

    @property
    def pool(self):
        return self._pool

    async def create_holfuy_table(self, table_name="wind_holfuy"):
        async with self._pool.acquire() as conn:
            await conn.execute(f"""
                CREATE TABLE IF NOT EXISTS {table_name} (
                    id SERIAL PRIMARY KEY,
                    station_id INTEGER NOT NULL,
                    datetime TIMESTAMP WITH TIME ZONE NOT NULL,

                    wind_speed REAL NOT NULL,
                    wind_gust REAL NOT NULL,
                    wind_min REAL NOT NULL,
                    wind_direction INTEGER NOT NULL,
                    temperature REAL NOT NULL,
                    humidity REAL NOT NULL,
                    pressure REAL NOT NULL,
                    UNIQUE (station_id, datetime)
                );
            """)

    async def create_lfv_table(self, table_name="wind_lfv"):
        async with self._pool.acquire() as conn:
            await conn.execute(f"""
                CREATE TABLE IF NOT EXISTS {table_name} (
                    id SERIAL PRIMARY KEY,
                    flight_level INTEGER NOT NULL,
                    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
                    interval_hours INTEGER NOT NULL,
                    wind_direction INTEGER,
                    wind_speed INTEGER NOT NULL,
                    temperature INTEGER NOT NULL,
                    UNIQUE (flight_level, start_time)
                );
            """)

    async def drop_table(self, table_name):
        async with self._pool.acquire() as conn:
            await conn.execute(f"DROP TABLE IF EXISTS {table_name};")

    async def insert_holfuy_measurements(
        self, station_id, measurements, table_name="wind_holfuy"
    ):
        # measurements: list of Measurement
        async with self._pool.acquire() as conn:
            try:
                await conn.executemany(
                    f"""
                    INSERT INTO {table_name} (
                        station_id, datetime,
                        wind_speed, wind_gust, wind_min, wind_direction,
                        temperature, humidity, pressure
                    ) VALUES (
                        $1, $2, $3, $4, $5, $6, $7, $8, $9
                    ) ON CONFLICT (station_id, datetime) DO NOTHING
                    """,
                    [
                        (
                            station_id,
                            m.dateTime.astimezone(pytz.timezone("Europe/Stockholm")),
                            m.wind.speed,
                            m.wind.gust,
                            m.wind.min,
                            m.wind.direction,
                            m.temperature,
                            m.humidity,
                            m.pressure,
                        )
                        for m in sorted(measurements, key=lambda m: m.dateTime)
                    ],
                )
            except Exception as e:
                logger.error(f"Error inserting Holfuy measurements: {e}", exc_info=True)

    async def upsert_lfv_data_points(self, data_points, table_name="wind_lfv"):
        # data_points: list of WindDataPoint
        async with self._pool.acquire() as conn:
            try:
                await conn.executemany(
                    f"""
                    INSERT INTO {table_name} (
                        flight_level, start_time, interval_hours,
                        wind_direction, wind_speed, temperature
                    ) VALUES (
                        $1, $2, $3, $4, $5, $6
                    ) ON CONFLICT (flight_level, start_time)
                    DO UPDATE SET
                        interval_hours = EXCLUDED.interval_hours,
                        wind_direction = EXCLUDED.wind_direction,
                        wind_speed = EXCLUDED.wind_speed,
                        temperature = EXCLUDED.temperature
                    """,
                    [
                        (
                            d.flight_level,
                            d.start_time,
                            d.interval_hours,
                            d.wind_direction,
                            d.wind_speed,
                            d.temperature,
                        )
                        for d in data_points
                    ],
                )
            except Exception as e:
                logger.error(f"Error upserting LFV data points: {e}", exc_info=True)
