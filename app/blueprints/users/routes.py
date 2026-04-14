from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required

from app.blueprints.users.schemas import validate_update_profile_payload
from app.blueprints.users.services import (
    get_user_profile,
    list_specialists,
    update_user_profile,
)
from app.utils.errors import ValidationError


users_bp = Blueprint("users", __name__)


@users_bp.get("/me")
@jwt_required()
def get_me():
    current_user_id = get_jwt_identity()
    profile = get_user_profile(current_user_id)
    return jsonify(profile), 200


@users_bp.put("/me")
@jwt_required()
def update_me():
    current_user_id = get_jwt_identity()
    payload = validate_update_profile_payload(request.get_json(silent=True))
    profile = update_user_profile(current_user_id, payload)
    return jsonify({"message": "Profile updated successfully", "user": profile}), 200


@users_bp.get("/specialists")
@jwt_required()
def get_specialists():
    filters = {
        "specialization": request.args.get("specialization", ""),
        "city": request.args.get("city", ""),
        "language": request.args.get("language", ""),
    }

    min_fee = request.args.get("min_fee")
    max_fee = request.args.get("max_fee")
    try:
        filters["min_fee"] = float(min_fee) if min_fee not in (None, "") else None
        filters["max_fee"] = float(max_fee) if max_fee not in (None, "") else None
    except ValueError as exc:
        raise ValidationError("Fee filters must be numeric") from exc

    specialists = list_specialists(filters)
    return jsonify({"items": specialists}), 200
