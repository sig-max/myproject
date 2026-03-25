$ErrorActionPreference = 'Stop'

Write-Host 'Checking Flutter availability...' -ForegroundColor Cyan
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Host 'Flutter is not installed or not on PATH.' -ForegroundColor Red
  Write-Host 'Install Flutter first, then run this script again.' -ForegroundColor Yellow
  exit 1
}

Write-Host 'Flutter found:' -ForegroundColor Green
flutter --version

if (-not (Test-Path 'android') -or -not (Test-Path 'ios')) {
  Write-Host 'Generating Flutter project scaffolding...' -ForegroundColor Cyan
  flutter create .
} else {
  Write-Host 'Flutter scaffolding already exists. Skipping create.' -ForegroundColor Green
}

Write-Host 'Fetching Dart dependencies...' -ForegroundColor Cyan
flutter pub get

Write-Host 'Running flutter doctor...' -ForegroundColor Cyan
flutter doctor

Write-Host 'Setup complete.' -ForegroundColor Green
Write-Host 'Run app (dev): flutter run -t lib/main_dev.dart --dart-define=API_BASE_URL=http://10.0.2.2:5000' -ForegroundColor Yellow
