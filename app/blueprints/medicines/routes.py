from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required
from datetime import datetime, timezone
import re

HHMM_RE = re.compile(r"^([01]\d|2[0-3]):([0-5]\d)$")

from app.blueprints.medicines.schemas import (
    validate_create_medicine_payload,
    validate_medicine_filters,
    validate_update_medicine_payload,
)
from app.blueprints.medicines.services import (
    create_medicine,
    delete_medicine,
    get_medicine_detail,
    list_medicines,
    update_medicine,
)


medicines_bp = Blueprint("medicines", __name__)


@medicines_bp.post("")
@jwt_required()
def create_medicine_route():
    print("Create medicine request received")
    user_id = get_jwt_identity()
    payload = validate_create_medicine_payload(request.get_json(silent=True))
    medicine = create_medicine(user_id, payload)
    return (
        jsonify(
            {
                "success": True,
                "message": "Medicine created successfully",
                "data": medicine,
            }
        ),
        201,
    )


@medicines_bp.get("")
@jwt_required()
def list_medicines_route():
    print("List medicines request received")
    user_id = get_jwt_identity()
    medicine_name, start_date, dosage = validate_medicine_filters(
        request.args.get("medicine_name"),
        request.args.get("start_date"),
        request.args.get("dosage"),
    )
    medicines = list_medicines(
        user_id,
        medicine_name=medicine_name,
        start_date=start_date,
        dosage=dosage,
    )
    return jsonify({"success": True, "data": medicines, "count": len(medicines)}), 200


@medicines_bp.get("/<medicine_id>")
@jwt_required()
def get_medicine_route(medicine_id: str):
    user_id = get_jwt_identity()
    medicine = get_medicine_detail(user_id, medicine_id)
    return jsonify({"success": True, "data": medicine}), 200


@medicines_bp.put("/<medicine_id>")
@jwt_required()
def update_medicine_route(medicine_id: str):
    user_id = get_jwt_identity()
    payload = validate_update_medicine_payload(request.get_json(silent=True))
    medicine = update_medicine(user_id, medicine_id, payload)
    return (
        jsonify(
            {
                "success": True,
                "message": "Medicine updated successfully",
                "data": medicine,
            }
        ),
        200,
    )


@medicines_bp.delete("/<medicine_id>")
@jwt_required()
def delete_medicine_route(medicine_id: str):
    user_id = get_jwt_identity()
    delete_medicine(user_id, medicine_id)
    return jsonify({"success": True, "message": "Medicine deleted successfully"}), 200
