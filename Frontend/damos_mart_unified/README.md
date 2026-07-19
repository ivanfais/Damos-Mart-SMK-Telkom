# Damos Mart Unified

Satu APK berisi keempat varian DISC (Influence, Dominance, Steadiness, Conscientiousness).

## Struktur

- `lib/` — host shell (picker DISC, restart, penyimpanan pilihan)
- `packages/disc_core/` — enum DISC + bridge pindah tema
- `packages/variant_*` — salinan `lib/` + `assets/` dari masing-masing app DISC (tanpa mengubah folder asli)

## Setup

```powershell
cd Frontend
powershell -ExecutionPolicy Bypass -File scripts/init_unified_app.ps1
cd damos_mart_unified
flutter pub get
```

Jalankan ulang `init_unified_app.ps1` jika ada perubahan besar di salah satu varian asli dan ingin disalin ulang ke `packages/`.

## Run & build

```bash
flutter run
flutter build apk --release
```

## Alur user

1. Buka app → pilih gaya DISC
2. Masuk ke paket varian yang dipilih (fitur & UI sesuai project aslinya)
3. Profil → **Gaya Aplikasi DISC** → pilih varian lain → app restart, login tetap

## Catatan

- Empat folder app asli di `Frontend/damos_mart_*` **tidak diubah**.
- Perubahan di app asli perlu disinkronkan dengan menjalankan ulang script init atau copy manual ke `packages/variant_*`.
