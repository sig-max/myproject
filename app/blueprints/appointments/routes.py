from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required

from app.blueprints.appointments.schemas import (
    validate_create_booking_payload,
    validate_create_slot_payload,
)
from app.blueprints.appointments.services import (
    create_appointment_booking,
    create_appointment_slot,
    list_current_specialist_slots,
    list_my_appointments,
    list_specialist_slots,
)
from app.utils.errors import ValidationError


appointments_bp = Blueprint("appointments", __name__)


@appointments_bp.post("/slots")
@jwt_required()
def create_slot():
    current_user_id = get_jwt_identity()
    payload = validate_create_slot_payload(request.get_json(silent=True))
    slot = create_appointment_slot(current_user_id, payload)
    return jsonify({"slot": slot}), 201


@appointments_bp.get("/slots")
@jwt_required()
def get_specialist_slots():
    specialist_id = request.args.get("specialist_id", "").strip()
    if not specialist_id:
        raise ValidationError("specialist_id is required")
    available_only = request.args.get("available_only", "false").lower() == "true"
    slots = list_specialist_slots(specialist_id, available_only=available_only)
    return jsonify({"items": slots}), 200


@appointments_bp.get("/slots/mine")
@jwt_required()
def get_my_slots():
    current_user_id = get_jwt_identity()
    slots = list_current_specialist_slots(current_user_id)
    return jsonify({"items": slots}), 200


@appointments_bp.post("/book")
@jwt_required()
def book_appointment():
    current_user_id = get_jwt_identity()
    payload = validate_create_booking_payload(request.get_json(silent=True))
    appointment = create_appointment_booking(current_user_id, payload)
    return jsonify({"appointment": appointment}), 201


@appointments_bp.get("/mine")
@jwt_required()
def get_my_appointments():
    current_user_id = get_jwt_identity()
    appointments = list_my_appointments(current_user_id)
    return jsonify({"items": appointments}), 200
