from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required

from app.blueprints.intake_logs.schemas import (
    validate_create_intake_log_payload,
    validate_history_filters,
)
from app.blueprints.intake_logs.services import (
    create_intake_log,
    get_history_checkbook,
    get_today_checkbook,
)


intake_logs_bp = Blueprint("intake_logs", __name__)


@intake_logs_bp.post("")
@jwt_required()
def create_intake_log_route():
    user_id = get_jwt_identity()
    payload = validate_create_intake_log_payload(request.get_json(silent=True))
    intake_log = create_intake_log(user_id, payload)
    return (
        jsonify(
            {
                "success": True,
                "message": "Intake log created successfully",
                "data": intake_log,
            }
        ),
        201,
    )


@intake_logs_bp.get("/today")
@jwt_required()
def get_today_checkbook_route():
    user_id = get_jwt_identity()
    data = get_today_checkbook(user_id)
    return jsonify({"success": True, "data": data}), 200


@intake_logs_bp.get("/history")
@jwt_required()
def get_history_checkbook_route():
    user_id = get_jwt_identity()
    from_date, to_date, medicine_id = validate_history_filters(
        request.args.get("from_date"),
        request.args.get("to_date"),
        request.args.get("medicine_id"),
    )
    data = get_history_checkbook(
        user_id,
        from_date=from_date,
        to_date=to_date,
        medicine_id=medicine_id,
    )
    return jsonify({"success": True, "data": data}), 200
