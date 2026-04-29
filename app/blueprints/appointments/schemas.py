from datetime import datetime, timezone

from app.utils.errors import ValidationError
from app.utils.validators import require_fields, validate_string


ALLOWED_WEEKDAYS = {0, 1, 2, 3, 4, 5, 6}


def validate_create_slot_payload(data: dict) -> dict:
    if not isinstance(data, dict):
        raise ValidationError("Request body must be a valid JSON object")

    require_fields(data, ["start_at", "end_at"])
    start_at = _parse_iso_datetime("start_at", data["start_at"])
    end_at = _parse_iso_datetime("end_at", data["end_at"])
    if start_at <= datetime.now(timezone.utc):
        raise ValidationError("start_at must be in the future")
    if end_at <= start_at:
        raise ValidationError("end_at must be after start_at")

    repeat_weekdays = data.get("repeat_weekdays")
    if repeat_weekdays is None:
        repeat_weekdays = []
    if not isinstance(repeat_weekdays, list):
        raise ValidationError("repeat_weekdays must be a list")

    normalized_weekdays = []
    for weekday in repeat_weekdays:
        if not isinstance(weekday, int) or weekday not in ALLOWED_WEEKDAYS:
            raise ValidationError("repeat_weekdays must contain weekday numbers from 0 to 6")
        if weekday not in normalized_weekdays:
            normalized_weekdays.append(weekday)

    repeat_weeks = data.get("repeat_weeks", 1)
    if not isinstance(repeat_weeks, int):
        raise ValidationError("repeat_weeks must be an integer")
    if repeat_weeks < 1 or repeat_weeks > 12:
        raise ValidationError("repeat_weeks must be between 1 and 12")

    data["start_at"] = start_at
    data["end_at"] = end_at
    data["repeat_weekdays"] = normalized_weekdays
    data["repeat_weeks"] = repeat_weeks
    return data


def validate_create_booking_payload(data: dict) -> dict:
    if not isinstance(data, dict):
        raise ValidationError("Request body must be a valid JSON object")

    require_fields(data, ["slot_id"])
    validate_string("slot_id", data["slot_id"], min_length=24, max_length=24)
    notes = data.get("notes", "")
    if notes is not None:
        if not isinstance(notes, str):
            raise ValidationError("notes must be a string")
        if len(notes.strip()) > 500:
            raise ValidationError("notes cannot exceed 500 characters")
    return data


def validate_accept_appointment_payload(data: dict) -> dict:
    if data is None:
        return {}
    if not isinstance(data, dict):
        raise ValidationError("Request body must be a valid JSON object")
    return data


def _parse_iso_datetime(field_name: str, value: str) -> datetime:
    if not isinstance(value, str):
        raise ValidationError(f"{field_name} must be a string")
    try:
        normalized = value.replace("Z", "+00:00")
        parsed = datetime.fromisoformat(normalized)
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=timezone.utc)
        return parsed.astimezone(timezone.utc)
    except ValueError as exc:
        raise ValidationError(f"{field_name} must be a valid ISO datetime") from exc
