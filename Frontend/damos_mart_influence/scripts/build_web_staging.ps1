param(
  [Parameter(Mandatory = $true)]
  [string]$ApiBaseUrl
)

$ErrorActionPreference = "Stop"

$normalized = $ApiBaseUrl.TrimEnd('/')

Write-Host "Building Damos Mart web (staging) -> API: $normalized"

flutter build web --release `
  --dart-define=APP_ENV=staging `
  --dart-define=API_BASE_URL=$normalized

Write-Host ""
Write-Host "Build selesai: build/web"
Write-Host ""
Write-Host "Deploy ke Netlify (drag & drop folder build/web ke https://app.netlify.com/drop)"
Write-Host "atau CLI: netlify deploy --prod --dir=build/web"
