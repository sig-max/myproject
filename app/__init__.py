from flask import Flask, jsonify, request
from flask_cors import CORS
from pymongo.errors import PyMongoError
from pymongo.uri_parser import parse_uri
from urllib.parse import parse_qsl, urlencode

from app.config import config_by_name
from app.extensions import bcrypt, initialize_indexes, jwt, mongo
from app.routes import register_blueprints, register_core_routes
from app.utils.errors import register_error_handlers

def _ensure_mongo_uri_has_database(mongo_uri: str, database_name: str) -> str:
    if not mongo_uri or not database_name:
        return mongo_uri

    try:
        parsed = parse_uri(mongo_uri)
    except Exception:
        return mongo_uri

    if parsed.get("database"):
        return mongo_uri

    if "?" in mongo_uri:
        base_uri, query = mongo_uri.split("?", 1)
        return f"{base_uri.rstrip('/')}/{database_name}?{query}"

    return f"{mongo_uri.rstrip('/')}/{database_name}"


def _ensure_mongo_uri_timeout_options(mongo_uri: str) -> str:
    """Apply sensible timeout defaults so DB outages fail fast instead of hanging requests."""
    if not mongo_uri:
        return mongo_uri

    if "?" in mongo_uri:
        base_uri, query = mongo_uri.split("?", 1)
    else:
        base_uri, query = mongo_uri, ""

    params = dict(parse_qsl(query, keep_blank_values=True))
    params.setdefault("serverSelectionTimeoutMS", "5000")
    params.setdefault("connectTimeoutMS", "5000")
    params.setdefault("socketTimeoutMS", "10000")

    return f"{base_uri}?{urlencode(params)}"


def create_app(config_name: str | None = None) -> Flask:
    app = Flask(__name__)
    CORS(app, resources={r"/api/*": {"origins": "*"}})
    app.config["MONGO_INIT_ERROR"] = None

    selected_config = config_name or "default"
    app.config.from_object(config_by_name[selected_config])

    if not app.config.get("MONGO_URI"):
        raise RuntimeError("MONGO_URI is required. Set it in your environment variables.")

    app.config["MONGO_URI"] = _ensure_mongo_uri_has_database(
        app.config["MONGO_URI"],
        app.config.get("MONGO_DB_NAME", "medical_store"),
    )
    app.config["MONGO_URI"] = _ensure_mongo_uri_timeout_options(app.config["MONGO_URI"])

    try:
        mongo.init_app(app)
    except Exception as exc:
        app.config["MONGO_INIT_ERROR"] = str(exc)
        print(f"Mongo initialization failed: {exc}")
    jwt.init_app(app)
    bcrypt.init_app(app)

    if app.config["MONGO_INIT_ERROR"] is None:
        with app.app_context():
            try:
                initialize_indexes()
            except PyMongoError as exc:
                # Keep API booting so health/CORS/diagnostics are still available
                # even if Atlas is temporarily unreachable.
                app.config["MONGO_INIT_ERROR"] = str(exc)
                print(f"Mongo index initialization skipped: {exc}")

    register_core_routes(app)
    register_blueprints(app)
    register_error_handlers(app)

    @app.before_request
    def fail_fast_when_db_unavailable():
        if app.config.get("MONGO_INIT_ERROR") and request.path.startswith("/api/"):
            return (
                jsonify(
                    {
                        "error": "Database unavailable",
                        "details": app.config["MONGO_INIT_ERROR"],
                    }
                ),
                503,
            )

    return app
