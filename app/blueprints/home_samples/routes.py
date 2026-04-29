from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required

from app.blueprints.home_samples.schemas import (
    validate_create_home_sample_request_payload,
    validate_update_home_sample_status_payload,
)
from app.blueprints.home_samples.services import (
    create_home_sample_request,
    list_my_home_sample_requests,
    update_home_sample_request_status,
)


home_samples_bp = Blueprint("home_samples", __name__)


@home_samples_bp.post("")
@jwt_required()
def create_request():
    current_user_id = get_jwt_identity()
    payload = validate_create_home_sample_request_payload(
        request.get_json(silent=True)
    )
    item = create_home_sample_request(current_user_id, payload)
    return jsonify({"item": item}), 201


@home_samples_bp.get("/mine")
@jwt_required()
def get_my_requests():
    current_user_id = get_jwt_identity()
    items = list_my_home_sample_requests(current_user_id)
    return jsonify({"items": items}), 200


@home_samples_bp.put("/<request_id>/status")
@jwt_required()
def update_status(request_id: str):
    current_user_id = get_jwt_identity()
    payload = validate_update_home_sample_status_payload(
        request.get_json(silent=True)
    )
    item = update_home_sample_request_status(current_user_id, request_id, payload)
    return jsonify({"item": item}), 200
