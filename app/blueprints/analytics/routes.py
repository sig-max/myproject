from flask import Blueprint, jsonify
from flask_jwt_extended import get_jwt_identity, jwt_required

from app.blueprints.analytics.services import get_specialist_dashboard_analytics


analytics_bp = Blueprint("analytics", __name__)


@analytics_bp.get("/specialist/me")
@jwt_required()
def get_specialist_analytics():
    current_user_id = get_jwt_identity()
    data = get_specialist_dashboard_analytics(current_user_id)
    return jsonify(data), 200
