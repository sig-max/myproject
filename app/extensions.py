from flask_bcrypt import Bcrypt
from flask_jwt_extended import JWTManager
from flask_pymongo import PyMongo
from pymongo.errors import OperationFailure

mongo = PyMongo()
jwt = JWTManager()
bcrypt = Bcrypt()


def init_extensions(app):
    mongo.init_app(app)
    jwt.init_app(app)
    bcrypt.init_app(app)


def initialize_indexes() -> None:
    """Create indexes used by the application if a DB connection is available."""
    db = mongo.db
    if db is None:
        return

    users_indexes = db["users"].index_information()
    has_unique_email_index = any(
        index.get("key") == [("email", 1)] and index.get("unique") is True
        for index in users_indexes.values()
    )
    if not has_unique_email_index:
        _safe_create_index(db["users"], [("email", 1)], unique=True, name="users_email_unique_idx")
    _safe_create_index(
        db["patient_profiles"],
        [("user_id", 1)],
        unique=True,
        name="patient_profiles_user_unique_idx",
    )
    _safe_create_index(
        db["specialist_profiles"],
        [("user_id", 1)],
        unique=True,
        name="specialist_profiles_user_unique_idx",
    )

    _safe_create_index(
        db["medicines"],
        [("user_id", 1), ("created_at", -1)],
        name="medicines_user_created_idx",
    )
    _safe_create_index(
        db["intake_logs"],
        [("user_id", 1), ("date", -1)],
        name="intake_logs_user_date_idx",
    )
    _safe_create_index(
        db["expenses"],
        [("user_id", 1), ("date", -1)],
        name="expenses_user_date_idx",
    )
    _safe_create_index(
        db["appointment_slots"],
        [("specialist_user_id", 1), ("start_at", 1)],
        name="appointment_slots_specialist_start_idx",
    )
    _safe_create_index(
        db["appointments"],
        [("specialist_user_id", 1), ("created_at", -1)],
        name="appointments_specialist_created_idx",
    )
    _safe_create_index(
        db["appointments"],
        [("patient_user_id", 1), ("created_at", -1)],
        name="appointments_patient_created_idx",
    )
    _safe_create_index(
        db["appointments"],
        [("status", 1), ("auto_accept_at", 1)],
        name="appointments_status_auto_accept_idx",
    )
    _safe_create_index(
        db["home_sample_requests"],
        [("patient_user_id", 1), ("created_at", -1)],
        name="home_sample_requests_patient_created_idx",
    )
    _safe_create_index(
        db["home_sample_requests"],
        [("specialist_user_id", 1), ("created_at", -1)],
        name="home_sample_requests_specialist_created_idx",
    )
    _safe_create_index(
        db["home_sample_requests"],
        [("status", 1), ("created_at", -1)],
        name="home_sample_requests_status_created_idx",
    )
    _safe_create_index(
        db["chat_threads"],
        [("patient_user_id", 1), ("specialist_user_id", 1)],
        unique=True,
        name="chat_threads_patient_specialist_unique_idx",
    )
    _safe_create_index(
        db["chat_threads"],
        [("updated_at", -1)],
        name="chat_threads_updated_idx",
    )
    _safe_create_index(
        db["chat_messages"],
        [("thread_id", 1), ("created_at", 1)],
        name="chat_messages_thread_created_idx",
    )


def _safe_create_index(collection, keys, **kwargs) -> None:
    """Create index without failing app startup on existing equivalent/conflicting indexes."""
    try:
        collection.create_index(keys, **kwargs)
    except OperationFailure as exc:
        # Atlas may already have the same index with another name/options.
        if exc.code in {68, 85, 86}:
            return
        raise
