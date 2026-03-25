from datetime import datetime, timezone

from app.extensions import mongo
from app.utils.helpers import parse_object_id


REMINDERS_COLLECTION = "reminders"


def build_reminder_document(user_id: str, payload: dict) -> dict:
    now = datetime.now(timezone.utc)
    return {
        "user_id": user_id,
        "medicine_id": payload["medicine_id"],
        "reminder_time": payload["reminder_time"],
        "repeat_type": payload.get("repeat_type", "daily"),
        "is_active": payload.get("is_active", True),
        "created_at": now,
        "updated_at": now,
    }


def build_reminder_update_document(payload: dict) -> dict:
    update_doc = {"updated_at": datetime.now(timezone.utc)}
    field_map = {
        "medicine_id": "medicine_id",
        "title": "title",
        "time": "reminder_time",
        "reminder_time": "reminder_time",
        "frequency": "repeat_type",
        "repeat_type": "repeat_type",
        "is_active": "is_active",
    }
    for field, mapped_field in field_map.items():
        if field in payload:
            update_doc[mapped_field] = (
                payload[field].strip() if isinstance(payload[field], str) else payload[field]
            )
    return update_doc


def create_reminder(user_id: str, payload: dict) -> dict:
    doc = build_reminder_document(user_id, payload)
    result = mongo.db[REMINDERS_COLLECTION].insert_one(doc)
    return mongo.db[REMINDERS_COLLECTION].find_one({"_id": result.inserted_id})


def get_reminders(user_id: str, medicine_id: str | None = None):
    query = {"user_id": user_id}
    if medicine_id:
        query["medicine_id"] = medicine_id
    return mongo.db[REMINDERS_COLLECTION].find(query).sort("created_at", -1)


def update_reminder(user_id: str, reminder_id: str, payload: dict):
    object_id = parse_object_id(reminder_id, "reminder_id")
    update_doc = build_reminder_update_document(payload)
    result = mongo.db[REMINDERS_COLLECTION].update_one(
        {"_id": object_id, "user_id": user_id}, {"$set": update_doc}
    )
    return result.matched_count, mongo.db[REMINDERS_COLLECTION].find_one(
        {"_id": object_id, "user_id": user_id}
    )


def delete_reminder(user_id: str, reminder_id: str) -> int:
    object_id = parse_object_id(reminder_id, "reminder_id")
    result = mongo.db[REMINDERS_COLLECTION].delete_one({"_id": object_id, "user_id": user_id})
    return result.deleted_count
