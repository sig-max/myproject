from app.blueprints.medicines.models import (
    create_medicine as create_medicine_model,
    delete_medicine as delete_medicine_model,
    filter_user_medicines,
    get_medicine_by_id,
    update_medicine as update_medicine_model,
)
from app.utils.errors import NotFoundError
from app.utils.helpers import serialize_document


def _compat_frequency(doc: dict) -> dict:
    times = doc.get("times")
    if not isinstance(times, list):
        times = []
        doc["times"] = times
    doc["frequency"] = len(times)
    return doc


def create_medicine(user_id: str, payload: dict) -> dict:
    medicine = create_medicine_model(user_id, payload)
    return _compat_frequency(serialize_document(medicine))


def list_medicines(
    user_id: str,
    medicine_name: str | None = None,
    start_date: str | None = None,
    dosage: str | None = None,
) -> list[dict]:
    cursor = filter_user_medicines(
        user_id,
        medicine_name=medicine_name,
        start_date=start_date,
        dosage=dosage,
    )
    return [_compat_frequency(serialize_document(item)) for item in cursor]


def get_medicine_detail(user_id: str, medicine_id: str) -> dict:
    medicine = get_medicine_by_id(user_id, medicine_id)
    if not medicine:
        raise NotFoundError("Medicine not found")
    return _compat_frequency(serialize_document(medicine))


def update_medicine(user_id: str, medicine_id: str, payload: dict) -> dict:
    matched_count, medicine = update_medicine_model(user_id, medicine_id, payload)
    if matched_count == 0 or medicine is None:
        raise NotFoundError("Medicine not found")
    return _compat_frequency(serialize_document(medicine))


def delete_medicine(user_id: str, medicine_id: str) -> None:
    deleted_count = delete_medicine_model(user_id, medicine_id)
    if deleted_count == 0:
        raise NotFoundError("Medicine not found")
