from app.utils.errors import ValidationError
from app.utils.validators import require_fields, validate_list, validate_string


ALLOWED_ATTACHMENT_TYPES = {"image", "file", "prescription"}


def validate_create_thread_payload(data: dict) -> dict:
    if not isinstance(data, dict):
        raise ValidationError("Request body must be a valid JSON object")

    require_fields(data, ["specialist_user_id"])
    validate_string(
        "specialist_user_id", data["specialist_user_id"], min_length=24, max_length=24
    )
    return data


def validate_send_message_payload(data: dict) -> dict:
    if not isinstance(data, dict):
        raise ValidationError("Request body must be a valid JSON object")

    require_fields(data, ["thread_id"])
    validate_string("thread_id", data["thread_id"], min_length=24, max_length=24)

    message_text = str(data.get("message_text", "")).strip()
    attachments = data.get("attachments", [])
    if not message_text and not attachments:
        raise ValidationError("Either message_text or attachments is required")

    if message_text:
        validate_string("message_text", message_text, min_length=1, max_length=2000)
    data["message_text"] = message_text

    if "attachments" in data:
        validate_list("attachments", attachments)
        for item in attachments:
            if not isinstance(item, dict):
                raise ValidationError("Each attachment must be an object")
            attachment_type = str(item.get("type", "")).strip().lower()
            if attachment_type not in ALLOWED_ATTACHMENT_TYPES:
                raise ValidationError(
                    f"Invalid attachment type. Must be one of: {', '.join(sorted(ALLOWED_ATTACHMENT_TYPES))}"
                )
            validate_string("attachment.name", item.get("name", ""), min_length=1, max_length=255)
            validate_string("attachment.url", item.get("url", ""), min_length=1, max_length=5000000)
            item["type"] = attachment_type
    else:
        data["attachments"] = []

    return data
