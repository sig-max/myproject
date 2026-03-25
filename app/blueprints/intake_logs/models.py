from datetime import date, datetime, time, timedelta, timezone

from app.extensions import mongo


INTAKE_LOGS_COLLECTION = "intake_logs"


def _get_day_bounds(target_date: date) -> tuple[datetime, datetime]:
    day_start = datetime.combine(target_date, time.min, tzinfo=timezone.utc)
    next_day = day_start + timedelta(days=1)
    return day_start, next_day


def build_intake_log_document(user_id: str, payload: dict) -> dict:
    now = datetime.now(timezone.utc)
    target_date = payload.get("date", now.date())
    day_start, _ = _get_day_bounds(target_date)
    return {
        "user_id": user_id,
        "medicine_id": payload["medicine_id"],
        "date": day_start,
        "taken": payload.get("taken", True),
        "time_taken": payload.get("time_taken", now if payload.get("taken", True) else None),
        "created_at": now,
    }


def create_intake_log(user_id: str, payload: dict) -> dict:
    doc = build_intake_log_document(user_id, payload)
    result = mongo.db[INTAKE_LOGS_COLLECTION].insert_one(doc)
    return mongo.db[INTAKE_LOGS_COLLECTION].find_one({"_id": result.inserted_id})


def get_daily_logs(user_id: str, target_date: date | None = None):
    if target_date is None:
        return mongo.db[INTAKE_LOGS_COLLECTION].find({"user_id": user_id}).sort("created_at", -1)

    day_start, next_day = _get_day_bounds(target_date)
    return mongo.db[INTAKE_LOGS_COLLECTION].find(
        {"user_id": user_id, "date": {"$gte": day_start, "$lt": next_day}}
    ).sort("created_at", -1)


def get_log_for_medicine_date(user_id: str, medicine_id: str, target_date: date) -> dict | None:
    day_start, next_day = _get_day_bounds(target_date)
    return mongo.db[INTAKE_LOGS_COLLECTION].find_one(
        {
            "user_id": user_id,
            "medicine_id": medicine_id,
            "date": {"$gte": day_start, "$lt": next_day},
        }
    )


def get_user_logs(user_id: str):
    return mongo.db[INTAKE_LOGS_COLLECTION].find({"user_id": user_id}).sort(
        [("date", -1), ("created_at", -1)]
    )


def get_user_logs_filtered(
    user_id: str,
    from_date: datetime | None = None,
    to_date: datetime | None = None,
    medicine_id: str | None = None,
):
    match_query = {"user_id": user_id}

    if medicine_id:
        match_query["medicine_id"] = medicine_id

    if from_date or to_date:
        date_query = {}
        if from_date:
            date_query["$gte"] = from_date
        if to_date:
            date_query["$lte"] = to_date
        match_query["date"] = date_query

    pipeline = [
        {"$match": match_query},
        {"$sort": {"date": -1, "created_at": -1}},
    ]
    return mongo.db[INTAKE_LOGS_COLLECTION].aggregate(pipeline)
