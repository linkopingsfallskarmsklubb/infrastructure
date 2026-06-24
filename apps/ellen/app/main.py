import asyncio
import json

from app.auth import get_access_token
from app.config import logger, settings
from app.flatten import flatten
from app.insidan import get_skyview
from app.sheets import build_service, ensure_tab, write_rows


def rows_to_key(rows: list[list]) -> str:
    return json.dumps(rows, sort_keys=True, default=str)


async def export_once(sheets_service, last_key: str | None) -> str | None:
    token = await get_access_token(
        settings.insidan_token_url,
        settings.insidan_client_id,
        settings.insidan_client_secret.get_secret_value(),
    )
    if not token:
        logger.warning("No access token received.")
        return last_key

    skyview = await get_skyview(settings.insidan_api_url, token)
    if not skyview:
        logger.warning("No skyview data received.")
        return last_key

    rows = flatten(skyview)
    key = rows_to_key(rows)

    if key == last_key:
        logger.debug("No changes, skipping sheet update.")
        return last_key

    logger.info("Flattened %d loads, writing to sheet.", len(rows))
    try:
        ensure_tab(
            sheets_service,
            settings.google_spreadsheet_id,
            settings.google_sheet_tab,
        )
        write_rows(
            sheets_service,
            settings.google_spreadsheet_id,
            settings.google_sheet_tab,
            rows,
        )
    except Exception as e:
        logger.error("Google Sheets export failed: %s", e, exc_info=True)
        return last_key

    return key


async def main():
    logger.info("Starting with settings: %s", settings)
    sheets_service = build_service(settings.google_application_credentials)
    last_key: str | None = None

    while True:
        last_key = await export_once(sheets_service, last_key)
        await asyncio.sleep(settings.poll_interval)


if __name__ == "__main__":
    asyncio.run(main())
