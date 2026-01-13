from datetime import datetime
from zoneinfo import ZoneInfo

import niquests
from pydantic import BaseModel, field_validator

from app.config import logger


class Wind(BaseModel):
    speed: float
    gust: float
    min: float
    direction: int


class Measurement(BaseModel):
    dateTime: datetime
    dataCount: int
    secondsBack: int
    wind: Wind
    temperature: float
    humidity: float
    pressure: float

    @field_validator("dateTime", mode="before")
    def parse_datetime(cls, value):
        if isinstance(value, str):
            dt = datetime.strptime(value, "%Y-%m-%d %H:%M:%S")
            return dt.replace(tzinfo=ZoneInfo("Europe/Stockholm"))
        return value


class StationData(BaseModel):
    stationId: int
    speedUnit: str
    tempUnit: str
    measurements: list[Measurement]


async def get_station_data(holfuy_password: str):
    r = await niquests.aget(
        f"https://api.holfuy.com/archive/?pw={holfuy_password}&s=761&su=m/s&mback=60"
    )
    if r.status_code != 200 or r.text is None:
        logger.error(f"Failed to fetch Holfuy data: {r.text}")
        return

    return StationData.model_validate_json(r.text)
