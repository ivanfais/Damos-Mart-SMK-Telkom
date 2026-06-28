param(
  [Parameter(Mandatory = $true)]
  [string]$TargetName,

  [Parameter(Mandatory = $true)]
  [string]$ApplicationId
)

$ErrorActionPreference = 'Stop'

$frontendRoot = Split-Path $PSScriptRoot -Parent
$source = Join-Path $frontendRoot 'damos_mart_influence'
$dest = Join-Path $frontendRoot $TargetName

if (-not (Test-Path $source)) {
  throw "Source not found: $source"
}

if (Test-Path $dest) {
  Write-Host "Removing existing folder: $dest"
  Remove-Item $dest -Recurse -Force
}

Write-Host "Copying $source -> $dest"
robocopy $source $dest /E /XD .dart_tool build .idea /NFL /NDL /NJH /NJS | Out-Null
if ($LASTEXITCODE -gt 7) {
  throw "robocopy failed with exit code $LASTEXITCODE"
}

$oldPackage = 'damos_mart_influence'
$oldAppId = 'com.example.damos_mart_influence'

$textExtensions = @('.dart', '.yaml', '.kts', '.xml', '.json', '.md', '.ps1', '.plist', '.xcconfig', '.swift', '.html')

Get-ChildItem $dest -Recurse -File | Where-Object {
  $textExtensions -contains $_.Extension.ToLower()
} | ForEach-Object {
  $content = Get-Content $_.FullName -Raw -Encoding UTF8
  $updated = $content.Replace($oldPackage, $TargetName).Replace($oldAppId, $ApplicationId)
  if ($updated -ne $content) {
    Set-Content -Path $_.FullName -Value $updated -Encoding UTF8 -NoNewline
  }
}

$oldKotlinDir = Join-Path $dest 'android\app\src\main\kotlin\com\example\damos_mart_influence'
$newKotlinDir = Join-Path $dest "android\app\src\main\kotlin\com\example\$TargetName"

if (Test-Path $oldKotlinDir) {
  New-Item -ItemType Directory -Force -Path (Split-Path $newKotlinDir -Parent) | Out-Null
  Move-Item $oldKotlinDir $newKotlinDir -Force
}

Write-Host "Done: $TargetName ($ApplicationId)"
