# Flutter + Flask Medical App Setup Guide (Windows)

This guide makes your current project runnable end-to-end.

## 0) Current Status

Your Flutter source code is already added under `lib/` and dependencies are in `pubspec.yaml`.
What is currently missing on your machine is Flutter SDK installation and initial Flutter platform scaffold generation (`android/`, `ios/`, etc.).

---

## 1) Install Required Tools

Install these in order:

1. **Git for Windows**
2. **Flutter SDK (stable)**
3. **Android Studio** (includes Android SDK + Emulator)
4. **VS Code** + Flutter and Dart extensions
5. **Python 3.10+** (for Flask backend)

### 1.1 Install Flutter SDK

- Download Flutter stable ZIP from flutter.dev.
- Extract to: `C:\src\flutter`
- Add to PATH: `C:\src\flutter\bin`

Verify in new PowerShell:

```powershell
flutter --version
```

### 1.2 Android setup

- Open Android Studio once and let SDK components install.
- Install at least one Android API (e.g., API 34).
- Create an emulator in Device Manager.

Verify:

```powershell
flutter doctor
```

Fix all red ❌ items before continuing.

---

## 2) Bootstrap This Existing Project

Open PowerShell in this folder:

`C:\Users\adii6\Downloads\my_medical_store\my_medical_store\frontend\node_modules\flatted\python\project1`

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup_flutter.ps1
```

This script will:
- check Flutter,
- run `flutter create .` if scaffold folders are missing,
- run `flutter pub get`,
- run `flutter doctor`.

---

## 3) Start Flask Backend

In terminal 1:

```powershell
cd C:\Users\adii6\Downloads\my_medical_store\my_medical_store\frontend\node_modules\flatted\python\project1
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python run.py
```

Expected backend URL:

- local machine: `http://127.0.0.1:5000`
- Android emulator from Flutter app: `http://10.0.2.2:5000`

---

## 4) Run Flutter App (Dev)

In terminal 2:

```powershell
cd C:\Users\adii6\Downloads\my_medical_store\my_medical_store\frontend\node_modules\flatted\python\project1
flutter devices
flutter run -t lib/main_dev.dart --dart-define=API_BASE_URL=http://10.0.2.2:5000
```

If running on a physical Android device via USB, replace URL with your PC LAN IP:

```powershell
flutter run -t lib/main_dev.dart --dart-define=API_BASE_URL=http://<YOUR_PC_IP>:5000
```

---

## 5) Run Flutter App (Prod Flavor)

```powershell
flutter run -t lib/main_prod.dart --dart-define=API_BASE_URL=https://your-production-domain.com
```

---

## 6) VS Code Launch Configs

Use Run and Debug with:
- **Flutter Dev**
- **Flutter Prod**

Already configured in `.vscode/launch.json`.

---

## 7) Quick Troubleshooting

### Flutter command not found
- Confirm `C:\src\flutter\bin` is in PATH.
- Restart terminal/VS Code.

### App cannot connect to backend
- Ensure Flask server is running.
- For emulator use `10.0.2.2`, not `localhost`.
- Check firewall for port `5000`.

### Android licenses issue

```powershell
flutter doctor --android-licenses
```

### Build cache issues

```powershell
flutter clean
flutter pub get
```

---

## 8) First Login Test Flow

1. Open app.
2. Register a new user.
3. Login.
4. Add medicine.
5. Check daily checklist and mark taken.
6. Add expense and verify summary.

If any API fails, inspect Flask terminal logs and response payload.
