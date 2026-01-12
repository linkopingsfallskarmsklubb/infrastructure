# Weather tools

Weather tools is a collection of tools and services to collect and
process weather data for use by other applications.

## Prerequisites

* Python 3.13 or higher
* [uv](astral.sh/docs/getting-started/installation/#install-uv-cli)
* PostgreSQL
* Create .env based on config.py and set the required environment variables.

## Get started

```python
cd apps/tools/weather
uv run python -m app.main
uv run python -m pytest tests
```
