# Damos Mart Influence — Flutter Web Client

## User testing online (staging)

Backend harus online dengan URL HTTPS publik. Frontend di-build dengan URL API tersebut lalu di-host (Netlify).

### 1. Deploy backend (Railway — gratis tier)

Repo GitHub kamu monorepo (`Backend` + `Frontend`). Railway harus diarahkan ke subfolder backend saja.

1. Buat akun di [Railway](https://railway.app).
2. **New Project** → **Deploy from GitHub** → pilih repo `Damos-Mart-SMK-Telkom`.
3. Klik service backend → **Settings** → **Root Directory** → isi:
   ```
   Backend/damos-mart-backend
   ```
   (tanpa slash di akhir). Save → Railway akan redeploy dari folder itu saja.
4. Tambah service **PostgreSQL** dan **Redis** di project yang sama (klik **+ New** di project).
5. Set environment variables di service backend (tab **Variables**):

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

5. Railway akan build dari `Dockerfile` di folder tersebut. Setelah deploy, catat URL publik, mis. `https://damos-mart-api.up.railway.app`.
6. Aktifkan domain publik: service backend → **Settings** → **Networking** → **Generate Domain**.
7. (Opsional) Seed data: service backend → **Settings** → shell / one-off → `npm run prisma:seed`.

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
