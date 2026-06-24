from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

from app.config import logger
from app.flatten import COLUMNS

SCOPES = ["https://www.googleapis.com/auth/spreadsheets"]


def build_service(credentials_path: str):
    creds = service_account.Credentials.from_service_account_file(
        credentials_path, scopes=SCOPES
    )
    return build("sheets", "v4", credentials=creds, cache_discovery=False)


def ensure_tab(service, spreadsheet_id: str, tab: str) -> None:
    try:
        metadata = service.spreadsheets().get(
            spreadsheetId=spreadsheet_id, fields="sheets.properties.title"
        ).execute()
        titles = [s["properties"]["title"] for s in metadata.get("sheets", [])]
    except HttpError as e:
        logger.error("Failed to read spreadsheet metadata: %s", e)
        raise

    if tab in titles:
        return

    logger.info("Tab '%s' not found, creating it", tab)
    try:
        service.spreadsheets().batchUpdate(
            spreadsheetId=spreadsheet_id,
            body={"requests": [{"addSheet": {"properties": {"title": tab}}}]},
        ).execute()
    except HttpError as e:
        logger.error("Failed to create tab '%s': %s", tab, e)
        raise


def write_rows(service, spreadsheet_id: str, tab: str, rows: list[list]) -> None:
    values = [COLUMNS, *rows]
    range_name = f"'{tab}'!A1"

    try:
        service.spreadsheets().values().clear(
            spreadsheetId=spreadsheet_id,
            range=f"'{tab}'",
        ).execute()
        service.spreadsheets().values().update(
            spreadsheetId=spreadsheet_id,
            range=range_name,
            valueInputOption="RAW",
            body={"values": values},
        ).execute()
        logger.info("Wrote %d rows to tab '%s'", len(rows), tab)
    except HttpError as e:
        logger.error("Failed to write to Google Sheet: %s", e)
        raise
