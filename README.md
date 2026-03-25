# Medical Management Backend (Flask + MongoDB Atlas)

Production-ready backend skeleton for a medical management mobile application.

## Tech Stack

- Flask
- MongoDB Atlas
- Flask-PyMongo
- Flask-JWT-Extended
- Flask-Bcrypt
- python-dotenv

## Project Structure

```text
app/
    __init__.py
    config.py
    extensions.py
    routes.py
    utils/
        __init__.py
        errors.py
        helpers.py
        validators.py

    blueprints/
        auth/
            routes.py
            services.py
            models.py
            schemas.py
        users/
            routes.py
            services.py
            models.py
            schemas.py
        medicines/
            routes.py
            services.py
            models.py
            schemas.py
        reminders/
            routes.py
            services.py
            models.py
            schemas.py
        intake_logs/
            routes.py
            services.py
            models.py
            schemas.py
        expenses/
            routes.py
            services.py
            models.py
            schemas.py

run.py
requirements.txt
.env.example
```

## Setup

1. Create and activate a virtual environment.
2. Install dependencies:

   ```bash
   pip install -r requirements.txt
   ```

3. Create `.env` from `.env.example` and provide your MongoDB Atlas URI + secrets.
4. Run the app:

   ```bash
   python run.py
   ```

## API Highlights

- `GET /health`
- Auth: `/api/auth/register`, `/api/auth/login`, `/api/auth/refresh`
- Users: `/api/users/me`
- Medicines: `/api/medicines`
- Reminders: `/api/reminders`
- Intake Logs: `/api/intake-logs`
- Expenses: `/api/expenses`, `/api/expenses/summary`

## Notes

- Uses app factory pattern via `create_app()` in `app/__init__.py`.
- Uses JWT authentication for protected routes.
- Uses bcrypt password hashing for user credentials.
- Uses centralized error handling and per-blueprint input validation.
