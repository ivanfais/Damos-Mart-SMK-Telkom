$ErrorActionPreference = "Stop"



$apiBaseUrl = if ($env:API_BASE_URL) { $env:API_BASE_URL } else { "https://damos-mart-smk-telkom-production.up.railway.app" }

$webOrigin = if ($env:APP_WEB_ORIGIN) { $env:APP_WEB_ORIGIN } else { "http://localhost:8080" }



Write-Host "Running Damos Mart Dominance (dev) -> API: $apiBaseUrl"

Write-Host "Pindah tema DISC: jalankan Frontend/scripts/dev_single_domain.ps1 -> $webOrigin"



flutter run -d chrome `

  --dart-define=APP_ENV=development `

  --dart-define=API_BASE_URL=$apiBaseUrl `

  --dart-define=APP_WEB_ORIGIN=$webOrigin

