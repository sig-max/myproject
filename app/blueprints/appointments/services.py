from app.blueprints.appointments.models import (
    create_appointment_booking as create_appointment_booking_model,
    create_appointment_slot as create_appointment_slot_model,
    list_my_appointments as list_my_appointments_model,
    list_slots_for_current_specialist as list_slots_for_current_specialist_model,
    list_slots_for_specialist as list_slots_for_specialist_model,
)
from app.blueprints.users.models import get_user_by_id
from app.utils.errors import APIError
from app.utils.helpers import serialize_document


def create_appointment_slot(current_user_id: str, payload: dict) -> dict:
    current_user = get_user_by_id(current_user_id)
    if not current_user or current_user.get("role") != "specialist":
        raise APIError("Only specialists can create appointment slots", status_code=403)

    slot = create_appointment_slot_model(current_user_id, payload)
    if slot == "overlap":
        raise APIError("This slot overlaps an existing availability slot", status_code=409)
    return _serialize_appointment_payload(slot)


def list_specialist_slots(specialist_user_id: str, available_only: bool = False) -> list[dict]:
    slots = list_slots_for_specialist_model(specialist_user_id, available_only=available_only)
    return [_serialize_appointment_payload(slot) for slot in slots]


def list_current_specialist_slots(current_user_id: str) -> list[dict]:
    current_user = get_user_by_id(current_user_id)
    if not current_user or current_user.get("role") != "specialist":
        raise APIError("Only specialists can view their slots", status_code=403)

    slots = list_slots_for_current_specialist_model(current_user_id)
    return [_serialize_appointment_payload(slot) for slot in slots]


def create_appointment_booking(current_user_id: str, payload: dict) -> dict:
    current_user = get_user_by_id(current_user_id)
    if not current_user or current_user.get("role") != "patient":
        raise APIError("Only patients can book appointments", status_code=403)

    appointment = create_appointment_booking_model(current_user_id, payload)
    if appointment is None:
        raise APIError("Appointment slot not found", status_code=404)
    if appointment == "already_booked":
        raise APIError("Appointment slot is already booked", status_code=409)

    return _serialize_appointment_payload(appointment)


def list_my_appointments(current_user_id: str) -> list[dict]:
    current_user = get_user_by_id(current_user_id)
    if not current_user:
        raise APIError("User not found", status_code=404)

    appointments = list_my_appointments_model(current_user_id, current_user.get("role", "patient"))
    return [_serialize_appointment_payload(item) for item in appointments]


def _serialize_appointment_payload(document: dict) -> dict:
    payload = serialize_document(document)
    for field_name in [
        "specialist_user_id",
        "patient_user_id",
        "slot_id",
    ]:
        if field_name in payload and payload[field_name] is not None:
            payload[field_name] = str(payload[field_name])
    if "slot" in payload and isinstance(payload["slot"], dict):
        payload["slot"] = _serialize_appointment_payload(payload["slot"])
    return payload
