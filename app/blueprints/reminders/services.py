from app.blueprints.reminders.models import (
    create_reminder as create_reminder_model,
    delete_reminder as delete_reminder_model,
    get_reminders,
)
from app.blueprints.medicines.models import get_medicine_by_id
from app.utils.errors import NotFoundError
from app.utils.helpers import serialize_document


def create_reminder(user_id: str, payload: dict) -> dict:
    medicine = get_medicine_by_id(user_id, payload["medicine_id"])
    if not medicine:
        raise NotFoundError("Medicine not found")

    reminder_times = payload.get("reminder_times")
    if reminder_times:
        created = []
        for reminder_time in reminder_times:
            reminder = create_reminder_model(
                user_id,
                {
                    "medicine_id": payload["medicine_id"],
                    "reminder_time": reminder_time,
                    "repeat_type": payload.get("repeat_type", "daily"),
                    "is_active": payload.get("is_active", True),
                },
            )
            created.append(_serialize_for_flutter(reminder, medicine_name=medicine["medicine_name"]))

        return {
            "medicine_id": payload["medicine_id"],
            "medicine_name": medicine["medicine_name"],
            "created_count": len(created),
            "items": created,
        }

    reminder = create_reminder_model(user_id, payload)
    return _serialize_for_flutter(reminder, medicine_name=medicine["medicine_name"])


def list_reminders(user_id: str, medicine_id: str | None = None) -> dict:
    cursor = get_reminders(user_id, medicine_id=medicine_id)

    items = []
    for reminder in cursor:
        medicine = get_medicine_by_id(user_id, reminder["medicine_id"])
        items.append(
            _serialize_for_flutter(
                reminder,
                medicine_name=medicine["medicine_name"] if medicine else None,
            )
        )

    return {
        "count": len(items),
        "items": items,
    }


def delete_reminder(user_id: str, reminder_id: str) -> None:
    deleted_count = delete_reminder_model(user_id, reminder_id)
    if deleted_count == 0:
        raise NotFoundError("Reminder not found")


def _serialize_for_flutter(reminder: dict, medicine_name: str | None) -> dict:
    payload = serialize_document(reminder)
    payload["medicine_name"] = medicine_name
    payload["notification_key"] = f"{payload['medicine_id']}:{payload['reminder_time']}"
    return payload
