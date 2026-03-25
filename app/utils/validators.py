import re

from app.utils.errors import ValidationError


EMAIL_REGEX = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


def require_fields(data: dict, fields: list[str]) -> None:
    missing_fields = [field for field in fields if field not in data or data[field] in (None, "")]
    if missing_fields:
        raise ValidationError("Missing required fields", details={"missing": missing_fields})


def validate_email(email: str) -> None:
    if not isinstance(email, str) or not EMAIL_REGEX.match(email):
        raise ValidationError("Invalid email address")


def validate_string(field_name: str, value, min_length: int = 1, max_length: int = 255) -> None:
    if not isinstance(value, str):
        raise ValidationError(f"{field_name} must be a string")
    if len(value.strip()) < min_length:
        raise ValidationError(f"{field_name} must be at least {min_length} characters long")
    if len(value.strip()) > max_length:
        raise ValidationError(f"{field_name} cannot exceed {max_length} characters")


def validate_number(field_name: str, value, min_value: float | None = None) -> None:
    if not isinstance(value, (int, float)):
        raise ValidationError(f"{field_name} must be a number")
    if min_value is not None and value < min_value:
        raise ValidationError(f"{field_name} must be greater than or equal to {min_value}")


def validate_list(field_name: str, value) -> None:
    if not isinstance(value, list):
        raise ValidationError(f"{field_name} must be a list")
