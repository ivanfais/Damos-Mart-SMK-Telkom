# Damos Mart Influence — Flutter Web Client

## API backend (Railway)

Default app sudah mengarah ke:

```
https://damos-mart-smk-telkom-production.up.railway.app/api/v1
```

## Jalankan app (Chrome)

```powershell
cd Frontend/damos_mart_influence
flutter run -d chrome
```

Atau pakai script:

```powershell
.\scripts\run_staging.ps1
```

## Backend lokal

Kalau mau pakai `http://localhost:3000`:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000 --dart-define=APP_ENV=development
```

## Build web (staging / share ke tester)

```powershell
.\scripts\build_web_staging.ps1
```

Output: folder `build/web`

## Akun demo (setelah seed database Railway)

| Role | Email | Password |
|------|-------|----------|
| Siswa | `siswa@damosmart.com` | `siswa123` |
| Admin | `admin@damosmart.com` | `admin123` |
