from app.blueprints.home_samples.models import (
    create_home_sample_request as create_home_sample_request_model,
    list_home_sample_requests_for_patient,
    list_home_sample_requests_for_specialist,
    update_home_sample_request_status as update_home_sample_request_status_model,
)
from app.blueprints.users.models import get_user_by_id
from app.extensions import mongo
from app.utils.errors import APIError
from app.utils.helpers import serialize_document


def create_home_sample_request(current_user_id: str, payload: dict) -> dict:
    current_user = get_user_by_id(current_user_id)
    if not current_user or current_user.get("role") != "patient":
        raise APIError(
            "Only patients can request home sample collection", status_code=403
        )

    request_doc = create_home_sample_request_model(current_user_id, payload)
    return _serialize_home_sample_request(request_doc)


def list_my_home_sample_requests(current_user_id: str) -> list[dict]:
    current_user = get_user_by_id(current_user_id)
    if not current_user:
        raise APIError("User not found", status_code=404)

    if current_user.get("role") == "specialist":
        items = list_home_sample_requests_for_specialist(current_user_id)
    else:
        items = list_home_sample_requests_for_patient(current_user_id)

    return [_serialize_home_sample_request(item) for item in items]


def update_home_sample_request_status(
    current_user_id: str, request_id: str, payload: dict
) -> dict:
    current_user = get_user_by_id(current_user_id)
    if not current_user or current_user.get("role") != "specialist":
        raise APIError(
            "Only specialists can update home sample requests", status_code=403
        )

    updated_doc = update_home_sample_request_status_model(
        current_user_id,
        request_id,
        payload["status"],
    )
    if updated_doc is None:
        raise APIError("Home sample request not found", status_code=404)
    if updated_doc == "already_assigned":
        raise APIError(
            "This request has already been accepted by another specialist",
            status_code=409,
        )
    if updated_doc == "forbidden":
        raise APIError(
            "Only the assigned specialist can update this request", status_code=403
        )

    return _serialize_home_sample_request(updated_doc)


def _serialize_home_sample_request(document: dict) -> dict:
    payload = serialize_document(document)
    for field_name in ["patient_user_id", "specialist_user_id"]:
        if payload.get(field_name) is not None:
            payload[field_name] = str(payload[field_name])

    patient = mongo.db["users"].find_one({"_id": document["patient_user_id"]})
    if patient:
        payload["patient_name"] = patient.get("name", "")

    specialist_id = document.get("specialist_user_id")
    if specialist_id:
        specialist = mongo.db["users"].find_one({"_id": specialist_id})
        if specialist:
            payload["specialist_name"] = specialist.get("name", "")

    return payload
