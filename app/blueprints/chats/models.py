from datetime import datetime, timezone

from app.blueprints.users.models import get_user_by_id
from app.extensions import mongo
from app.utils.helpers import parse_object_id


CHAT_THREADS_COLLECTION = "chat_threads"
CHAT_MESSAGES_COLLECTION = "chat_messages"


def get_or_create_chat_thread(patient_user_id: str, specialist_user_id: str) -> dict:
    patient = get_user_by_id(patient_user_id)
    specialist = get_user_by_id(specialist_user_id)

    thread = mongo.db[CHAT_THREADS_COLLECTION].find_one(
        {
            "patient_user_id": patient["_id"],
            "specialist_user_id": specialist["_id"],
        }
    )
    if thread:
        return thread

    now = datetime.now(timezone.utc)
    thread_doc = {
        "patient_user_id": patient["_id"],
        "specialist_user_id": specialist["_id"],
        "last_message_text": "",
        "last_message_at": now,
        "created_at": now,
        "updated_at": now,
    }
    result = mongo.db[CHAT_THREADS_COLLECTION].insert_one(thread_doc)
    return mongo.db[CHAT_THREADS_COLLECTION].find_one({"_id": result.inserted_id})


def list_chat_threads_for_user(user_id: str, role: str) -> list[dict]:
    object_id = parse_object_id(user_id, field_name="user_id")
    query = (
        {"specialist_user_id": object_id}
        if role == "specialist"
        else {"patient_user_id": object_id}
    )
    return list(
        mongo.db[CHAT_THREADS_COLLECTION].find(query).sort("updated_at", -1)
    )


def get_chat_thread(thread_id: str) -> dict | None:
    object_id = parse_object_id(thread_id, field_name="thread_id")
    return mongo.db[CHAT_THREADS_COLLECTION].find_one({"_id": object_id})


def list_chat_messages(thread_id: str) -> list[dict]:
    thread_object_id = parse_object_id(thread_id, field_name="thread_id")
    return list(
        mongo.db[CHAT_MESSAGES_COLLECTION]
        .find({"thread_id": thread_object_id})
        .sort("created_at", 1)
    )


def create_chat_message(sender_user_id: str, payload: dict) -> dict:
    sender = get_user_by_id(sender_user_id)
    thread_object_id = parse_object_id(payload["thread_id"], field_name="thread_id")
    thread = mongo.db[CHAT_THREADS_COLLECTION].find_one({"_id": thread_object_id})
    if not thread:
        return None

    attachments = payload.get("attachments", [])
    now = datetime.now(timezone.utc)
    message_doc = {
        "thread_id": thread["_id"],
        "sender_user_id": sender["_id"],
        "sender_role": sender.get("role", "patient"),
        "message_text": payload.get("message_text", "").strip(),
        "attachments": attachments,
        "created_at": now,
        "updated_at": now,
    }
    result = mongo.db[CHAT_MESSAGES_COLLECTION].insert_one(message_doc)
    mongo.db[CHAT_THREADS_COLLECTION].update_one(
        {"_id": thread["_id"]},
        {
            "$set": {
                "last_message_text": message_doc["message_text"],
                "last_message_at": now,
                "updated_at": now,
            }
        },
    )
    return mongo.db[CHAT_MESSAGES_COLLECTION].find_one({"_id": result.inserted_id})
