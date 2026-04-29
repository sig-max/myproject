import re

from app.utils.errors import ValidationError


EMAIL_REGEX = re.compile(r"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$")
PHONE_REGEX = re.compile(r"^[6-9]\d{9}$")


def require_fields(data: dict, fields: list[str]) -> None:
    missing_fields = [field for field in fields if field not in data or data[field] in (None, "")]
    if missing_fields:
        raise ValidationError("Missing required fields", details={"missing": missing_fields})


def validate_email(email: str) -> None:
    if not isinstance(email, str):
        raise ValidationError("Invalid email address")

    normalized = email.strip()
    if not EMAIL_REGEX.match(normalized):
        raise ValidationError("Invalid email address")

    local_part, _, domain_part = normalized.partition("@")
    if ".." in normalized or local_part.startswith(".") or local_part.endswith("."):
        raise ValidationError("Invalid email address")
    if domain_part.startswith(".") or domain_part.endswith(".") or "." not in domain_part:
        raise ValidationError("Invalid email address")


def validate_phone(field_name: str, value) -> None:
    if not isinstance(value, str):
        raise ValidationError(f"{field_name} must be a string")

    normalized = re.sub(r"\s+", "", value.strip())
    if not PHONE_REGEX.match(normalized):
        raise ValidationError(f"{field_name} must be a valid 10-digit mobile number")


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
