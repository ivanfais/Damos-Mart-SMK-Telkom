param(
  [Parameter(Mandatory = $true)]
  [string]$RailwayDatabaseUrl,

  [ValidateSet('catalog', 'full')]
  [string]$Scope = 'catalog',

  [switch]$SkipTruncate
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$backendRoot = Split-Path $PSScriptRoot -Parent
$composeFile = Join-Path $repoRoot 'Backend\docker-compose.yml'
$dumpFile = Join-Path $backendRoot "local_${Scope}_dump.sql"
$truncateFile = Join-Path $backendRoot 'railway_truncate_catalog.sql'

Write-Host '=== Damos Mart: sync database lokal -> Railway ===' -ForegroundColor Cyan
Write-Host "Scope: $Scope"
Write-Host ''

# 1. Pastikan Postgres lokal jalan
Write-Host '[1/4] Memeriksa Docker Postgres lokal...'
$postgresRunning = docker ps --filter 'name=damos-mart-postgres' --format '{{.Names}}' 2>$null
if (-not $postgresRunning) {
  Write-Host '      Container belum jalan. Menjalankan docker compose...'
  docker compose -f $composeFile up -d postgres
  Start-Sleep -Seconds 4
}

$ready = docker exec damos-mart-postgres pg_isready -U postgres -d damos_mart 2>$null
if ($LASTEXITCODE -ne 0) {
  throw 'PostgreSQL lokal belum siap. Cek Docker Desktop lalu coba lagi.'
}
Write-Host '      Postgres lokal OK.' -ForegroundColor Green

# 2. Export dari lokal
Write-Host '[2/4] Export data dari localhost...'
if ($Scope -eq 'catalog') {
  docker exec damos-mart-postgres pg_dump `
    -U postgres `
    -d damos_mart `
    --data-only `
    --column-inserts `
    --table=public.categories `
    --table=public.products `
    --table=public.product_variants `
    | Set-Content -Path $dumpFile -Encoding utf8
} else {
  docker exec damos-mart-postgres pg_dump `
    -U postgres `
    -d damos_mart `
    --data-only `
    --column-inserts `
    | Set-Content -Path $dumpFile -Encoding utf8
}

if (-not (Test-Path $dumpFile) -or (Get-Item $dumpFile).Length -lt 10) {
  throw "Export gagal atau kosong: $dumpFile"
}
Write-Host "      Disimpan ke: $dumpFile" -ForegroundColor Green

# 3. (Opsional) Hapus data katalog lama di Railway supaya tidak bentrok
if ($Scope -eq 'catalog' -and -not $SkipTruncate) {
  Write-Host '[3/4] Menghapus katalog lama di Railway (truncate)...'
  @'
BEGIN;
TRUNCATE TABLE product_variants, products, categories RESTART IDENTITY CASCADE;
COMMIT;
'@ | Set-Content -Path $truncateFile -Encoding utf8

  Get-Content $truncateFile | docker run --rm -i postgres:16-alpine psql "$RailwayDatabaseUrl" 2>&1 | Out-Host
  if ($LASTEXITCODE -ne 0) {
    throw 'Truncate di Railway gagal. Periksa DATABASE_PUBLIC_URL.'
  }
  Write-Host '      Truncate OK.' -ForegroundColor Green
} else {
  Write-Host '[3/4] Lewati truncate (-SkipTruncate atau scope full).' -ForegroundColor Yellow
}

# 4. Import ke Railway
Write-Host '[4/4] Import ke Railway...'
Get-Content $dumpFile | docker run --rm -i postgres:16-alpine psql "$RailwayDatabaseUrl" 2>&1 | Out-Host
if ($LASTEXITCODE -ne 0) {
  throw 'Import ke Railway gagal. Periksa log di atas.'
}

Write-Host ''
Write-Host 'Selesai! Data lokal sudah di Railway.' -ForegroundColor Green
Write-Host ''
Write-Host 'Catatan gambar produk:' -ForegroundColor Yellow
Write-Host '  File di folder uploads/ di laptop TIDAK ikut pindah.'
Write-Host '  Upload ulang gambar lewat admin panel, atau copy folder uploads ke server.'
Write-Host ''
Write-Host 'Cek produk di Railway:'
Write-Host '  docker run --rm postgres:16-alpine psql `"$RailwayDatabaseUrl`" -c `"SELECT name, price, stock FROM products;`"'
