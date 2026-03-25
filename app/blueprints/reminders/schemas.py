import re

from app.utils.errors import ValidationError
from app.utils.validators import require_fields, validate_list, validate_string


TIME_24H_REGEX = re.compile(r"^([01]\d|2[0-3]):([0-5]\d)$")


def validate_create_reminder_payload(data) -> dict:
    if not isinstance(data, dict):
        raise ValidationError("Request body must be a valid JSON object")

    require_fields(data, ["medicine_id"])
    validate_string("medicine_id", data["medicine_id"], min_length=24, max_length=24)

    has_single_time = "reminder_time" in data
    has_multiple_times = "reminder_times" in data
    if not has_single_time and not has_multiple_times:
        raise ValidationError("Provide either reminder_time or reminder_times")

    if has_single_time:
        _validate_reminder_time(data["reminder_time"])
    if has_multiple_times:
        validate_list("reminder_times", data["reminder_times"])
        if not data["reminder_times"]:
            raise ValidationError("reminder_times cannot be empty")
        for reminder_time in data["reminder_times"]:
            _validate_reminder_time(reminder_time)

    if "repeat_type" in data and data["repeat_type"] is not None:
        validate_string("repeat_type", data["repeat_type"], min_length=3, max_length=20)
    if "is_active" in data and not isinstance(data["is_active"], bool):
        raise ValidationError("is_active must be a boolean")

    return data


def validate_medicine_id_query(medicine_id: str | None) -> str | None:
    if medicine_id is None:
        return None
    validate_string("medicine_id", medicine_id, min_length=24, max_length=24)
    return medicine_id.strip()


def _validate_reminder_time(value: str) -> None:
    validate_string("reminder_time", value, min_length=5, max_length=5)
    if not TIME_24H_REGEX.match(value):
        raise ValidationError("reminder_time must be in HH:MM 24-hour format")
