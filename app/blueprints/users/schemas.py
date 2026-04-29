from app.utils.errors import ValidationError
from app.utils.validators import (
    validate_list,
    validate_number,
    validate_phone,
    validate_string,
)


def validate_update_profile_payload(data) -> dict:
    if not isinstance(data, dict):
        raise ValidationError("Request body must be a valid JSON object")

    allowed_fields = {
        "full_name",
        "phone",
        "bio",
        "city",
        "state",
        "languages",
        "conditions",
        "preferred_specializations",
        "specialization",
        "years_of_experience",
        "consultation_fee",
    }
    unknown_fields = [field for field in data.keys() if field not in allowed_fields]
    if unknown_fields:
        raise ValidationError("Unknown fields in request", details={"fields": unknown_fields})

    if "full_name" in data:
        validate_string("full_name", data["full_name"], min_length=2, max_length=120)
    if "phone" in data and data["phone"] is not None:
        validate_phone("phone", data["phone"])
    if "bio" in data and data["bio"] is not None:
        validate_string("bio", data["bio"], min_length=0, max_length=500)
    if "city" in data and data["city"] is not None:
        validate_string("city", data["city"], min_length=2, max_length=120)
    if "state" in data and data["state"] is not None:
        validate_string("state", data["state"], min_length=2, max_length=120)
    if "specialization" in data and data["specialization"] is not None:
        validate_string("specialization", data["specialization"], min_length=2, max_length=120)
    if "years_of_experience" in data:
        validate_number("years_of_experience", data["years_of_experience"], min_value=0)
    if "consultation_fee" in data:
        validate_number("consultation_fee", data["consultation_fee"], min_value=0)
    for field_name in ["languages", "conditions", "preferred_specializations"]:
        if field_name in data:
            validate_list(field_name, data[field_name])
            for item in data[field_name]:
                validate_string(field_name, item, min_length=1, max_length=120)

    if not data:
        raise ValidationError("At least one field is required for update")

    return data
