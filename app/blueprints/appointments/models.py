from datetime import datetime, timezone

from app.blueprints.users.models import get_user_by_id
from app.extensions import mongo
from app.utils.helpers import parse_object_id


APPOINTMENT_SLOTS_COLLECTION = "appointment_slots"
APPOINTMENTS_COLLECTION = "appointments"


def create_appointment_slot(specialist_user_id: str, payload: dict) -> dict:
    specialist = get_user_by_id(specialist_user_id)
    overlapping_slot = mongo.db[APPOINTMENT_SLOTS_COLLECTION].find_one(
        {
            "specialist_user_id": specialist["_id"],
            "start_at": {"$lt": payload["end_at"]},
            "end_at": {"$gt": payload["start_at"]},
        }
    )
    if overlapping_slot:
        return "overlap"

    now = datetime.now(timezone.utc)
    slot_doc = {
        "specialist_user_id": specialist["_id"],
        "start_at": payload["start_at"],
        "end_at": payload["end_at"],
        "is_booked": False,
        "created_at": now,
        "updated_at": now,
    }
    result = mongo.db[APPOINTMENT_SLOTS_COLLECTION].insert_one(slot_doc)
    return mongo.db[APPOINTMENT_SLOTS_COLLECTION].find_one({"_id": result.inserted_id})


def list_slots_for_specialist(specialist_user_id: str, available_only: bool = False) -> list[dict]:
    specialist_object_id = parse_object_id(specialist_user_id, field_name="specialist_id")
    query = {"specialist_user_id": specialist_object_id}
    if available_only:
        query["is_booked"] = False
    return list(
        mongo.db[APPOINTMENT_SLOTS_COLLECTION]
        .find(query)
        .sort("start_at", 1)
    )


def list_slots_for_current_specialist(specialist_user_id: str) -> list[dict]:
    specialist_object_id = parse_object_id(specialist_user_id, field_name="specialist_id")
    return list(
        mongo.db[APPOINTMENT_SLOTS_COLLECTION]
        .find({"specialist_user_id": specialist_object_id})
        .sort("start_at", 1)
    )


def create_appointment_booking(patient_user_id: str, payload: dict) -> dict:
    patient = get_user_by_id(patient_user_id)
    slot_id = parse_object_id(payload["slot_id"], field_name="slot_id")
    slot = mongo.db[APPOINTMENT_SLOTS_COLLECTION].find_one({"_id": slot_id})
    if not slot:
        return None
    if slot.get("is_booked"):
        return "already_booked"

    now = datetime.now(timezone.utc)
    appointment_doc = {
        "slot_id": slot["_id"],
        "patient_user_id": patient["_id"],
        "specialist_user_id": slot["specialist_user_id"],
        "status": "booked",
        "notes": payload.get("notes", "").strip(),
        "booked_at": now,
        "created_at": now,
        "updated_at": now,
    }
    result = mongo.db[APPOINTMENTS_COLLECTION].insert_one(appointment_doc)
    mongo.db[APPOINTMENT_SLOTS_COLLECTION].update_one(
        {"_id": slot["_id"]},
        {"$set": {"is_booked": True, "updated_at": now}},
    )
    return mongo.db[APPOINTMENTS_COLLECTION].find_one({"_id": result.inserted_id})


def list_my_appointments(user_id: str, role: str) -> list[dict]:
    object_id = parse_object_id(user_id, field_name="user_id")
    if role == "specialist":
        query = {"specialist_user_id": object_id}
    else:
        query = {"patient_user_id": object_id}
    appointments = list(
        mongo.db[APPOINTMENTS_COLLECTION]
        .find(query)
        .sort("created_at", -1)
    )
    enriched = []
    for appointment in appointments:
        payload = {**appointment}
        slot = mongo.db[APPOINTMENT_SLOTS_COLLECTION].find_one({"_id": appointment["slot_id"]})
        if slot:
            payload["slot"] = slot
        patient = mongo.db["users"].find_one({"_id": appointment["patient_user_id"]})
        if patient:
            payload["patient_name"] = patient.get("name", "")
        specialist = mongo.db["users"].find_one({"_id": appointment["specialist_user_id"]})
        if specialist:
            payload["specialist_name"] = specialist.get("name", "")
        enriched.append(payload)
    return enriched
