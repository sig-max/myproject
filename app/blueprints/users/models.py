from datetime import datetime, timezone

from app.extensions import mongo
from app.utils.helpers import parse_object_id


USERS_COLLECTION = "users"
PATIENT_PROFILES_COLLECTION = "patient_profiles"
SPECIALIST_PROFILES_COLLECTION = "specialist_profiles"


def build_user_document(payload: dict, password_hash: str) -> dict:
    now = datetime.now(timezone.utc)
    role = payload.get("role", "patient").strip().lower()
    return {
        "name": payload.get("name", payload.get("full_name", "")).strip(),
        "email": payload["email"].strip().lower(),
        "password_hash": password_hash,
        "role": role,
        "is_active": True,
        "is_deleted": False,
        "created_at": now,
        "updated_at": now,
    }


def build_patient_profile_document(user_id, payload: dict) -> dict:
    now = datetime.now(timezone.utc)
    return {
        "user_id": user_id,
        "phone": payload.get("phone"),
        "bio": "",
        "avatar_url": "",
        "city": "",
        "state": "",
        "languages": [],
        "conditions": [],
        "preferred_specializations": [],
        "created_at": now,
        "updated_at": now,
    }


def build_specialist_profile_document(user_id, payload: dict) -> dict:
    now = datetime.now(timezone.utc)
    return {
        "user_id": user_id,
        "phone": payload.get("phone"),
        "bio": "",
        "avatar_url": "",
        "specialization": "",
        "years_of_experience": 0,
        "city": "",
        "state": "",
        "languages": [],
        "consultation_fee": 0,
        "is_verified": False,
        "rating": 0.0,
        "reviews_count": 0,
        "patients_consulted": 0,
        "availability_summary": {
            "has_active_slots": False,
        },
        "created_at": now,
        "updated_at": now,
    }


def create_user(payload: dict, password_hash: str) -> dict:
    user_doc = build_user_document(payload, password_hash)
    result = mongo.db[USERS_COLLECTION].insert_one(user_doc)
    created_user = mongo.db[USERS_COLLECTION].find_one({"_id": result.inserted_id})
    try:
        _create_profile_for_user(created_user, payload)
    except Exception:
        mongo.db[USERS_COLLECTION].delete_one({"_id": created_user["_id"]})
        raise
    return get_user_by_id(str(created_user["_id"]))


def _create_profile_for_user(user_doc: dict, payload: dict) -> None:
    if user_doc["role"] == "specialist":
        profile_doc = build_specialist_profile_document(user_doc["_id"], payload)
        mongo.db[SPECIALIST_PROFILES_COLLECTION].insert_one(profile_doc)
        return

    profile_doc = build_patient_profile_document(user_doc["_id"], payload)
    mongo.db[PATIENT_PROFILES_COLLECTION].insert_one(profile_doc)


def get_user_by_email(email: str) -> dict | None:
    user = mongo.db[USERS_COLLECTION].find_one({"email": email.strip().lower()})
    return _merge_user_with_profile(user)


def get_user_by_id(user_id: str) -> dict | None:
    object_id = parse_object_id(user_id, field_name="user_id")
    user = mongo.db[USERS_COLLECTION].find_one({"_id": object_id})
    return _merge_user_with_profile(user)


def _merge_user_with_profile(user: dict | None) -> dict | None:
    if not user:
        return None

    user_payload = {**user}
    profile = _get_profile_for_user(user_payload)
    user_payload["profile"] = _serialize_profile_document(profile)
    return user_payload


def _get_profile_for_user(user: dict) -> dict | None:
    collection_name = (
        SPECIALIST_PROFILES_COLLECTION
        if user.get("role") == "specialist"
        else PATIENT_PROFILES_COLLECTION
    )
    return mongo.db[collection_name].find_one({"user_id": user["_id"]})


def _serialize_profile_document(profile: dict | None) -> dict:
    if not profile:
        return {}

    payload = {**profile}
    payload["id"] = str(payload.pop("_id"))
    payload["user_id"] = str(payload["user_id"])
    return payload


def update_user_profile(user_id: str, payload: dict) -> dict | None:
    object_id = parse_object_id(user_id, field_name="user_id")
    now = datetime.now(timezone.utc)

    user_update_doc = {}
    if "full_name" in payload:
        user_update_doc["name"] = payload["full_name"].strip()
    if "name" in payload:
        user_update_doc["name"] = payload["name"].strip()

    if user_update_doc:
        user_update_doc["updated_at"] = now
        mongo.db[USERS_COLLECTION].update_one({"_id": object_id}, {"$set": user_update_doc})

    user = mongo.db[USERS_COLLECTION].find_one({"_id": object_id})
    if not user:
        return None

    profile_update_doc = {}
    shared_profile_fields = ["phone", "bio", "city", "state", "languages"]
    for field_name in shared_profile_fields:
        if field_name in payload:
            profile_update_doc[field_name] = payload[field_name]

    if user.get("role") == "specialist":
        for field_name in ["specialization", "years_of_experience", "consultation_fee"]:
            if field_name in payload:
                profile_update_doc[field_name] = payload[field_name]
    else:
        for field_name in ["conditions", "preferred_specializations"]:
            if field_name in payload:
                profile_update_doc[field_name] = payload[field_name]

    if profile_update_doc:
        profile_update_doc["updated_at"] = now
        collection_name = (
            SPECIALIST_PROFILES_COLLECTION
            if user.get("role") == "specialist"
            else PATIENT_PROFILES_COLLECTION
        )
        mongo.db[collection_name].update_one(
            {"user_id": object_id},
            {"$set": profile_update_doc},
        )

    return get_user_by_id(user_id)


def list_specialists(filters: dict | None = None) -> list[dict]:
    filters = filters or {}
    profile_query = {}

    specialization = filters.get("specialization", "").strip()
    city = filters.get("city", "").strip()
    language = filters.get("language", "").strip()

    if specialization:
        profile_query["specialization"] = {"$regex": specialization, "$options": "i"}
    if city:
        profile_query["city"] = {"$regex": city, "$options": "i"}
    if language:
        profile_query["languages"] = {"$elemMatch": {"$regex": language, "$options": "i"}}

    min_fee = filters.get("min_fee")
    max_fee = filters.get("max_fee")
    if min_fee is not None or max_fee is not None:
        fee_query = {}
        if min_fee is not None:
            fee_query["$gte"] = min_fee
        if max_fee is not None:
            fee_query["$lte"] = max_fee
        profile_query["consultation_fee"] = fee_query

    specialist_profiles = list(
        mongo.db[SPECIALIST_PROFILES_COLLECTION]
        .find(profile_query)
        .sort("updated_at", -1)
    )

    specialists = []
    for profile in specialist_profiles:
        user = mongo.db[USERS_COLLECTION].find_one(
            {
                "_id": profile["user_id"],
                "role": "specialist",
                "is_active": True,
                "is_deleted": False,
            }
        )
        if not user:
            continue

        merged_user = {**user, "profile": _serialize_profile_document(profile)}
        specialists.append(merged_user)

    return specialists
