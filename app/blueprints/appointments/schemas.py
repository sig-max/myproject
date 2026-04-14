from datetime import datetime, timezone

from app.utils.errors import ValidationError
from app.utils.validators import require_fields, validate_string


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

    data["start_at"] = start_at
    data["end_at"] = end_at
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
