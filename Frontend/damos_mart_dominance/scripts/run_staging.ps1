$ErrorActionPreference = "Stop"

$apiBaseUrl = "https://damos-mart-smk-telkom-production.up.railway.app"

Write-Host "Running Damos Mart Influence -> API: $apiBaseUrl"

flutter run -d chrome `
  --dart-define=APP_ENV=staging `
  --dart-define=API_BASE_URL=$apiBaseUrl
