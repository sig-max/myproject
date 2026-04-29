from datetime import date

from app.utils.errors import ValidationError
from app.utils.validators import require_fields, validate_phone, validate_string


ALLOWED_REQUEST_STATUSES = {"pending", "accepted", "completed", "cancelled"}


def validate_create_home_sample_request_payload(data: dict) -> dict:
    if not isinstance(data, dict):
        raise ValidationError("Request body must be a valid JSON object")

    require_fields(
        data,
        [
            "test_name",
            "preferred_date",
            "preferred_time",
            "address",
            "city",
            "phone",
        ],
    )
    validate_string("test_name", data["test_name"], min_length=2, max_length=120)
    validate_string(
        "preferred_time", data["preferred_time"], min_length=2, max_length=40
    )
    validate_string("address", data["address"], min_length=5, max_length=300)
    validate_string("city", data["city"], min_length=2, max_length=120)
    validate_phone("phone", data["phone"])
    if "notes" in data and data["notes"] is not None:
        validate_string("notes", data["notes"], min_length=0, max_length=500)

    try:
        preferred_date = date.fromisoformat(str(data["preferred_date"]))
    except ValueError as exc:
        raise ValidationError("preferred_date must be in YYYY-MM-DD format") from exc
    if preferred_date < date.today():
        raise ValidationError("preferred_date cannot be in the past")

    data["preferred_date"] = preferred_date.isoformat()
    return data


def validate_update_home_sample_status_payload(data: dict) -> dict:
    if not isinstance(data, dict):
        raise ValidationError("Request body must be a valid JSON object")

    require_fields(data, ["status"])
    status = str(data["status"]).strip().lower()
    if status not in ALLOWED_REQUEST_STATUSES:
        raise ValidationError(
            f"Invalid status. Must be one of: {', '.join(sorted(ALLOWED_REQUEST_STATUSES))}"
        )
    data["status"] = status
    return data
