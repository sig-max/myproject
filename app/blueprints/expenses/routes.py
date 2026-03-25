from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required

from app.blueprints.expenses.schemas import (
    validate_create_expense_payload,
    validate_expense_filters,
    validate_month_filter,
    validate_summary_filters,
)
from app.blueprints.expenses.services import (
    create_expense,
    get_expense_summary,
    list_expenses_with_month,
)


expenses_bp = Blueprint("expenses", __name__)


@expenses_bp.post("")
@jwt_required()
def create_expense_route():
    user_id = get_jwt_identity()
    payload = validate_create_expense_payload(request.get_json(silent=True))
    expense = create_expense(user_id, payload)
    return (
        jsonify(
            {
                "success": True,
                "message": "Expense created successfully",
                "data": expense,
            }
        ),
        201,
    )


@expenses_bp.get("")
@jwt_required()
def list_expenses_route():
    user_id = get_jwt_identity()
    from_date, to_date = validate_expense_filters(
        request.args.get("from_date"),
        request.args.get("to_date"),
    )
    month = validate_month_filter(request.args.get("month"))
    expenses = list_expenses_with_month(user_id, from_date=from_date, to_date=to_date, month=month)
    return jsonify({"success": True, "data": {"items": expenses, "count": len(expenses)}}), 200


@expenses_bp.get("/summary")
@jwt_required()
def expenses_summary_route():
    user_id = get_jwt_identity()
    year, month = validate_summary_filters(
        request.args.get("year"),
        request.args.get("month"),
    )
    summary = get_expense_summary(user_id, year=year, month=month)
    return jsonify(summary), 200
