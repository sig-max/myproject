from datetime import datetime

from app.utils.errors import ValidationError
from app.utils.validators import require_fields, validate_number, validate_string


def validate_create_expense_payload(data) -> dict:
    if not isinstance(data, dict):
        raise ValidationError("Request body must be a valid JSON object")

    # Updated field names to match Flutter
    require_fields(data, ["title", "amount", "date"])

    validate_string("title", data["title"], min_length=2, max_length=120)
    validate_number("amount", data["amount"], min_value=0)

    validate_string("date", data["date"], min_length=10, max_length=10)
    _validate_iso_date(data["date"], field_name="date")

    if "category" in data and data["category"] is not None:
        validate_string("category", data["category"], min_length=2, max_length=50)

    if "notes" in data and data["notes"] is not None:
        validate_string("notes", data["notes"], min_length=1, max_length=1000)

    return data


def validate_expense_filters(from_date: str | None, to_date: str | None) -> tuple[str | None, str | None]:
    if from_date is not None:
        validate_string("from_date", from_date, min_length=10, max_length=10)
        _validate_iso_date(from_date, field_name="from_date")

    if to_date is not None:
        validate_string("to_date", to_date, min_length=10, max_length=10)
        _validate_iso_date(to_date, field_name="to_date")

    return from_date, to_date


def validate_month_filter(month: str | None) -> str | None:
    if month is None:
        return None

    validate_string("month", month, min_length=7, max_length=7)

    try:
        datetime.strptime(month, "%Y-%m")
    except ValueError as exc:
        raise ValidationError("month must be in YYYY-MM format") from exc

    return month


def validate_summary_filters(year: str | None, month: str | None) -> tuple[int | None, int | None]:
    parsed_year = None
    parsed_month = None

    if year is not None:
        if not year.isdigit():
            raise ValidationError("year must be a valid integer")

        parsed_year = int(year)

        if parsed_year < 1970 or parsed_year > 2100:
            raise ValidationError("year is out of allowed range")

    if month is not None:
        if not month.isdigit():
            raise ValidationError("month must be a valid integer")

        parsed_month = int(month)

        if parsed_month < 1 or parsed_month > 12:
            raise ValidationError("month must be between 1 and 12")

    return parsed_year, parsed_month


def _validate_iso_date(value: str, field_name: str) -> None:
    try:
        datetime.strptime(value, "%Y-%m-%d")
    except ValueError as exc:
        raise ValidationError(f"{field_name} must be in YYYY-MM-DD format") from exc