from datetime import datetime, timezone

from app.extensions import mongo
from app.utils.helpers import parse_object_id


USERS_COLLECTION = "users"


def build_user_document(payload: dict, password_hash: str) -> dict:
    now = datetime.now(timezone.utc)
    return {
        "name": payload["name"].strip(),
        "email": payload["email"].strip().lower(),
        "password_hash": password_hash,
        "created_at": now,
        "updated_at": now,
    }


def create_user(payload: dict, password_hash: str) -> dict:
    user_doc = build_user_document(payload, password_hash)
    result = mongo.db[USERS_COLLECTION].insert_one(user_doc)
    return mongo.db[USERS_COLLECTION].find_one({"_id": result.inserted_id})


def get_user_by_email(email: str) -> dict | None:
    return mongo.db[USERS_COLLECTION].find_one({"email": email.strip().lower()})


def get_user_by_id(user_id: str) -> dict | None:
    object_id = parse_object_id(user_id, field_name="user_id")
    return mongo.db[USERS_COLLECTION].find_one({"_id": object_id})
