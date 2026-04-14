from app.blueprints.users.models import (
    get_user_by_id,
    list_specialists as list_specialists_model,
    update_user_profile as update_user_profile_model,
)
from app.utils.errors import NotFoundError
from app.utils.helpers import serialize_document


def get_user_profile(user_id: str) -> dict:
    user = get_user_by_id(user_id)
    if not user:
        raise NotFoundError("User not found")

    user.pop("password_hash", None)

    return serialize_document(user)


def update_user_profile(user_id: str, payload: dict) -> dict:
    user = update_user_profile_model(user_id, payload)
    if not user:
        raise NotFoundError("User not found")

    user.pop("password_hash", None)

    return serialize_document(user)


def list_specialists(filters: dict | None = None) -> list[dict]:
    specialists = list_specialists_model(filters)
    serialized = []
    for specialist in specialists:
        specialist.pop("password_hash", None)
        serialized.append(serialize_document(specialist))
    return serialized
