from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required

from app.blueprints.chats.schemas import (
    validate_create_thread_payload,
    validate_send_message_payload,
)
from app.blueprints.chats.services import (
    create_chat_message,
    get_or_create_chat_thread,
    list_my_chat_threads,
    list_thread_messages,
)


chats_bp = Blueprint("chats", __name__)


@chats_bp.post("/threads")
@jwt_required()
def create_thread():
    current_user_id = get_jwt_identity()
    payload = validate_create_thread_payload(request.get_json(silent=True))
    thread = get_or_create_chat_thread(current_user_id, payload["specialist_user_id"])
    return jsonify({"thread": thread}), 201


@chats_bp.get("/threads")
@jwt_required()
def get_threads():
    current_user_id = get_jwt_identity()
    items = list_my_chat_threads(current_user_id)
    return jsonify({"items": items}), 200


@chats_bp.get("/threads/<thread_id>/messages")
@jwt_required()
def get_messages(thread_id: str):
    current_user_id = get_jwt_identity()
    items = list_thread_messages(current_user_id, thread_id)
    return jsonify({"items": items}), 200


@chats_bp.post("/messages")
@jwt_required()
def send_message():
    current_user_id = get_jwt_identity()
    payload = validate_send_message_payload(request.get_json(silent=True))
    item = create_chat_message(current_user_id, payload)
    return jsonify({"item": item}), 201
