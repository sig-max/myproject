from app.utils.errors import ValidationError
from app.utils.validators import validate_string


def validate_update_profile_payload(data) -> dict:
    if not isinstance(data, dict):
        raise ValidationError("Request body must be a valid JSON object")

    allowed_fields = {"full_name", "phone"}
    unknown_fields = [field for field in data.keys() if field not in allowed_fields]
    if unknown_fields:
        raise ValidationError("Unknown fields in request", details={"fields": unknown_fields})

    if "full_name" in data:
        validate_string("full_name", data["full_name"], min_length=2, max_length=120)
    if "phone" in data and data["phone"] is not None:
        validate_string("phone", data["phone"], min_length=8, max_length=20)

    if not data:
        raise ValidationError("At least one field is required for update")

    return data
