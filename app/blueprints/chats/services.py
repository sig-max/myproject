from app.blueprints.chats.models import (
    create_chat_message as create_chat_message_model,
    get_chat_thread,
    get_or_create_chat_thread as get_or_create_chat_thread_model,
    list_chat_messages as list_chat_messages_model,
    list_chat_threads_for_user as list_chat_threads_for_user_model,
)
from app.blueprints.users.models import get_user_by_id
from app.extensions import mongo
from app.utils.errors import APIError
from app.utils.helpers import serialize_document


def get_or_create_chat_thread(current_user_id: str, specialist_user_id: str) -> dict:
    current_user = get_user_by_id(current_user_id)
    if not current_user or current_user.get("role") != "patient":
        raise APIError("Only patients can start chats", status_code=403)

    specialist = get_user_by_id(specialist_user_id)
    if not specialist or specialist.get("role") != "specialist":
        raise APIError("Specialist not found", status_code=404)

    thread = get_or_create_chat_thread_model(current_user_id, specialist_user_id)
    return _serialize_chat_thread(thread)


def list_my_chat_threads(current_user_id: str) -> list[dict]:
    current_user = get_user_by_id(current_user_id)
    if not current_user:
        raise APIError("User not found", status_code=404)

    threads = list_chat_threads_for_user_model(
        current_user_id, current_user.get("role", "patient")
    )
    return [_serialize_chat_thread(thread) for thread in threads]


def list_thread_messages(current_user_id: str, thread_id: str) -> list[dict]:
    _ensure_thread_access(current_user_id, thread_id)
    messages = list_chat_messages_model(thread_id)
    return [_serialize_chat_message(message) for message in messages]


def create_chat_message(current_user_id: str, payload: dict) -> dict:
    _ensure_thread_access(current_user_id, payload["thread_id"])
    message = create_chat_message_model(current_user_id, payload)
    if not message:
        raise APIError("Chat thread not found", status_code=404)
    return _serialize_chat_message(message)


def _ensure_thread_access(current_user_id: str, thread_id: str) -> dict:
    current_user = get_user_by_id(current_user_id)
    if not current_user:
        raise APIError("User not found", status_code=404)

    thread = get_chat_thread(thread_id)
    if not thread:
        raise APIError("Chat thread not found", status_code=404)

    allowed_ids = {str(thread["patient_user_id"]), str(thread["specialist_user_id"])}
    if current_user_id not in allowed_ids:
        raise APIError("You do not have access to this chat", status_code=403)
    return thread


def _serialize_chat_thread(document: dict) -> dict:
    payload = serialize_document(document)
    payload["patient_user_id"] = str(payload["patient_user_id"])
    payload["specialist_user_id"] = str(payload["specialist_user_id"])

    patient = mongo.db["users"].find_one({"_id": document["patient_user_id"]})
    specialist = mongo.db["users"].find_one({"_id": document["specialist_user_id"]})
    if patient:
        payload["patient_name"] = patient.get("name", "")
    if specialist:
        payload["specialist_name"] = specialist.get("name", "")
    return payload


def _serialize_chat_message(document: dict) -> dict:
    payload = serialize_document(document)
    payload["thread_id"] = str(payload["thread_id"])
    payload["sender_user_id"] = str(payload["sender_user_id"])
    sender = mongo.db["users"].find_one({"_id": document["sender_user_id"]})
    if sender:
        payload["sender_name"] = sender.get("name", "")
    return payload
