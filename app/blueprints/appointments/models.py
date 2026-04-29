from datetime import datetime, timedelta, timezone

from app.blueprints.users.models import get_user_by_id
from app.extensions import mongo
from app.utils.helpers import parse_object_id


APPOINTMENT_SLOTS_COLLECTION = "appointment_slots"
APPOINTMENTS_COLLECTION = "appointments"
AUTO_ACCEPT_MINUTES = 60


def create_appointment_slot(specialist_user_id: str, payload: dict):
    specialist = get_user_by_id(specialist_user_id)
    if not specialist:
        return None

    slot_ranges = _build_slot_ranges(payload)
    created_slots = []
    had_overlap = False
    for start_at, end_at in slot_ranges:
        overlapping_slot = mongo.db[APPOINTMENT_SLOTS_COLLECTION].find_one(
            {
                "specialist_user_id": specialist["_id"],
                "start_at": {"$lt": end_at},
                "end_at": {"$gt": start_at},
            }
        )
        if overlapping_slot:
            had_overlap = True
            continue

        now = datetime.now(timezone.utc)
        slot_doc = {
            "specialist_user_id": specialist["_id"],
            "start_at": start_at,
            "end_at": end_at,
            "is_booked": False,
            "created_at": now,
            "updated_at": now,
            "repeat_weekdays": payload.get("repeat_weekdays", []),
            "repeat_weeks": payload.get("repeat_weeks", 1),
        }
        result = mongo.db[APPOINTMENT_SLOTS_COLLECTION].insert_one(slot_doc)
        created_slots.append(
            mongo.db[APPOINTMENT_SLOTS_COLLECTION].find_one({"_id": result.inserted_id})
        )

    if not created_slots and had_overlap:
        return "overlap"

    return {
        "items": created_slots,
        "created_count": len(created_slots),
        "had_overlap": had_overlap,
    }


def list_slots_for_specialist(specialist_user_id: str, available_only: bool = False) -> list[dict]:
    specialist_object_id = parse_object_id(specialist_user_id, field_name="specialist_id")
    query = {
        "specialist_user_id": specialist_object_id,
        "end_at": {"$gte": datetime.now(timezone.utc)},
    }
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
        .find(
            {
                "specialist_user_id": specialist_object_id,
                "end_at": {"$gte": datetime.now(timezone.utc)},
            }
        )
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
    if slot["end_at"] < datetime.now(timezone.utc):
        return "expired"

    now = datetime.now(timezone.utc)
    appointment_doc = {
        "slot_id": slot["_id"],
        "patient_user_id": patient["_id"],
        "specialist_user_id": slot["specialist_user_id"],
        "status": "pending",
        "notes": payload.get("notes", "").strip(),
        "booked_at": now,
        "requested_at": now,
        "auto_accept_at": now.replace(second=0, microsecond=0),
        "created_at": now,
        "updated_at": now,
    }
    appointment_doc["auto_accept_at"] = appointment_doc["auto_accept_at"] + timedelta(
        minutes=AUTO_ACCEPT_MINUTES
    )
    result = mongo.db[APPOINTMENTS_COLLECTION].insert_one(appointment_doc)
    mongo.db[APPOINTMENT_SLOTS_COLLECTION].update_one(
        {"_id": slot["_id"]},
        {"$set": {"is_booked": True, "updated_at": now}},
    )
    return mongo.db[APPOINTMENTS_COLLECTION].find_one({"_id": result.inserted_id})


def list_my_appointments(user_id: str, role: str) -> list[dict]:
    promote_due_pending_appointments()
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


def accept_appointment(specialist_user_id: str, appointment_id: str) -> dict | str | None:
    promote_due_pending_appointments()
    specialist_object_id = parse_object_id(specialist_user_id, field_name="specialist_user_id")
    appointment_object_id = parse_object_id(appointment_id, field_name="appointment_id")
    appointment = mongo.db[APPOINTMENTS_COLLECTION].find_one({"_id": appointment_object_id})
    if not appointment:
        return None
    if appointment["specialist_user_id"] != specialist_object_id:
        return "forbidden"
    if appointment.get("status") == "accepted":
        return appointment
    if appointment.get("status") != "pending":
        return "invalid_status"

    now = datetime.now(timezone.utc)
    mongo.db[APPOINTMENTS_COLLECTION].update_one(
        {"_id": appointment_object_id},
        {
            "$set": {
                "status": "accepted",
                "accepted_at": now,
                "updated_at": now,
            }
        },
    )
    return mongo.db[APPOINTMENTS_COLLECTION].find_one({"_id": appointment_object_id})


def promote_due_pending_appointments() -> None:
    now = datetime.now(timezone.utc)
    mongo.db[APPOINTMENTS_COLLECTION].update_many(
        {
            "status": "pending",
            "auto_accept_at": {"$lte": now},
        },
        {
            "$set": {
                "status": "accepted",
                "accepted_at": now,
                "updated_at": now,
            }
        },
    )


def _build_slot_ranges(payload: dict) -> list[tuple[datetime, datetime]]:
    base_start = payload["start_at"]
    base_end = payload["end_at"]
    repeat_weekdays = payload.get("repeat_weekdays", [])
    repeat_weeks = payload.get("repeat_weeks", 1)

    if not repeat_weekdays:
        return [(base_start, base_end)]

    duration = base_end - base_start
    start_of_week = base_start.date()
    weekday_offset = base_start.weekday()
    monday = start_of_week - timedelta(days=weekday_offset)

    ranges = []
    seen = set()
    for week_index in range(repeat_weeks):
        week_start = monday + timedelta(days=week_index * 7)
        for weekday in repeat_weekdays:
            slot_date = week_start + timedelta(days=weekday)
            start_at = datetime(
                slot_date.year,
                slot_date.month,
                slot_date.day,
                base_start.hour,
                base_start.minute,
                tzinfo=timezone.utc,
            )
            end_at = start_at + duration
            if start_at <= datetime.now(timezone.utc):
                continue
            key = (start_at.isoformat(), end_at.isoformat())
            if key in seen:
                continue
            seen.add(key)
            ranges.append((start_at, end_at))

    ranges.sort(key=lambda item: item[0])
    return ranges
