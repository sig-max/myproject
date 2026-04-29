from datetime import datetime, timezone

from app.blueprints.users.models import get_user_by_id
from app.extensions import mongo
from app.utils.errors import APIError


def get_specialist_dashboard_analytics(current_user_id: str) -> dict:
    current_user = get_user_by_id(current_user_id)
    if not current_user or current_user.get("role") != "specialist":
        raise APIError("Only specialists can view analytics", status_code=403)

    specialist_object_id = current_user["_id"]
    now = datetime.now(timezone.utc)
    month_start = datetime(now.year, now.month, 1, tzinfo=timezone.utc)
    year_start = datetime(now.year, 1, 1, tzinfo=timezone.utc)

    appointments = list(
        mongo.db["appointments"].find({"specialist_user_id": specialist_object_id})
    )
    home_samples = list(
        mongo.db["home_sample_requests"].find(
            {
                "$or": [
                    {"specialist_user_id": specialist_object_id},
                    {"status": "pending"},
                ]
            }
        )
    )
    chat_threads = list(
        mongo.db["chat_threads"].find({"specialist_user_id": specialist_object_id})
    )
    chat_messages = list(
        mongo.db["chat_messages"].find(
            {
                "sender_user_id": specialist_object_id,
                "sender_role": "specialist",
            }
        )
    )

    patient_ids = {
        str(item["patient_user_id"])
        for item in appointments
    }
    patient_ids.update(
        str(item["patient_user_id"])
        for item in home_samples
        if item.get("specialist_user_id") == specialist_object_id
    )
    patient_ids.update(str(item["patient_user_id"]) for item in chat_threads)

    monthly_breakdown = _build_status_breakdown(
        appointments=appointments,
        home_samples=home_samples,
        chat_messages=chat_messages,
        range_start=month_start,
        specialist_object_id=specialist_object_id,
    )
    yearly_breakdown = _build_status_breakdown(
        appointments=appointments,
        home_samples=home_samples,
        chat_messages=chat_messages,
        range_start=year_start,
        specialist_object_id=specialist_object_id,
    )

    return {
        "summary": {
            "patients_consulted": len(patient_ids),
            "appointments_booked": len(appointments),
            "chat_threads": len(chat_threads),
            "pending_home_samples": sum(
                1 for item in home_samples if item.get("status") == "pending"
            ),
        },
        "line_chart": _build_line_chart(
            appointments=appointments,
            home_samples=home_samples,
            chat_messages=chat_messages,
            specialist_object_id=specialist_object_id,
        ),
        "monthly_breakdown": monthly_breakdown,
        "yearly_breakdown": yearly_breakdown,
    }


def _build_status_breakdown(
    *,
    appointments: list[dict],
    home_samples: list[dict],
    chat_messages: list[dict],
    range_start: datetime,
    specialist_object_id,
) -> dict:
    appointments_count = sum(
        1
        for item in appointments
        if item.get("created_at") and item["created_at"] >= range_start
    )
    follow_up_count = sum(
        1
        for item in chat_messages
        if item.get("created_at") and item["created_at"] >= range_start
    )
    tests_completed = sum(
        1
        for item in home_samples
        if item.get("specialist_user_id") == specialist_object_id
        and item.get("status") == "completed"
        and item.get("updated_at")
        and item["updated_at"] >= range_start
    )
    tests_pending = sum(
        1
        for item in home_samples
        if item.get("specialist_user_id") == specialist_object_id
        and item.get("status") in {"accepted", "pending"}
        and item.get("updated_at")
        and item["updated_at"] >= range_start
    )

    return {
        "appointments": appointments_count,
        "follow_ups": follow_up_count,
        "tests_completed": tests_completed,
        "tests_pending": tests_pending,
    }


def _build_line_chart(
    *,
    appointments: list[dict],
    home_samples: list[dict],
    chat_messages: list[dict],
    specialist_object_id,
) -> list[dict]:
    now = datetime.now(timezone.utc)
    points = []

    for month_offset in range(5, -1, -1):
        month_index = now.month - month_offset
        year = now.year
        while month_index <= 0:
            month_index += 12
            year -= 1

        appointment_count = sum(
            1
            for item in appointments
            if item.get("created_at")
            and item["created_at"].year == year
            and item["created_at"].month == month_index
        )
        follow_up_count = sum(
            1
            for item in chat_messages
            if item.get("created_at")
            and item["created_at"].year == year
            and item["created_at"].month == month_index
        )
        test_completed_count = sum(
            1
            for item in home_samples
            if item.get("specialist_user_id") == specialist_object_id
            and item.get("status") == "completed"
            and item.get("updated_at")
            and item["updated_at"].year == year
            and item["updated_at"].month == month_index
        )

        points.append(
            {
                "label": datetime(year, month_index, 1).strftime("%b"),
                "appointments": appointment_count,
                "follow_ups": follow_up_count,
                "tests_completed": test_completed_count,
                "progress_score": appointment_count
                + follow_up_count
                + test_completed_count,
            }
        )

    return points
