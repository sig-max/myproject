from datetime import datetime, timezone

from app.extensions import mongo
from app.utils.helpers import parse_object_id


USERS_COLLECTION = "users"


def build_user_document(payload: dict, password_hash: str) -> dict:
    now = datetime.now(timezone.utc)
    return {
        "name": payload.get("name", payload.get("full_name", "")).strip(),
        "email": payload["email"].strip().lower(),
        "password_hash": password_hash,
        "phone": payload.get("phone"),
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


def build_profile_update_document(payload: dict) -> dict:
    update_doc = {"updated_at": datetime.now(timezone.utc)}

    if "full_name" in payload:
        update_doc["name"] = payload["full_name"].strip()
    if "name" in payload:
        update_doc["name"] = payload["name"].strip()
    if "phone" in payload:
        update_doc["phone"] = payload["phone"]

    return update_doc


def update_user_profile(user_id: str, payload: dict) -> dict | None:
    object_id = parse_object_id(user_id, field_name="user_id")
    update_doc = build_profile_update_document(payload)
    mongo.db[USERS_COLLECTION].update_one({"_id": object_id}, {"$set": update_doc})
    return mongo.db[USERS_COLLECTION].find_one({"_id": object_id})
