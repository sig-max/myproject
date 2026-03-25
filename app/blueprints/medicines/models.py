from datetime import datetime, timezone
import re
from typing import Any

from bson import ObjectId
from pymongo.collection import Collection

from app.extensions import mongo
from app.utils.helpers import parse_object_id

MEDICINES_COLLECTION = "medicines"
_HHMM_RE = re.compile(r"^([01]\d|2[0-3]):([0-5]\d)$")
_TIME_SLOT_MAP = {
    "morning": "morning",
    "afternoon": "afternoon",
    "evening": "evening",
    "night": "night",
}
_TIME_SLOT_ORDER = {"morning": 0, "afternoon": 1, "evening": 2, "night": 3}


def _normalize_times(raw) -> list[str]:
    if not isinstance(raw, list):
        return []
    seen: set[str] = set()
    out: list[str] = []
    for item in raw:
        t = str(item).strip()
        slot = _TIME_SLOT_MAP.get(t.lower())
        if slot and slot not in seen:
            seen.add(slot)
            out.append(slot)
            continue

        # Legacy compatibility for older HH:MM reminder times.
        if _HHMM_RE.match(t) and t not in seen:
            seen.add(t)
            out.append(t)

    out.sort(key=lambda value: (_TIME_SLOT_ORDER.get(value, 99), value))
    return out


def _to_non_negative_int(value, default: int = 0) -> int:
    try:
        return max(0, int(value))
    except (TypeError, ValueError):
        return default


def _medicines_collection() -> Collection:
    db = mongo.db
    if db is None:
        raise RuntimeError("MongoDB is not initialized")
    return db[MEDICINES_COLLECTION]


def _extract_name(payload: dict[str, Any]) -> str:
    return str(payload.get("name", payload.get("medicine_name", ""))).strip()


def _extract_stock(payload: dict[str, Any]) -> int:
    return _to_non_negative_int(payload.get("stock", payload.get("quantity", 0)), 0)


def _extract_times(payload: dict[str, Any]) -> list[str]:
    return _normalize_times(payload.get("times", payload.get("reminder_times", [])))


def create_medicine(user_id: str, payload: dict) -> dict:
    now = datetime.now(timezone.utc)
    times = _extract_times(payload)
    collection = _medicines_collection()

    doc = {
        "user_id": user_id,
        "name": _extract_name(payload),
        "dosage": str(payload.get("dosage", "")).strip(),
        "times": times,
        "stock": _extract_stock(payload),
        "notes": str(payload.get("notes", "")).strip(),
        "created_at": now,
        "updated_at": now,
        # compatibility for older clients that still read frequency
        "frequency": len(times),
    }

    result = collection.insert_one(doc)
    created = collection.find_one({"_id": result.inserted_id})
    if created is None:
        raise RuntimeError("Failed to fetch created medicine")
    return created


def filter_user_medicines(
    user_id: str,
    medicine_name: str | None = None,
    start_date: str | None = None,  # kept for API compatibility
    dosage: str | None = None,
):
    query: dict = {"user_id": user_id}

    if medicine_name:
        query["name"] = {"$regex": medicine_name, "$options": "i"}

    if dosage:
        query["dosage"] = dosage

    return _medicines_collection().find(query).sort("created_at", -1)


def get_user_medicines(user_id: str):
    """Compatibility wrapper used by intake logs and older modules."""
    return filter_user_medicines(user_id)


def get_medicine_by_id(user_id: str, medicine_id: str):
    object_id = parse_object_id(medicine_id, "medicine_id")
    return _medicines_collection().find_one({"_id": object_id, "user_id": user_id})


def update_medicine(user_id: str, medicine_id: str, payload: dict):
    object_id = parse_object_id(medicine_id, "medicine_id")
    collection = _medicines_collection()
    update_doc: dict = {}

    if "name" in payload or "medicine_name" in payload:
        update_doc["name"] = _extract_name(payload)

    if "dosage" in payload:
        update_doc["dosage"] = str(payload.get("dosage", "")).strip()

    if "times" in payload or "reminder_times" in payload:
        normalized_times = _extract_times(payload)
        update_doc["times"] = normalized_times
        update_doc["frequency"] = len(normalized_times)  # compatibility only

    if "stock" in payload or "quantity" in payload:
        update_doc["stock"] = _extract_stock(payload)

    if "notes" in payload:
        update_doc["notes"] = str(payload.get("notes", "")).strip()

    update_doc["updated_at"] = datetime.now(timezone.utc)

    result = collection.update_one(
        {"_id": object_id, "user_id": user_id},
        {"$set": update_doc},
    )

    return result.matched_count, collection.find_one({"_id": object_id, "user_id": user_id})


def delete_medicine(user_id: str, medicine_id: str) -> int:
    object_id = parse_object_id(medicine_id, "medicine_id")
    result = _medicines_collection().delete_one({"_id": object_id, "user_id": user_id})
    return result.deleted_count