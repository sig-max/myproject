from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required

from app.blueprints.reminders.schemas import (
    validate_create_reminder_payload,
    validate_medicine_id_query,
)
from app.blueprints.reminders.services import (
    create_reminder,
    delete_reminder,
    list_reminders,
)


reminders_bp = Blueprint("reminders", __name__)


@reminders_bp.post("")
@jwt_required()
def create_reminder_route():
    user_id = get_jwt_identity()
    payload = validate_create_reminder_payload(request.get_json(silent=True))
    reminder = create_reminder(user_id, payload)
    return (
        jsonify(
            {
                "success": True,
                "message": "Reminder created successfully",
                "data": reminder,
            }
        ),
        201,
    )


@reminders_bp.get("")
@jwt_required()
def list_reminders_route():
    user_id = get_jwt_identity()
    medicine_id = validate_medicine_id_query(request.args.get("medicine_id"))
    reminders = list_reminders(user_id, medicine_id=medicine_id)
    return jsonify({"success": True, "data": reminders}), 200


@reminders_bp.delete("/<reminder_id>")
@jwt_required()
def delete_reminder_route(reminder_id: str):
    user_id = get_jwt_identity()
    delete_reminder(user_id, reminder_id)
    return jsonify({"success": True, "message": "Reminder deleted successfully"}), 200
