import re
from datetime import datetime
from typing import List, Optional

import pytz
from bs4 import BeautifulSoup
from niquests import AsyncSession
from pydantic import BaseModel

from app.config import logger


class WindDataPoint(BaseModel):
    flight_level: int  # feet
    start_time: datetime  # UTC datetime when interval starts
    interval_hours: int
    wind_direction: Optional[int]  # degrees, None if 'Vrb'
    wind_speed: int  # knots
    temperature: int  # Celsius


async def get_altitude_winds(url: str) -> List[WindDataPoint]:
    async with AsyncSession() as session:
        resp = await session.get(url)
        resp.raise_for_status()
        soup = BeautifulSoup(resp.text, "html.parser")
        text = soup.get_text("\n", strip=True)

        # Find the Delområde 2 section
        area_start = text.find("Delområde 2")
        if area_start == -1:
            logger.error("Delområde 2 not found in LFV data")
            raise ValueError("Delområde 2 not found")
        area_text = text[area_start:]
        # End at next Delområde or Delområde 3/4 or end of string
        for delim in ["Delområde 3", "Delområde 4", "Prel prognos"]:
            delim_pos = area_text.find(delim)
            if delim_pos != -1:
                area_text = area_text[:delim_pos]
                break

        # Find the wind/temperature block
        block_start = area_text.find("Genomsnittlig vind och temperatur för området")
        if block_start == -1:
            logger.error("Wind/temperature block not found in LFV data")
            raise ValueError("Wind/temperature block not found")
        block_text = area_text[block_start:]

        # Find the date
        date_match = re.search(r"GÄLLANDE DEN (\d{1,2} \w+ \d{4})", area_text)
        if not date_match:
            logger.error("Date not found in LFV data")
            raise ValueError("Date not found")
        date_str = date_match.group(1)
        # Handle Swedish month names
        month_map = {
            "JANUARI": "JANUARY",
            "FEBRUARI": "FEBRUARY",
            "MARS": "MARCH",
            "APRIL": "APRIL",
            "MAJ": "MAY",
            "JUNI": "JUNE",
            "JULI": "JULY",
            "AUGUSTI": "AUGUST",
            "SEPTEMBER": "SEPTEMBER",
            "OKTOBER": "OCTOBER",
            "NOVEMBER": "NOVEMBER",
            "DECEMBER": "DECEMBER",
        }
        for swe, eng in month_map.items():
            date_str = date_str.replace(swe, eng.upper())

        prognos_date = datetime.strptime(date_str, "%d %B %Y").date()

        # Parse flight levels and their data
        flight_levels = ["2000ft", "FL050", "FL100"]
        data_points = []
        lines = block_text.splitlines()
        cet = pytz.timezone("Europe/Stockholm")
        # Find indices for each flight level
        level_indices = []
        for i, line in enumerate(lines):
            if line.strip().rstrip(":") in flight_levels:
                level_indices.append((line.strip().rstrip(":"), i))
        level_indices.append((None, len(lines)))  # Sentinel for last block
        for idx in range(len(level_indices) - 1):
            fl_name, start_idx = level_indices[idx]
            _, end_idx = level_indices[idx + 1]
            fl_lines = lines[start_idx + 1 : end_idx]
            if fl_name.startswith("FL"):
                flight_level = int(fl_name[2:]) * 100
            else:
                flight_level = int(fl_name.replace("ft", ""))
            for line in fl_lines:
                line = line.strip()
                m = re.match(
                    r"([0-9]{2})-([0-9]{2})UTC:\s*(Vrb|[0-9]+)/([0-9]+)kt\s*([+-]?[0-9]+)\.?",
                    line,
                )
                if m:
                    start_hour = int(m.group(1))
                    end_hour = int(m.group(2))
                    interval_hours = end_hour - start_hour
                    wind_dir_raw = m.group(3)
                    wind_dir = None if wind_dir_raw == "Vrb" else int(wind_dir_raw)
                    wind_speed = int(m.group(4))
                    temp = int(m.group(5))
                    start_dt = cet.localize(
                        datetime.combine(prognos_date, datetime.min.time())
                    )
                    start_datetime = start_dt.replace(hour=start_hour)
                    data_points.append(
                        WindDataPoint(
                            flight_level=flight_level,
                            start_time=start_datetime,
                            interval_hours=interval_hours,
                            wind_direction=wind_dir,
                            wind_speed=wind_speed,
                            temperature=temp,
                        )
                    )
        return data_points
