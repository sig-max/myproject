from flask import Flask, jsonify
from flask_jwt_extended import JWTManager

from app.blueprints.appointments.routes import appointments_bp
from app.blueprints.auth.routes import auth_bp
from app.blueprints.expenses.routes import expenses_bp
from app.blueprints.intake_logs.routes import intake_logs_bp
from app.blueprints.medicines.routes import medicines_bp
from app.blueprints.reminders.routes import reminders_bp
from app.blueprints.users.routes import users_bp
from app.extensions import jwt


def register_core_routes(app: Flask) -> None:
    @app.get("/health")
    def health_check():
        return jsonify({"status": "ok", "service": "medical-management-api"}), 200

    _register_jwt_callbacks(jwt)


def register_blueprints(app: Flask) -> None:
    app.register_blueprint(auth_bp, url_prefix="/api/v1/auth")
    app.register_blueprint(users_bp, url_prefix="/api/v1/users")
    app.register_blueprint(appointments_bp, url_prefix="/api/v1/appointments")
    app.register_blueprint(medicines_bp, url_prefix="/api/v1/medicines")
    app.register_blueprint(reminders_bp, url_prefix="/api/v1/reminders")
    app.register_blueprint(intake_logs_bp, url_prefix="/api/v1/intake-logs")
    app.register_blueprint(expenses_bp, url_prefix="/api/v1/expenses")


def _register_jwt_callbacks(jwt_manager: JWTManager) -> None:
    @jwt_manager.unauthorized_loader
    def unauthorized_callback(message: str):
        return jsonify({"error": "Authorization required", "details": message}), 401

    @jwt_manager.invalid_token_loader
    def invalid_token_callback(message: str):
        return jsonify({"error": "Invalid token", "details": message}), 422

    @jwt_manager.expired_token_loader
    def expired_token_callback(jwt_header, jwt_payload):
        return jsonify({"error": "Token expired"}), 401
