from flask import Flask, jsonify
from pymongo.errors import PyMongoError


class APIError(Exception):
    def __init__(self, message: str, status_code: int = 400, details=None):
        super().__init__(message)
        self.message = message
        self.status_code = status_code
        self.details = details


class ValidationError(APIError):
    def __init__(self, message: str = "Invalid request data", details=None):
        super().__init__(message=message, status_code=400, details=details)


class NotFoundError(APIError):
    def __init__(self, message: str = "Resource not found"):
        super().__init__(message=message, status_code=404)


def register_error_handlers(app: Flask) -> None:
    @app.errorhandler(APIError)
    def handle_api_error(error: APIError):
        payload = {"error": error.message}
        if error.details is not None:
            payload["details"] = error.details
        return jsonify(payload), error.status_code

    @app.errorhandler(PyMongoError)
    def handle_database_error(error: PyMongoError):
        return jsonify({"error": "Database operation failed", "details": str(error)}), 503

    @app.errorhandler(404)
    def handle_not_found(_):
        return jsonify({"error": "Endpoint not found"}), 404

    @app.errorhandler(Exception)
    def handle_unexpected(error: Exception):
        return jsonify({"error": "Internal server error", "details": str(error)}), 500
