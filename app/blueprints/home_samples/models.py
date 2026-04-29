from datetime import datetime, timezone

from app.blueprints.users.models import get_user_by_id
from app.extensions import mongo
from app.utils.helpers import parse_object_id


HOME_SAMPLE_REQUESTS_COLLECTION = "home_sample_requests"


def create_home_sample_request(patient_user_id: str, payload: dict) -> dict:
    patient = get_user_by_id(patient_user_id)
    now = datetime.now(timezone.utc)
    request_doc = {
        "patient_user_id": patient["_id"],
        "specialist_user_id": None,
        "test_name": payload["test_name"].strip(),
        "preferred_date": payload["preferred_date"],
        "preferred_time": payload["preferred_time"].strip(),
        "address": payload["address"].strip(),
        "city": payload["city"].strip(),
        "phone": payload["phone"].strip(),
        "notes": payload.get("notes", "").strip(),
        "status": "pending",
        "created_at": now,
        "updated_at": now,
    }
    result = mongo.db[HOME_SAMPLE_REQUESTS_COLLECTION].insert_one(request_doc)
    return mongo.db[HOME_SAMPLE_REQUESTS_COLLECTION].find_one(
        {"_id": result.inserted_id}
    )


def list_home_sample_requests_for_patient(patient_user_id: str) -> list[dict]:
    patient_object_id = parse_object_id(patient_user_id, field_name="patient_user_id")
    return list(
        mongo.db[HOME_SAMPLE_REQUESTS_COLLECTION]
        .find({"patient_user_id": patient_object_id})
        .sort("created_at", -1)
    )


def list_home_sample_requests_for_specialist(specialist_user_id: str) -> list[dict]:
    specialist_object_id = parse_object_id(
        specialist_user_id, field_name="specialist_user_id"
    )
    return list(
        mongo.db[HOME_SAMPLE_REQUESTS_COLLECTION]
        .find(
            {
                "$or": [
                    {"status": "pending"},
                    {"specialist_user_id": specialist_object_id},
                ]
            }
        )
        .sort("created_at", -1)
    )


def update_home_sample_request_status(
    specialist_user_id: str, request_id: str, status: str
) -> dict | str | None:
    request_object_id = parse_object_id(request_id, field_name="request_id")
    specialist_object_id = parse_object_id(
        specialist_user_id, field_name="specialist_user_id"
    )
    request_doc = mongo.db[HOME_SAMPLE_REQUESTS_COLLECTION].find_one(
        {"_id": request_object_id}
    )
    if not request_doc:
        return None

    assigned_specialist_id = request_doc.get("specialist_user_id")
    if status == "accepted":
        if assigned_specialist_id and assigned_specialist_id != specialist_object_id:
            return "already_assigned"
    elif assigned_specialist_id and assigned_specialist_id != specialist_object_id:
        return "forbidden"

    update_doc = {
        "status": status,
        "updated_at": datetime.now(timezone.utc),
    }
    if status == "accepted" and not assigned_specialist_id:
        update_doc["specialist_user_id"] = specialist_object_id

    mongo.db[HOME_SAMPLE_REQUESTS_COLLECTION].update_one(
        {"_id": request_object_id},
        {"$set": update_doc},
    )
    return mongo.db[HOME_SAMPLE_REQUESTS_COLLECTION].find_one(
        {"_id": request_object_id}
    )
