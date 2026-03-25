from bson import ObjectId

from app.utils.errors import ValidationError


def parse_object_id(value: str, field_name: str = "id") -> ObjectId:
    if not ObjectId.is_valid(value):
        raise ValidationError(f"Invalid {field_name}")
    return ObjectId(value)


def serialize_document(document: dict) -> dict:
    payload = {**document}
    payload["id"] = str(payload.pop("_id"))
    return payload
