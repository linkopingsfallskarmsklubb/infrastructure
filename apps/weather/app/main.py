import asyncio

from app.config import logger, settings
from app.holfuy import get_station_data
from app.lfv import get_altitude_winds
from app.pgsql import PgClient


async def fetch_and_save_holfuy_data(db: PgClient):
    logger.debug("Fetching Holfuy data...")
    holfuy = None
    try:
        holfuy = await get_station_data(settings.holfuy_api_key.get_secret_value())
    except Exception as e:
        logger.error(f"Error fetching Holfuy data: {e}", exc_info=True)

    if not holfuy:
        logger.warning("No Holfuy data received.")
        return

    logger.info(
        f"Saving {len(holfuy.measurements)} Holfuy data points for station {holfuy.stationId}"
    )
    try:
        await db.insert_holfuy_measurements(holfuy.stationId, holfuy.measurements)
    except Exception as e:
        logger.error(f"Error saving Holfuy data: {e}", exc_info=True)


async def fetch_and_save_lfv_data(db: PgClient):
    logger.debug("Fetching LFV wind data...")
    lfv_points = None
    try:
        lfv_points = await get_altitude_winds(settings.lfv_url)
    except Exception as e:
        logger.error(f"Error fetching LFV wind data: {e}", exc_info=True)

    if not lfv_points:
        logger.warning("No LFV wind data received.")
        return

    logger.info(f"Saving {len(lfv_points)} LFV wind data points.")
    try:
        await db.upsert_lfv_data_points(lfv_points)
    except Exception as e:
        logger.error(f"Error saving LFV wind data: {e}", exc_info=True)


async def main():
    logger.debug("Connecting to database...")
    try:
        db = PgClient()
        await db.connect()
        await db.create_holfuy_table()
        await db.create_lfv_table()
    except Exception as e:
        logger.error(f"Database setup failed: {e}", exc_info=True)
        return

    await asyncio.gather(fetch_and_save_holfuy_data(db), fetch_and_save_lfv_data(db))

    try:
        await db.close()
    except Exception as e:
        logger.error(f"Error closing database: {e}", exc_info=True)


if __name__ == "__main__":
    logger.info(f"Starting with settings: {settings}")
    asyncio.run(main())
