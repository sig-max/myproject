from flask_jwt_extended import create_access_token

from app.blueprints.auth.models import create_user, get_user_by_email
from app.extensions import bcrypt
from app.utils.errors import APIError
from app.utils.helpers import serialize_document


def register_user(payload: dict) -> dict:
    existing_user = get_user_by_email(payload["email"])
    if existing_user:
        raise APIError("Email already registered", status_code=409)

    password_hash = bcrypt.generate_password_hash(payload["password"]).decode("utf-8")
    created_user = create_user(payload, password_hash)
    user_payload = serialize_document(_exclude_password(created_user))
    token = create_access_token(identity=str(created_user["_id"]))

    return {
        "access_token": token,
        "token": token,
        "user": user_payload,
    }


def authenticate_user(payload: dict) -> dict:
    user = get_user_by_email(payload["email"])
    if not user:
        raise APIError("Invalid email or password", status_code=401)

    if not bcrypt.check_password_hash(user["password_hash"], payload["password"]):
        raise APIError("Invalid email or password", status_code=401)

    user_id = str(user["_id"])
    token = create_access_token(identity=user_id)

    return {
        "access_token": token,
        "token": token,
        "user": serialize_document(_exclude_password(user)),
    }


def _exclude_password(user: dict) -> dict:
    payload = {**user}
    payload.pop("password_hash", None)
    return payload
