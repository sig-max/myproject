from datetime import datetime, timedelta, timezone

from app.blueprints.expenses.models import (
    create_expense as create_expense_model,
    get_monthly_total,
    get_top_medicines,
    get_user_expenses,
    get_yearly_total,
)
from app.utils.helpers import serialize_document


def create_expense(user_id: str, payload: dict) -> dict:
    payload = {**payload, "date": _parse_iso_date(payload["date"], end_of_day=False)}
    expense = create_expense_model(user_id, payload)
    return serialize_document(expense)


def list_expenses(user_id: str, from_date: str | None = None, to_date: str | None = None) -> list[dict]:
    from_date_obj = _parse_iso_date(from_date, end_of_day=False) if from_date else None
    to_date_obj = _parse_iso_date(to_date, end_of_day=True) if to_date else None
    cursor = get_user_expenses(user_id, from_date=from_date_obj, to_date=to_date_obj)
    return [serialize_document(item) for item in cursor]


def list_expenses_with_month(
    user_id: str,
    from_date: str | None = None,
    to_date: str | None = None,
    month: str | None = None,
) -> list[dict]:
    from_date_obj = _parse_iso_date(from_date, end_of_day=False) if from_date else None
    to_date_obj = _parse_iso_date(to_date, end_of_day=True) if to_date else None
    month_start, month_end = _parse_month_range(month) if month else (None, None)

    cursor = get_user_expenses(
        user_id,
        from_date=from_date_obj,
        to_date=to_date_obj,
        month_start=month_start,
        month_end=month_end,
    )
    return [serialize_document(item) for item in cursor]


def get_expense_summary(user_id: str, year: int | None = None, month: int | None = None) -> dict:
    now = datetime.now(timezone.utc)
    selected_year = year or now.year
    selected_month = month or now.month

    monthly_total = get_monthly_total(user_id, selected_year, selected_month)
    yearly_total = get_yearly_total(user_id, selected_year)
    top_medicines = get_top_medicines(user_id, selected_year)

    return {
        "monthly_total": monthly_total,
        "yearly_total": yearly_total,
        "top_medicines": top_medicines,
    }


def _parse_iso_date(date_text: str, end_of_day: bool) -> datetime:
    parsed = datetime.strptime(date_text, "%Y-%m-%d")
    if end_of_day:
        parsed = parsed.replace(hour=23, minute=59, second=59, microsecond=999999)
    return parsed.replace(tzinfo=timezone.utc)


def _parse_month_range(month_text: str) -> tuple[datetime, datetime]:
    parsed = datetime.strptime(month_text, "%Y-%m")
    month_start = parsed.replace(day=1, hour=0, minute=0, second=0, microsecond=0, tzinfo=timezone.utc)

    if month_start.month == 12:
        next_month = month_start.replace(year=month_start.year + 1, month=1)
    else:
        next_month = month_start.replace(month=month_start.month + 1)

    month_end = next_month - timedelta(microseconds=1)
    return month_start, month_end
