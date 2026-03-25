# Medical Management Backend API Guide

Developer-facing API documentation for frontend integration.

## Base URL

- Local: `http://localhost:5000`

## Authentication

- Auth type: JWT Bearer token
- Header format:

```http
Authorization: Bearer <token>
```

- Token is returned by `POST /api/v1/auth/login`.

## Standard Notes

- Content type for JSON requests:

```http
Content-Type: application/json
```

- Dates used in filters are `YYYY-MM-DD`.
- IDs are MongoDB ObjectId strings.

---

## Health

### 1) Health Check

- Endpoint: `/health`
- Method: `GET`
- Auth required: `No`
- Request body: `None`

Response example:

```json
{
  "status": "ok",
  "service": "medical-management-api"
}
```

---

## Auth APIs

### 2) Register User

- Endpoint: `/api/v1/auth/register`
- Method: `POST`
- Auth required: `No`
- Request body:

```json
{
  "name": "Aditi Sharma",
  "email": "aditi@example.com",
  "password": "StrongPass123"
}
```

Response example (`201`):

```json
{
  "message": "User registered successfully",
  "user": {
    "id": "65f0a1a2b3c4d5e6f7080910",
    "name": "Aditi Sharma",
    "email": "aditi@example.com",
    "created_at": "2026-03-07T10:00:00+00:00",
    "updated_at": "2026-03-07T10:00:00+00:00"
  }
}
```

### 3) Login

- Endpoint: `/api/v1/auth/login`
- Method: `POST`
- Auth required: `No`
- Request body:

```json
{
  "email": "aditi@example.com",
  "password": "StrongPass123"
}
```

Response example (`200`):

```json
{
  "token": "<jwt_access_token>",
  "user": {
    "id": "65f0a1a2b3c4d5e6f7080910",
    "name": "Aditi Sharma",
    "email": "aditi@example.com",
    "created_at": "2026-03-07T10:00:00+00:00",
    "updated_at": "2026-03-07T10:00:00+00:00"
  }
}
```

---

## Users APIs

### 4) Get Current User Profile

- Endpoint: `/api/users/me`
- Method: `GET`
- Auth required: `Yes`
- Request body: `None`

Response example (`200`):

```json
{
  "id": "65f0a1a2b3c4d5e6f7080910",
  "name": "Aditi Sharma",
  "email": "aditi@example.com",
  "phone": "+91-9999999999",
  "created_at": "2026-03-07T10:00:00+00:00",
  "updated_at": "2026-03-08T09:10:00+00:00"
}
```

### 5) Update Current User Profile

- Endpoint: `/api/users/me`
- Method: `PUT`
- Auth required: `Yes`
- Request body (any one field required):

```json
{
  "full_name": "Aditi S.",
  "phone": "+91-9999999999"
}
```

Response example (`200`):

```json
{
  "message": "Profile updated successfully",
  "user": {
    "id": "65f0a1a2b3c4d5e6f7080910",
    "name": "Aditi S.",
    "email": "aditi@example.com",
    "phone": "+91-9999999999",
    "created_at": "2026-03-07T10:00:00+00:00",
    "updated_at": "2026-03-08T09:30:00+00:00"
  }
}
```

---

## Medicines APIs

### 6) Create Medicine

- Endpoint: `/api/v1/medicines`
- Method: `POST`
- Auth required: `Yes`
- Request body:

```json
{
  "medicine_name": "Paracetamol",
  "dosage": "500mg",
  "quantity": 30,
  "start_date": "2026-03-01",
  "reminder_times": ["08:00", "20:00"],
  "times_per_day": 2,
  "category": "Fever",
  "notes": "After food"
}
```

Response example (`201`):

```json
{
  "success": true,
  "message": "Medicine created successfully",
  "data": {
    "id": "65f0a1a2b3c4d5e6f7080920",
    "user_id": "65f0a1a2b3c4d5e6f7080910",
    "medicine_name": "Paracetamol",
    "dosage": "500mg",
    "quantity": 30,
    "start_date": "2026-03-01",
    "reminder_times": ["08:00", "20:00"],
    "times_per_day": 2,
    "category": "Fever",
    "notes": "After food",
    "created_at": "2026-03-08T10:00:00+00:00",
    "updated_at": "2026-03-08T10:00:00+00:00"
  }
}
```

### 7) List Medicines (Advanced Filters)

- Endpoint: `/api/v1/medicines`
- Method: `GET`
- Auth required: `Yes`
- Request body: `None`
- Query params (all optional):
  - `medicine_name`: string search (case-insensitive)
  - `start_date`: exact match
  - `dosage`: exact match

Example request:

```http
GET /api/v1/medicines?medicine_name=para&start_date=2026-03-01&dosage=500mg
```

Response example (`200`):

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "65f0a1a2b3c4d5e6f7080920",
        "user_id": "65f0a1a2b3c4d5e6f7080910",
        "medicine_name": "Paracetamol",
        "dosage": "500mg",
        "quantity": 30,
        "start_date": "2026-03-01",
        "reminder_times": ["08:00", "20:00"]
      }
    ],
    "count": 1
  }
}
```

### 8) Get Medicine Detail

- Endpoint: `/api/v1/medicines/<medicine_id>`
- Method: `GET`
- Auth required: `Yes`
- Request body: `None`

Response example (`200`):

```json
{
  "success": true,
  "data": {
    "id": "65f0a1a2b3c4d5e6f7080920",
    "medicine_name": "Paracetamol",
    "dosage": "500mg",
    "quantity": 30,
    "start_date": "2026-03-01",
    "reminder_times": ["08:00", "20:00"]
  }
}
```

### 9) Update Medicine

- Endpoint: `/api/v1/medicines/<medicine_id>`
- Method: `PUT`
- Auth required: `Yes`
- Request body (any updatable field):

```json
{
  "quantity": 20,
  "notes": "Updated stock"
}
```

Response example (`200`):

```json
{
  "success": true,
  "message": "Medicine updated successfully",
  "data": {
    "id": "65f0a1a2b3c4d5e6f7080920",
    "quantity": 20,
    "notes": "Updated stock"
  }
}
```

### 10) Delete Medicine

- Endpoint: `/api/v1/medicines/<medicine_id>`
- Method: `DELETE`
- Auth required: `Yes`
- Request body: `None`

Response example (`200`):

```json
{
  "success": true,
  "message": "Medicine deleted successfully"
}
```

---

## Reminders APIs

### 11) Create Reminder (Single or Multiple Times)

- Endpoint: `/api/v1/reminders`
- Method: `POST`
- Auth required: `Yes`
- Request body (single time):

```json
{
  "medicine_id": "65f0a1a2b3c4d5e6f7080920",
  "reminder_time": "08:00",
  "repeat_type": "daily",
  "is_active": true
}
```

- Request body (multiple times):

```json
{
  "medicine_id": "65f0a1a2b3c4d5e6f7080920",
  "reminder_times": ["08:00", "20:00"],
  "repeat_type": "daily",
  "is_active": true
}
```

Response example (`201`, single):

```json
{
  "success": true,
  "message": "Reminder created successfully",
  "data": {
    "id": "65f0a1a2b3c4d5e6f7080930",
    "user_id": "65f0a1a2b3c4d5e6f7080910",
    "medicine_id": "65f0a1a2b3c4d5e6f7080920",
    "medicine_name": "Paracetamol",
    "reminder_time": "08:00",
    "repeat_type": "daily",
    "notification_key": "65f0a1a2b3c4d5e6f7080920:08:00",
    "is_active": true
  }
}
```

Response example (`201`, multiple):

```json
{
  "success": true,
  "message": "Reminder created successfully",
  "data": {
    "medicine_id": "65f0a1a2b3c4d5e6f7080920",
    "medicine_name": "Paracetamol",
    "created_count": 2,
    "items": [
      {
        "reminder_time": "08:00",
        "notification_key": "65f0a1a2b3c4d5e6f7080920:08:00"
      },
      {
        "reminder_time": "20:00",
        "notification_key": "65f0a1a2b3c4d5e6f7080920:20:00"
      }
    ]
  }
}
```

### 12) List Reminders

- Endpoint: `/api/v1/reminders`
- Method: `GET`
- Auth required: `Yes`
- Request body: `None`
- Query params (optional):
  - `medicine_id`

Response example (`200`):

```json
{
  "success": true,
  "data": {
    "count": 2,
    "items": [
      {
        "id": "65f0a1a2b3c4d5e6f7080930",
        "medicine_id": "65f0a1a2b3c4d5e6f7080920",
        "medicine_name": "Paracetamol",
        "reminder_time": "08:00",
        "repeat_type": "daily",
        "notification_key": "65f0a1a2b3c4d5e6f7080920:08:00"
      }
    ]
  }
}
```

### 13) Delete Reminder

- Endpoint: `/api/v1/reminders/<reminder_id>`
- Method: `DELETE`
- Auth required: `Yes`
- Request body: `None`

Response example (`200`):

```json
{
  "success": true,
  "message": "Reminder deleted successfully"
}
```

---

## Intake Logs APIs

### 14) Create Intake Log

- Endpoint: `/api/v1/intake-logs`
- Method: `POST`
- Auth required: `Yes`
- Request body:

```json
{
  "medicine_id": "65f0a1a2b3c4d5e6f7080920",
  "date": "2026-03-08",
  "taken": true,
  "time_taken": "2026-03-08T08:01:00Z"
}
```

Response example (`201`):

```json
{
  "success": true,
  "message": "Intake log created successfully",
  "data": {
    "id": "65f0a1a2b3c4d5e6f7080940",
    "user_id": "65f0a1a2b3c4d5e6f7080910",
    "medicine_id": "65f0a1a2b3c4d5e6f7080920",
    "date": "2026-03-08T00:00:00+00:00",
    "taken": true,
    "time_taken": "2026-03-08T08:01:00+00:00"
  }
}
```

### 15) Get Today Checkbook

- Endpoint: `/api/v1/intake-logs/today`
- Method: `GET`
- Auth required: `Yes`
- Request body: `None`

Response example (`200`):

```json
{
  "success": true,
  "data": {
    "date": "2026-03-08",
    "consistency": 80,
    "medicines": [
      { "medicine_name": "Paracetamol", "taken": true },
      { "medicine_name": "Vitamin D", "taken": false }
    ]
  }
}
```

### 16) Get Intake History (Advanced Filters)

- Endpoint: `/api/v1/intake-logs/history`
- Method: `GET`
- Auth required: `Yes`
- Request body: `None`
- Query params (optional):
  - `from_date` (`YYYY-MM-DD`)
  - `to_date` (`YYYY-MM-DD`)
  - `medicine_id`

Response example (`200`):

```json
{
  "success": true,
  "data": {
    "history": [
      {
        "date": "2026-03-08",
        "consistency": 80,
        "medicines": [
          { "medicine_name": "Paracetamol", "taken": true },
          { "medicine_name": "Vitamin D", "taken": false }
        ]
      }
    ],
    "total_days": 1
  }
}
```

---

## Expenses APIs

### 17) Create Expense

- Endpoint: `/api/v1/expenses`
- Method: `POST`
- Auth required: `Yes`
- Request body:

```json
{
  "medicine_name": "Paracetamol",
  "cost": 250,
  "date": "2026-03-08",
  "currency": "INR",
  "category": "Pharmacy",
  "notes": "Monthly refill"
}
```

Response example (`201`):

```json
{
  "success": true,
  "message": "Expense created successfully",
  "data": {
    "id": "65f0a1a2b3c4d5e6f7080950",
    "user_id": "65f0a1a2b3c4d5e6f7080910",
    "medicine_name": "Paracetamol",
    "cost": 250,
    "date": "2026-03-08T00:00:00+00:00",
    "currency": "INR",
    "category": "Pharmacy"
  }
}
```

### 18) List Expenses (Advanced Filters)

- Endpoint: `/api/v1/expenses`
- Method: `GET`
- Auth required: `Yes`
- Request body: `None`
- Query params (optional):
  - `month` (`YYYY-MM`)
  - `from_date` (`YYYY-MM-DD`)
  - `to_date` (`YYYY-MM-DD`)

Response example (`200`):

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "65f0a1a2b3c4d5e6f7080950",
        "medicine_name": "Paracetamol",
        "cost": 250,
        "date": "2026-03-08T00:00:00+00:00"
      }
    ],
    "count": 1
  }
}
```

### 19) Expense Summary

- Endpoint: `/api/v1/expenses/summary`
- Method: `GET`
- Auth required: `Yes`
- Request body: `None`
- Query params (optional):
  - `year` (integer)
  - `month` (1-12)

Response example (`200`):

```json
{
  "monthly_total": 2500,
  "yearly_total": 12000,
  "top_medicines": [
    {
      "medicine_name": "Paracetamol",
      "total_spent": 3200,
      "purchase_count": 8
    },
    {
      "medicine_name": "Vitamin D",
      "total_spent": 1800,
      "purchase_count": 6
    }
  ]
}
```

---

## Error Response Format

Typical error responses:

```json
{
  "error": "Validation message here",
  "details": {
    "field": "additional info"
  }
}
```

Common status codes:

- `400` Bad request / validation error
- `401` Unauthorized / token required
- `404` Resource not found
- `409` Conflict (example: duplicate intake log)
- `422` Invalid token
- `500` Internal server error
- `503` Database operation failed
