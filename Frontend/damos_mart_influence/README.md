# Damos Mart Influence — Flutter Web Client

## User testing online (staging)

Backend harus online dengan URL HTTPS publik. Frontend di-build dengan URL API tersebut lalu di-host (Netlify).

### 1. Deploy backend (Railway — gratis tier)

1. Buat akun di [Railway](https://railway.app).
2. New Project → **Deploy from GitHub** (repo backend) atau upload folder `damos-mart-backend`.
3. Tambah service **PostgreSQL** dan **Redis** di project yang sama.
4. Set environment variables di service backend:

| Variable | Contoh |
|----------|--------|
| `NODE_ENV` | `production` |
| `PORT` | `3000` |
| `DATABASE_URL` | dari Railway PostgreSQL |
| `REDIS_URL` | dari Railway Redis |
| `JWT_ACCESS_SECRET` | string random panjang |
| `JWT_REFRESH_SECRET` | string random panjang |
| `CORS_ORIGINS` | `https://your-app.netlify.app` |
| `API_PREFIX` | `/api/v1` |

5. Railway akan build dari `Dockerfile`. Setelah deploy, catat URL publik, mis. `https://damos-mart-api.up.railway.app`.
6. (Opsional) Seed data: jalankan `npm run prisma:seed` sekali via Railway shell.

Cek health: `https://your-api-url/health`

### 2. Build frontend untuk staging

Ganti URL API dengan URL Railway kamu:

```powershell
cd Frontend/damos_mart_influence
.\scripts\build_web_staging.ps1 -ApiBaseUrl "https://damos-mart-api.up.railway.app"
```

### 3. Deploy web ke Netlify

**Cara cepat:** buka [Netlify Drop](https://app.netlify.com/drop) → drag folder `build/web`.

**CLI:**

```bash
npm i -g netlify-cli
netlify deploy --prod --dir=build/web
```

Setelah deploy, tambahkan URL Netlify ke `CORS_ORIGINS` di Railway, lalu redeploy backend.

### 4. Bagikan link ke tester

Contoh: `https://damos-mart.netlify.app` — bisa dibuka di browser HP/PC.

---

## Develop lokal

```bash
flutter run -d chrome
```

Default API: `http://localhost:3000` (backend jalan di mesin lokal).

Custom API saat run:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```
