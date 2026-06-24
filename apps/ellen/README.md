# Ellen

Reads skyview data from the insidan-api `/api/skywin/view` endpoint,
flattens it into one row per load (with aggregated jumper count, total
weight and requested altitudes) and writes the result to a tab in a
Google Sheet. Runs as a long-running service, polling the API on an
interval and only updating the sheet when the data changes.

## Prerequisites

* Python 3.13 or higher
* [uv](astral.sh/docs/getting-started/installation/#install-uv-cli)
* A Google service account with access to the target spreadsheet
* An Authelia OIDC `client_credentials` client (in the `readers` group)
  for authenticating to the insidan-api

## Configuration

Create a `.env` based on the variables below (see `app/config.py`); the app looks for it at `app/.env`:

| Variable | Description |
| --- | --- |
| `INSIDAN_API_URL` | Base URL of the insidan-api (without `/api`). |
| `INSIDAN_TOKEN_URL` | Authelia OIDC token endpoint URL. |
| `INSIDAN_CLIENT_ID` | OIDC client ID for client_credentials flow. |
| `INSIDAN_CLIENT_SECRET` | OIDC client secret. |
| `GOOGLE_SPREADSHEET_ID` | The spreadsheet to write to. |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to a Google service account JSON key. |
| `GOOGLE_SHEET_TAB` | Tab name to write to (default `Skywin`). |
| `POLL_INTERVAL` | Seconds between polls (default `30`). |
| `LOG_LEVEL` | Logging level (default `INFO`). |

## Get started

```bash
cd apps/ellen
uv run python -m app.main
uv run python -m pytest tests
```

The app polls the insidan-api on each interval. Row 1 is the header,
the remaining rows are one load per row. The sheet is only rewritten
when the flattened data has changed since the last poll.
