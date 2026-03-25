from datetime import datetime

from app.utils.errors import ValidationError
from app.utils.validators import require_fields, validate_string


def validate_create_intake_log_payload(data) -> dict:
    if not isinstance(data, dict):
        raise ValidationError("Request body must be a valid JSON object")

    require_fields(data, ["medicine_id"])
    validate_string("medicine_id", data["medicine_id"], min_length=24, max_length=24)

    if "date" in data and data["date"] is not None:
        validate_string("date", data["date"], min_length=10, max_length=10)
        _validate_iso_date(data["date"], field_name="date")
    if "time_taken" in data and data["time_taken"] is not None:
        validate_string("time_taken", data["time_taken"], min_length=10, max_length=35)
    if "taken" in data and not isinstance(data["taken"], bool):
        raise ValidationError("taken must be a boolean")

    return data


def validate_history_filters(
    from_date: str | None,
    to_date: str | None,
    medicine_id: str | None,
) -> tuple[str | None, str | None, str | None]:
    if from_date is not None:
        validate_string("from_date", from_date, min_length=10, max_length=10)
        _validate_iso_date(from_date, field_name="from_date")

    if to_date is not None:
        validate_string("to_date", to_date, min_length=10, max_length=10)
        _validate_iso_date(to_date, field_name="to_date")

    if medicine_id is not None:
        validate_string("medicine_id", medicine_id, min_length=24, max_length=24)

    return from_date, to_date, medicine_id


def _validate_iso_date(value: str, field_name: str) -> None:
    try:
        datetime.strptime(value, "%Y-%m-%d")
    except ValueError as exc:
        raise ValidationError(f"{field_name} must be in YYYY-MM-DD format") from exc
