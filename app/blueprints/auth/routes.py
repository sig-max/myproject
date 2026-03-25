from flask import Blueprint, jsonify, request

from app.blueprints.auth.schemas import (
    validate_json_payload,
    validate_login_payload,
    validate_register_payload,
)
from app.blueprints.auth.services import authenticate_user, register_user


auth_bp = Blueprint("auth", __name__)


@auth_bp.post("/register")
def register():
    print("Register request received")
    payload = validate_register_payload(validate_json_payload(request.get_json(silent=True)))
    data = register_user(payload)
    return jsonify(data), 201


@auth_bp.post("/login")
def login():
    print("Login request received")
    payload = validate_login_payload(validate_json_payload(request.get_json(silent=True)))
    data = authenticate_user(payload)
    return jsonify(data), 200
