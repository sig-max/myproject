from datetime import date, datetime, timezone

from app.blueprints.intake_logs.models import (
    create_intake_log as create_intake_log_model,
    get_daily_logs,
    get_log_for_medicine_date,
    get_user_logs_filtered,
)
from app.blueprints.medicines.models import get_medicine_by_id, get_user_medicines
from app.utils.errors import APIError, NotFoundError, ValidationError
from app.utils.helpers import serialize_document


def create_intake_log(user_id: str, payload: dict) -> dict:
    medicine_id = payload["medicine_id"]
    target_date = _parse_target_date(payload.get("date"))
    medicine = get_medicine_by_id(user_id, medicine_id)
    if not medicine:
        raise NotFoundError("Medicine not found")

    existing_log = get_log_for_medicine_date(user_id, medicine_id, target_date)
    if existing_log:
        raise APIError("Intake already logged for this medicine on this date", status_code=409)

    taken = payload.get("taken", True)
    time_taken = _parse_time_taken(payload.get("time_taken"), taken)
    intake_log = create_intake_log_model(
        user_id,
        {
            "medicine_id": medicine_id,
            "date": target_date,
            "taken": taken,
            "time_taken": time_taken,
        },
    )
    return serialize_document(intake_log)


def get_today_checkbook(user_id: str) -> dict:
    today = datetime.now(timezone.utc).date()
    medicines = list(get_user_medicines(user_id))
    logs = list(get_daily_logs(user_id, today))
    return _build_daily_snapshot(today, medicines, logs)


def get_history_checkbook(
    user_id: str,
    from_date: str | None = None,
    to_date: str | None = None,
    medicine_id: str | None = None,
) -> dict:
    medicines = list(get_user_medicines(user_id))
    if medicine_id:
        medicines = [medicine for medicine in medicines if str(medicine["_id"]) == medicine_id]

    from_date_obj = _parse_history_date(from_date, end_of_day=False) if from_date else None
    to_date_obj = _parse_history_date(to_date, end_of_day=True) if to_date else None

    logs = list(
        get_user_logs_filtered(
            user_id,
            from_date=from_date_obj,
            to_date=to_date_obj,
            medicine_id=medicine_id,
        )
    )

    logs_by_date: dict[str, list[dict]] = {}
    for log in logs:
        date_key = log["date"].date().isoformat()
        logs_by_date.setdefault(date_key, []).append(log)

    history = []
    for date_key in sorted(logs_by_date.keys(), reverse=True):
        target_date = date.fromisoformat(date_key)
        history.append(_build_daily_snapshot(target_date, medicines, logs_by_date[date_key]))

    return {"history": history, "total_days": len(history)}


def _build_daily_snapshot(target_date: date, medicines: list[dict], logs: list[dict]) -> dict:
    logs_by_medicine = {log["medicine_id"]: log for log in logs}

    medicine_items = []
    taken_count = 0
    for medicine in medicines:
        medicine_id = str(medicine["_id"])
        log_entry = logs_by_medicine.get(medicine_id)
        taken = bool(log_entry and log_entry.get("taken"))
        if taken:
            taken_count += 1

        medicine_items.append(
            {
                "medicine_name": medicine.get("name", medicine.get("medicine_name", "")),
                "taken": taken,
            }
        )

    total = len(medicines)
    consistency = round((taken_count / total) * 100) if total else 0

    return {
        "date": target_date.isoformat(),
        "consistency": consistency,
        "medicines": medicine_items,
    }


def _parse_target_date(raw_date: str | None) -> date:
    if raw_date is None:
        return datetime.now(timezone.utc).date()
    try:
        return date.fromisoformat(raw_date)
    except ValueError as exc:
        raise ValidationError("date must be in YYYY-MM-DD format") from exc


def _parse_time_taken(raw_time: str | None, taken: bool) -> datetime | None:
    if not taken:
        return None
    if raw_time is None:
        return datetime.now(timezone.utc)

    normalized = raw_time.replace("Z", "+00:00")
    try:
        parsed = datetime.fromisoformat(normalized)
        return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)
    except ValueError as exc:
        raise ValidationError("time_taken must be a valid ISO datetime") from exc


def _parse_history_date(raw_date: str, end_of_day: bool) -> datetime:
    parsed = datetime.strptime(raw_date, "%Y-%m-%d")
    if end_of_day:
        parsed = parsed.replace(hour=23, minute=59, second=59, microsecond=999999)
    return parsed.replace(tzinfo=timezone.utc)
