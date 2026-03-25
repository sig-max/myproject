import re

from app.utils.errors import ValidationError
from app.utils.validators import (
    validate_list,
    validate_number,
    validate_string,
)


ALLOWED_TIMES = {"morning", "afternoon", "evening", "night"}
HHMM_RE = re.compile(r"^([01]\d|2[0-3]):([0-5]\d)$")


def _validate_times_list(field_name: str, values) -> list[str]:
    validate_list(field_name, values)

    normalized: list[str] = []
    seen: set[str] = set()
    for item in values:
        validate_string(f"{field_name}[]", item, min_length=2, max_length=20)
        text = item.strip()
        key = text.lower()

        if key in ALLOWED_TIMES:
            normalized_value = key
        elif HHMM_RE.match(text):
            normalized_value = text
        else:
            raise ValidationError(
                f"{field_name} must contain only: morning, afternoon, evening, night (or HH:MM)"
            )

        if normalized_value not in seen:
            seen.add(normalized_value)
            normalized.append(normalized_value)

    if not normalized:
        raise ValidationError(f"{field_name} must have at least one value")

    return normalized


def validate_create_medicine_payload(data) -> dict:
    if not isinstance(data, dict):
        raise ValidationError("Request body must be a valid JSON object")

    # Support both new keys (name/stock/times) and legacy keys.
    name_value = data.get("name", data.get("medicine_name"))
    if name_value is None:
        raise ValidationError("Missing required fields", details={"missing": ["name"]})
    validate_string("name", name_value, min_length=2, max_length=120)

    if "dosage" not in data:
        raise ValidationError("Missing required fields", details={"missing": ["dosage"]})
    validate_string("dosage", data["dosage"], min_length=1, max_length=60)

    stock_value = data.get("stock", data.get("quantity"))
    if stock_value is None:
        raise ValidationError("Missing required fields", details={"missing": ["stock"]})
    validate_number("stock", stock_value, min_value=0)

    times_value = data.get("times", data.get("reminder_times"))
    if times_value is None:
        raise ValidationError("Missing required fields", details={"missing": ["times"]})
    normalized_times = _validate_times_list("times", times_value)

    data["name"] = str(name_value).strip()
    data["stock"] = int(stock_value)
    data["times"] = normalized_times

    if "category" in data and data["category"] is not None:
        validate_string("category", data["category"], min_length=2, max_length=60)
    if "notes" in data and data["notes"] is not None:
        validate_string("notes", data["notes"], min_length=1, max_length=1000)

    return data


def validate_update_medicine_payload(data) -> dict:
    if not isinstance(data, dict):
        raise ValidationError("Request body must be a valid JSON object")
    if not data:
        raise ValidationError("At least one field is required for update")

    allowed_fields = {
        "name",
        "stock",
        "times",
        "medicine_name",
        "category",
        "dosage",
        "quantity",
        "times_per_day",
        "start_date",
        "reminder_times",
        "notes",
    }
    unknown_fields = [field for field in data if field not in allowed_fields]
    if unknown_fields:
        raise ValidationError("Unknown fields in request", details={"fields": unknown_fields})

    if "medicine_name" in data:
        validate_string("medicine_name", data["medicine_name"], min_length=2, max_length=120)
        data["name"] = data["medicine_name"].strip()

    if "name" in data:
        validate_string("name", data["name"], min_length=2, max_length=120)
        data["name"] = data["name"].strip()

    return _validate_optional_fields(data)


def _validate_optional_fields(data: dict) -> dict:
    if "category" in data and data["category"] is not None:
        validate_string("category", data["category"], min_length=2, max_length=60)
    if "stock" in data:
        validate_number("stock", data["stock"], min_value=0)
        data["stock"] = int(data["stock"])

    if "dosage" in data and data["dosage"] is not None:
        validate_string("dosage", data["dosage"], min_length=1, max_length=60)

    if "quantity" in data:
        validate_number("quantity", data["quantity"], min_value=0)
        data["stock"] = int(data["quantity"])

    if "times" in data:
        data["times"] = _validate_times_list("times", data["times"])

    if "times_per_day" in data:
        validate_number("times_per_day", data["times_per_day"], min_value=1)

    if "start_date" in data and data["start_date"] is not None:
        validate_string("start_date", data["start_date"], min_length=10, max_length=30)

    if "reminder_times" in data:
        data["times"] = _validate_times_list("reminder_times", data["reminder_times"])

    if "notes" in data and data["notes"] is not None:
        validate_string("notes", data["notes"], min_length=1, max_length=1000)
    return data


def validate_search_query(value: str | None) -> str | None:
    if value is None:
        return None
    validate_string("medicine_name", value, min_length=1, max_length=120)
    return value.strip()


def validate_medicine_filters(
    medicine_name: str | None,
    start_date: str | None,
    dosage: str | None,
) -> tuple[str | None, str | None, str | None]:
    parsed_name = validate_search_query(medicine_name)

    parsed_start_date = None
    if start_date is not None:
        validate_string("start_date", start_date, min_length=10, max_length=30)
        parsed_start_date = start_date.strip()

    parsed_dosage = None
    if dosage is not None:
        validate_string("dosage", dosage, min_length=1, max_length=60)
        parsed_dosage = dosage.strip()

    return parsed_name, parsed_start_date, parsed_dosage
