from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required

from app.blueprints.users.schemas import validate_update_profile_payload
from app.blueprints.users.services import get_user_profile, update_user_profile


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
