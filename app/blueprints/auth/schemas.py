from app.utils.errors import ValidationError
from app.utils.validators import require_fields, validate_email, validate_string

ALLOWED_ROLES = ["patient", "specialist"]

def validate_register_payload(data: dict) -> dict:
    require_fields(data, ["name", "email", "password", "role"])
    validate_string("name", data["name"], min_length=2, max_length=120)
    validate_email(data["email"])
    validate_string("password", data["password"], min_length=8, max_length=128)
    role = str(data["role"]).strip().lower()
    validate_string("role", role, min_length=7, max_length=10)
    if role not in ALLOWED_ROLES:
        raise ValidationError(f"Invalid role. Must be one of: {', '.join(ALLOWED_ROLES)}")

    data["role"] = role
    return data


def validate_login_payload(data: dict) -> dict:
    require_fields(data, ["email", "password"])
    validate_email(data["email"])
    validate_string("password", data["password"], min_length=1, max_length=128)
    return data


def validate_json_payload(data) -> dict:
    if not isinstance(data, dict):
        raise ValidationError("Request body must be a valid JSON object")
    return data
