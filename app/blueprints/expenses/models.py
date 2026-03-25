from datetime import datetime, timezone
from typing import Any, cast

from pymongo.collection import Collection

from app.extensions import mongo


EXPENSES_COLLECTION = "expenses"


def _expenses_collection() -> Collection:
    db = mongo.db
    if db is None:
        raise RuntimeError("MongoDB is not initialized")
    return db[EXPENSES_COLLECTION]


def build_expense_document(user_id: str, payload: dict) -> dict:
    now = datetime.now(timezone.utc)

    return {
        "user_id": user_id,
        "title": payload["title"].strip(),
        "amount": float(payload["amount"]),
        "category": payload.get("category"),
        "date": payload["date"],
        "notes": payload.get("notes"),
        "created_at": now,
    }


def create_expense(user_id: str, payload: dict) -> dict:
    doc = build_expense_document(user_id, payload)
    collection = _expenses_collection()
    result = collection.insert_one(doc)
    created_expense = collection.find_one({"_id": result.inserted_id})
    if created_expense is None:
        raise RuntimeError("Created expense document could not be retrieved")
    return cast(dict, created_expense)


def get_user_expenses(
    user_id: str,
    from_date: datetime | None = None,
    to_date: datetime | None = None,
    month_start: datetime | None = None,
    month_end: datetime | None = None,
):
    match_query: dict[str, Any] = {"user_id": user_id}
    date_filter: dict[str, datetime] = {}

    if month_start and month_end:
        date_filter.update({"$gte": month_start, "$lte": month_end})
    else:
        if from_date:
            date_filter["$gte"] = from_date
        if to_date:
            date_filter["$lte"] = to_date

    if date_filter:
        match_query["date"] = date_filter

    pipeline = [
        {"$match": match_query},
        {"$sort": {"date": -1}},
    ]

    return _expenses_collection().aggregate(pipeline)


def get_monthly_total(user_id: str, year: int, month: int) -> float:
    pipeline = [
        {
            "$match": {
                "user_id": user_id,
                "$expr": {
                    "$and": [
                        {"$eq": [{"$year": "$date"}, year]},
                        {"$eq": [{"$month": "$date"}, month]},
                    ]
                },
            }
        },
        {"$group": {"_id": None, "total": {"$sum": "$amount"}}},
    ]

    result = list(_expenses_collection().aggregate(pipeline))
    return float(result[0]["total"]) if result else 0.0


def get_yearly_total(user_id: str, year: int) -> float:
    pipeline = [
        {
            "$match": {
                "user_id": user_id,
                "$expr": {"$eq": [{"$year": "$date"}, year]},
            }
        },
        {"$group": {"_id": None, "total": {"$sum": "$amount"}}},
    ]

    result = list(_expenses_collection().aggregate(pipeline))
    return float(result[0]["total"]) if result else 0.0


def get_top_medicines(user_id: str, year: int, limit: int = 5) -> list[dict]:
    pipeline = [
        {
            "$match": {
                "user_id": user_id,
                "$expr": {"$eq": [{"$year": "$date"}, year]},
            }
        },
        {
            "$group": {
                "_id": "$title",
                "total_spent": {"$sum": "$amount"},
                "purchase_count": {"$sum": 1},
            }
        },
        {"$sort": {"total_spent": -1}},
        {"$limit": limit},
    ]

    result = list(_expenses_collection().aggregate(pipeline))

    return [
        {
            "title": item["_id"],
            "total_spent": float(item["total_spent"]),
            "purchase_count": int(item["purchase_count"]),
        }
        for item in result
    ]