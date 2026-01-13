from app.holfuy import Measurement


def test_measurement_datetime_timezone():
    data = {
        "dateTime": "2024-01-13 15:30:00",
        "dataCount": 1,
        "secondsBack": 0,
        "wind": {"speed": 1.0, "gust": 2.0, "min": 0.5, "direction": 90},
        "temperature": 20.0,
        "humidity": 50.0,
        "pressure": 1013.0,
    }
    m = Measurement(**data)
    assert m.dateTime.tzinfo is not None, "dateTime should be timezone-aware"
    assert m.dateTime.tzinfo.key == "Europe/Stockholm", (
        f"Expected Europe/Berlin, got {m.dateTime.tzinfo}"
    )

