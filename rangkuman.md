# Rangkuman Proyek Damos Mart SMK Telkom — Tipe Kepribadian Influence
> Catatan ini dibuat sebagai referensi untuk pengembangan versi **Conscientiousness**

---

## 1. Gambaran Umum Proyek

| Atribut | Detail |
|---|---|
| Nama App | Damos Mart Influence |
| Platform | Flutter (Mobile + Web) |
| Tipe Kepribadian Target | **Influence (DISC)** |
| Versi | 1.0.0+1 |
| SDK | Dart >=3.0.0 <4.0.0 |
| Backend API | Railway: `https://damos-mart-smk-telkom-production.up.railway.app/api/v1` |
| Database di Railway | PostgreSQL + Redis (keduanya Online, sudah terhubung) |

Damos Mart adalah aplikasi mobile koperasi digital untuk siswa SMK Telkom Jakarta. App ini hanya **frontend** yang mengonsumsi REST API + WebSocket dari backend terpisah.

---

## 2. Arsitektur & Stack Teknologi

### Arsitektur
```
Presentation Layer  →  Screens + Widgets
State Management    →  BLoC / Cubit (flutter_bloc)
Data Layer          →  Repositories
Network Layer       →  DioClient (REST) + SocketService (WebSocket)
Storage Layer       →  SecureStorage (token) + SharedPreferences
External APIs       →  REST API + Socket.io
```

### Dependency Utama
| Kategori | Package | Versi |
|---|---|---|
| State Management | flutter_bloc | ^8.1.3 |
| Routing | go_router | ^13.2.0 |
| HTTP Client | dio | ^5.4.1 |
| WebSocket | socket_io_client | ^3.0.2 |
| Secure Storage | flutter_secure_storage | ^9.0.0 |
| Font | google_fonts (Poppins) | ^6.1.0 |
| Image Cache | cached_network_image | ^3.3.1 |
| QR Code | qr_flutter | ^4.1.0 |
| Chart | fl_chart | ^0.66.0 |
| Shimmer Loading | shimmer | ^3.0.0 |
| Notifikasi Lokal | flutter_local_notifications | ^17.0.0 |
| Lokalisasi | intl | ^0.19.0 |

---

## 3. Struktur Folder (`lib/`)

```
lib/
├── main.dart                   # Entry point
├── app.dart                    # Root widget + MultiBlocProvider
├── routes/
│   ├── app_router.dart         # GoRouter navigation
│   └── damos_page_transitions.dart
├── screens/                    # Semua halaman layar
│   ├── auth/                   # Login, Register
│   ├── home/                   # Dashboard
│   ├── catalog/                # Katalog produk + detail
│   ├── cart/                   # Keranjang belanja
│   ├── checkout/               # Pembayaran + QRIS + tiket
│   ├── queue/                  # Antrian + tracking + QR
│   ├── profile/                # Profil + edit profil
│   ├── history/                # Riwayat pembelian
│   ├── chat/                   # Chat support
│   ├── info/                   # Info koperasi
│   ├── preorder/               # Pre-order
│   ├── review/                 # Review produk
│   └── splash/                 # Splash screen
├── blocs/                      # State management
│   ├── auth/                   # AuthBloc (login/register/logout)
│   ├── product/                # ProductCubit
│   ├── cart/                   # CartCubit
│   ├── order/                  # OrderCubit
│   ├── queue/                  # QueueCubit
│   ├── chat/                   # ChatCubit
│   ├── notification/           # NotificationCubit
│   └── cooperative/            # CooperativeCubit
├── data/
│   ├── models/                 # 13 model data
│   └── repositories/          # 9 repository (data access layer)
├── core/
│   ├── network/                # DioClient + error handling
│   ├── storage/                # Secure & prefs storage
│   ├── socket/                 # Socket.io service
│   ├── notifications/          # FCM push notifications
│   └── utils/                  # Formatter, validator, dsb
├── config/
│   ├── api_config.dart         # Endpoint definitions
│   ├── env.dart                # Environment config
│   └── app_constants.dart
├── theme/
│   ├── app_colors.dart         # Palet warna
│   ├── app_text_styles.dart    # Tipografi
│   ├── app_dimensions.dart     # Spacing & dimensi
│   └── app_theme.dart          # Material3 theme
└── widgets/
    ├── common/                 # 12 widget reusable
    ├── product/                # 5 widget produk
    └── home/                   # 3 widget halaman home
```

---

## 4. Semua Screen / Halaman

| Screen | Path File | Fungsi |
|---|---|---|
| Splash | `screens/splash/splash_screen.dart` | Loading awal, cek token |
| Login | `screens/auth/login_screen.dart` | Autentikasi |
| Register | `screens/auth/register_screen.dart` | Daftar akun baru |
| Home | `screens/home/home_screen.dart` | Dashboard utama |
| Catalog | `screens/catalog/catalog_screen.dart` | Katalog + pencarian produk |
| Product Detail | `screens/catalog/product_detail_screen.dart` | Detail produk + ulasan |
| Cart | `screens/cart/cart_screen.dart` | Keranjang belanja |
| Payment | `screens/checkout/payment_screen.dart` | Pilih metode pembayaran |
| QRIS Payment | `screens/checkout/qris_payment_screen.dart` | Tampilan QR code QRIS |
| Pickup Ticket | `screens/checkout/pickup_ticket_screen.dart` | Tiket pengambilan |
| Queue List | `screens/queue/queue_list_screen.dart` | Daftar antrian aktif |
| Queue Detail | `screens/queue/queue_detail_screen.dart` | Detail satu antrian |
| Preorder Tracking | `screens/queue/preorder_tracking_screen.dart` | Tracking pre-order |
| QR Ticket | `screens/queue/qr_ticket_screen.dart` | QR untuk pickup |
| Order Complete | `screens/queue/order_complete_screen.dart` | Konfirmasi selesai |
| Preorder | `screens/preorder/preorder_screen.dart` | Form pre-order |
| Profile | `screens/profile/profile_screen.dart` | Profil & pengaturan |
| Edit Profile | `screens/profile/edit_profile_screen.dart` | Edit data profil |
| History | `screens/history/purchase_history_screen.dart` | Riwayat pembelian |
| Chat | `screens/chat/chat_screen.dart` | Chat dengan admin |
| Coop Info | `screens/info/coop_info_screen.dart` | Info & jam koperasi |
| Review | `screens/review/review_screen.dart` | Submit ulasan produk |

---

## 5. Navigasi (GoRouter)

```
/                        → Splash
├── /login               → Login
├── /register            → Register
└── ShellRoute (Bottom Nav 5 tab)
    ├── /home            → Home
    ├── /catalog         → Katalog
    ├── /queue           → Antrian
    ├── /cart            → Keranjang
    └── /profile         → Profil
    
    Sub-routes (tanpa bottom nav):
    ├── /catalog/:id
    ├── /preorder/:id
    ├── /checkout
    ├── /checkout/qris/:orderId
    ├── /checkout/ticket/:orderId
    ├── /queue/:id
    ├── /queue/:id/tracking
    ├── /queue/:id/qr
    ├── /queue/:id/complete
    ├── /profile/edit
    ├── /profile/history
    ├── /profile/chat
    ├── /review/:orderId/:productId
    └── /info
```

**Logika redirect:**
- Token tidak ada → redirect ke `/login`
- Sudah login + akses auth page → redirect ke `/home`

---

## 6. Design System — Tipe Influence

### Warna Utama
| Peran | Warna | Hex |
|---|---|---|
| Primary | Hijau Koperasi | `#2E7D32` |
| Primary Light | Hijau Terang | `#4CAF50` |
| Primary Dark | Hijau Gelap | `#1B5E20` |
| Accent | Oranye Hangat | `#FF9800` |
| Accent Light | Oranye Muda | `#FFB74D` |
| Success | Hijau | `#4CAF50` |
| Error | Merah | `#E53935` |
| Warning | Oranye | `#FFA726` |
| Info | Biru | `#42A5F5` |
| Background | Putih | `#FFFFFF` |
| Surface | Abu Muda | `#F5F5F5` |

### Tipografi
- **Font:** Poppins (Google Fonts)
- Display: 32px
- Heading L/M/S: 24px / 20px / 18px
- Body L/M/S: 16px / 14px / 12px
- Harga: 18px bold (special)

### Dimensi
- Border Radius: 8 / 12 / 16 / 24 / 50px (pill)
- Button: tinggi 52px, radius 50px (pill shape)
- Input: tinggi 52px, radius 12px
- Bottom Nav: 70px
- Banner: 160px
- Product Card Image: 120px

### Animasi
- Page transition: 350ms easeInOut (slide + fade)
- Button press: 150ms bounce
- Card scale on tap: 200ms (scale 97%)
- Shimmer loading: 1500ms loop

---

## 7. Model Data

| Model | File | Isi Utama |
|---|---|---|
| User | `user_model.dart` | id, name, email, role, DISC type, avatar |
| Product | `product_model.dart` | id, name, price, stock, variants, rating |
| ProductVariant | `product_variant_model.dart` | Varian ukuran/warna produk |
| Category | `category_model.dart` | id, name, icon |
| CartItem | `cart_item_model.dart` | product, variant, qty, subtotal |
| Order | `order_model.dart` | status (pending/paid/preparing/ready/completed), payment |
| OrderItem | `order_item_model.dart` | Item per baris dalam order |
| Queue | `queue_model.dart` | nomor antrian, status, estimasi |
| ChatMessage | `chat_message_model.dart` | pesan, sender, timestamp |
| ChatRoom | `chat_room_model.dart` | room id, participants |
| Review | `review_model.dart` | rating bintang, komentar |
| Notification | `notification_model.dart` | judul, isi, is_read |
| CooperativeInfo | `cooperative_info_model.dart` | jam buka, kepadatan |

---

## 8. Fitur-Fitur Utama

1. **Katalog Produk** — browsing, filter kategori, pencarian, paginasi
2. **Keranjang & Checkout** — add to cart, pilih varian, checkout
3. **Pembayaran QRIS** — QR code dinamis untuk pembayaran
4. **Sistem Antrian Real-time** — WebSocket Socket.io untuk update live
5. **Pre-Order** — pemesanan dengan estimasi waktu
6. **Riwayat Pembelian** — histori lengkap transaksi
7. **Review Produk** — submit rating + komentar pasca pembelian
8. **Chat Support** — pesan real-time ke admin koperasi
9. **Notifikasi Push** — FCM untuk Android/iOS, in-app banner
10. **Info Koperasi** — jam buka, tingkat kepadatan
11. **Profil Siswa** — edit data diri, foto profil
12. **SSO Login** — opsi login via akun sekolah

---

## 9. API Endpoints Backend

Base URL: `https://damos-mart-smk-telkom-production.up.railway.app/api/v1`

| Kelompok | Endpoint Utama |
|---|---|
| Auth | `/auth/login`, `/auth/register`, `/auth/login/sso`, `/auth/refresh`, `/auth/logout` |
| User | `/users/me`, `/users/me/password` |
| Produk | `/products`, `/products/featured`, `/products/:id`, `/products/:id/reviews` |
| Kategori | `/categories`, `/categories/:id` |
| Keranjang | `/cart`, `/cart/:id` |
| Order | `/orders`, `/orders/:id`, `/orders/:id/pay`, `/orders/:id/cancel` |
| Antrian | `/queues/active`, `/queues/current`, `/queues/:id` |
| Chat | `/chat/room`, `/chat/room/:roomId/messages` |
| Koperasi | `/cooperative/hours`, `/cooperative/crowd`, `/cooperative/status`, `/cooperative/info` |
| Notifikasi | `/notifications`, `/notifications/:id/read`, `/notifications/read-all` |
| Review | `/reviews` |

**HTTP Client:** Dio dengan interceptor:
- Auto-inject Bearer token
- Auto-refresh token saat 401
- Queue request + retry setelah refresh

**WebSocket (Socket.io):**
- Event `queue:called` — nomor antrian dipanggil
- Event `queue:ready` — pesanan siap diambil
- Event `queue:updated` — update status antrian
- Real-time chat messaging

---

## 10. Perbedaan Desain: Influence vs Conscientiousness

Ini adalah poin-poin **yang perlu diubah/disesuaikan** untuk versi Conscientiousness:

### Influence (existing)
- Warna: Hijau cerah + Oranye hangat → **Energik, ramah, ekspresif**
- UI: Pill buttons, banner besar, animasi lively
- Font: Poppins dengan ukuran besar dan ekspresif
- Fokus: Pengalaman sosial, visual menarik, fun
- Fitur menonjol: Chat, review sosial, antrian visual

### Yang perlu berubah untuk Conscientiousness
| Aspek | Influence | Conscientiousness (disarankan) |
|---|---|---|
| Warna | Hijau + Oranye cerah | Biru/Navy + Abu profesional (akurasi, kepercayaan) |
| Bentuk UI | Pill, bulat, organik | Sudut lebih tajam/formal (radius kecil), terstruktur |
| Tipografi | Poppins besar, ekspresif | Lebih kecil, rapi, info-dense |
| Animasi | Lively, bounce, scale | Minimal, subtle, smooth |
| Layout | Visual-first, gambar besar | Data-first, detail teknis tampil jelas |
| Fitur Ekstra | Chat, review sosial | Riwayat detail, laporan, filter canggih, statistik |
| CTA Button | Besar, pill, mencolok | Lebih proporsional, informatif |
| Empty State | Ilustrasi fun | Pesan informatif + panduan aksi |
| Notifikasi | Banner pop, colorful | Notifikasi ringkas, structured |
| Info Koperasi | Visual jam buka | Jadwal detail, kapasitas, kebijakan |

### Fitur Tambahan yang Relevan untuk C-Type
- **Detail produk yang lebih lengkap** (bahan, komposisi, kebijakan retur)
- **Filter & sorting canggih** (harga, rating, stok, kategori berlapis)
- **Laporan pembelian** (statistik pengeluaran per periode)
- **Konfirmasi berlapis** sebelum checkout (summary yang rinci)
- **Estimasi waktu yang akurat** di antrian (angka, bukan hanya status)
- **History yang bisa di-export / dilihat per bulan**

---

## 11. Infrastruktur (Railway)

```
Project: charming-dedication
Environment: production

Services:
├── Damos-Mart-SMK-Telkom  (Online)
│   └── Public URL: damos-mart-smk-telkom-production.up.railway.app
│       → Port 3000
├── Postgres               (Online)
│   └── postgres-volume
└── Redis                  (Online)
    └── redis-volume
```

**Catatan untuk versi C-type:**
- Backend API yang sama bisa digunakan (shared)
- Cukup buat service Flutter baru di Railway project yang sama
- Atau deploy sebagai Flutter Web di hosting terpisah (Netlify, dsb)
- Environment variables perlu disesuaikan jika ada perbedaan config

---

## 12. Cara Menjalankan Proyek (Referensi)

```bash
# Jalankan di Chrome web (mode development)
flutter run -d chrome

# Dengan backend lokal
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000

# Build web untuk staging
./scripts/build_web_staging.ps1

# Test account setelah DB seed:
# Siswa : siswa@damosmart.com / siswa123
# Admin : admin@damosmart.com / admin123
```

---

## 13. Kesimpulan untuk Pengembangan Versi C-Type

Proyek Influence ini adalah **fondasi yang solid dan siap direplikasi**. Untuk membuat versi Conscientiousness:

1. **Duplikasi folder Flutter** (rename `damos_mart_influence` → `damos_mart_conscientiousness`)
2. **Ganti design system** (`app_colors.dart`, `app_text_styles.dart`, `app_dimensions.dart`)
3. **Sesuaikan widget** — terutama button shape, card layout, spacing
4. **Tambah fitur C-type** — filter detail, laporan, konfirmasi rinci
5. **API tetap sama** — tidak perlu backend baru, cukup consume endpoint yang sudah ada
6. **Koneksi database** — gunakan PostgreSQL + Redis yang sudah ada di Railway

> Backend sudah berjalan dan siap. Fokus pengembangan sepenuhnya ada di **tampilan + fitur yang relevan untuk tipe C (Conscientiousness)**.

---

*Rangkuman dibuat: 24 Juni 2026*
*Berdasarkan eksplorasi kode proyek: `D:\KULYEAH\TA GUE\Damos-Mart\Damos-Mart-SMK-Telkom`*

---

## 14. Daftar Lengkap Semua Endpoint yang Digunakan

**Base URL:** `https://damos-mart-smk-telkom-production.up.railway.app/api/v1`

---

### AUTH — `auth_repository.dart`

| Method | Endpoint | Fungsi | Request Body |
|---|---|---|---|
| POST | `/auth/login` | Login dengan email & password | `{ email, password }` |
| POST | `/auth/register` | Daftar akun baru (auto set `discType: INFLUENCE`) | `{ fullName, email, password, phone?, discType }` |
| POST | `/auth/login/sso` | Login via SSO sekolah | `{ ssoToken }` |
| POST | `/auth/refresh` | Refresh access token | `{ refreshToken }` *(di interceptor Dio)* |
| POST | `/auth/logout` | Logout & invalidasi token | `{ token: refreshToken }` |

**Response Auth:** `{ data: { user, accessToken, refreshToken } }`

---

### USER — `auth_repository.dart`

| Method | Endpoint | Fungsi | Request Body |
|---|---|---|---|
| GET | `/users/me` | Ambil data profil user yang sedang login | — |
| PUT | `/users/me` | Update profil (nama, telepon, foto avatar) | `FormData { fullName, phone?, avatar? }` atau `{ fullName, phone? }` |

**Catatan:** Upload avatar menggunakan `multipart/form-data`. Jika tidak ada foto, kirim JSON biasa.

---

### PRODUK — `product_repository.dart`

| Method | Endpoint | Fungsi | Query Params |
|---|---|---|---|
| GET | `/products` | Ambil daftar produk (paginasi + filter) | `category?, search?, inStock?, isPreorder?, sort, page, limit` |
| GET | `/products/featured` | Ambil produk unggulan/featured | `limit` |
| GET | `/products/:id` | Detail satu produk | — |
| GET | `/products/:id/reviews` | Ambil ulasan produk | `page, limit` |

**Sort options:** `newest` (default), bisa juga `price_asc`, `price_desc`, `popular`

**Response produk list:** `{ data: [...], pagination: { page, limit, total, totalPages } }`

---

### KATEGORI — `product_repository.dart`

| Method | Endpoint | Fungsi | Query Params |
|---|---|---|---|
| GET | `/categories` | Ambil semua kategori | — |
| GET | `/categories/:id` | Detail satu kategori | — |

---

### KERANJANG (CART) — `cart_repository.dart`

| Method | Endpoint | Fungsi | Request Body |
|---|---|---|---|
| GET | `/cart` | Ambil isi keranjang user | — |
| POST | `/cart` | Tambah item ke keranjang | `{ productId, variantId?, quantity }` |
| PUT | `/cart/:id` | Update jumlah item keranjang | `{ quantity }` |
| DELETE | `/cart/:id` | Hapus satu item dari keranjang | — |
| DELETE | `/cart` | Kosongkan seluruh keranjang | — |

**Response cart:** `{ data: { items: [...], totalItems, totalPrice } }`

---

### ORDER — `order_repository.dart`

| Method | Endpoint | Fungsi | Request Body |
|---|---|---|---|
| POST | `/orders` | Buat order baru dari item keranjang | `{ cartItemIds: [...], paymentMethod, notes? }` |
| GET | `/orders` | Ambil semua order milik user | — |
| GET | `/orders/:id` | Detail satu order | — |
| POST | `/orders/:id/pay` | Bayar order (trigger generate antrian) | `{ paymentMethod }` |
| POST | `/orders/:id/cancel` | Batalkan order | — |

**Status order:** `pending` → `paid` → `preparing` → `ready` → `completed`

**Payment methods:** `QRIS`, `CASH` (atau sesuai konfigurasi backend)

**Response `/orders/:id/pay`:** `{ data: { order: {...}, queue: {...} } }` — order dan nomor antrian dikembalikan sekaligus

---

### ANTRIAN (QUEUE) — `queue_repository.dart`

| Method | Endpoint | Fungsi | Keterangan |
|---|---|---|---|
| GET | `/queues/active` | Ambil semua antrian aktif milik user | List antrian yang belum selesai |
| GET | `/queues/current` | Ambil state antrian saat ini (global koperasi) | Berisi nomor yang sedang dipanggil |
| GET | `/queues/:id` | Detail satu antrian beserta order-nya | Response: `{ data: { queue: {..., order: {...} } } }` |

**Status antrian:** `waiting` → `called` → `ready` → `completed`

---

### REVIEW — `review_repository.dart`

| Method | Endpoint | Fungsi | Request Body |
|---|---|---|---|
| POST | `/reviews` | Submit ulasan produk pasca pembelian | `FormData { orderId, productId, rating, comment?, photos[]? }` |

**Catatan:** Rating dikirim sebagai string di FormData. Foto bersifat opsional (multipart upload).

---

### CHAT — `chat_repository.dart`

| Method | Endpoint | Fungsi | Request Body / Query |
|---|---|---|---|
| GET | `/chat/room` | Ambil atau buat room chat user dengan admin | — |
| GET | `/chat/room/:roomId/messages` | Ambil riwayat pesan di room | `{ limit, cursor? }` (cursor-based pagination) |
| POST | `/chat/room/:roomId/messages` | Kirim pesan baru | `{ message }` |

**Catatan:** Chat juga berjalan via WebSocket Socket.io untuk pesan real-time. REST digunakan untuk load riwayat.

---

### KOPERASI — `cooperative_repository.dart`

| Method | Endpoint | Fungsi | Keterangan |
|---|---|---|---|
| GET | `/cooperative/hours` | Ambil jadwal jam operasional | List hari & jam buka/tutup |
| GET | `/cooperative/crowd` | Ambil data kepadatan pengunjung | Data historis kepadatan per jam |
| GET | `/cooperative/info` | Ambil info umum koperasi | Nama, alamat, deskripsi, dsb |
| GET | `/cooperative/status` | Cek status koperasi saat ini | Apakah sedang buka/tutup + antrian aktif |

---

### NOTIFIKASI — `notification_repository.dart`

| Method | Endpoint | Fungsi | Request Body |
|---|---|---|---|
| GET | `/notifications` | Ambil semua notifikasi user | — |
| POST | `/notifications/:id/read` | Tandai satu notifikasi sudah dibaca | — |
| POST | `/notifications/read-all` | Tandai semua notifikasi sudah dibaca | — |

---

### WEBSOCKET EVENTS — `socket_service.dart`

**URL:** `wss://damos-mart-smk-telkom-production.up.railway.app` (Socket.io)

| Event (Listen) | Deskripsi | Payload |
|---|---|---|
| `queue:called` | Nomor antrian user dipanggil | `{ queueId, queueNumber }` |
| `queue:ready` | Pesanan siap diambil | `{ queueId, queueNumber }` |
| `queue:updated` | Status antrian berubah | `{ queueId, status }` |
| *(chat messages)* | Pesan baru masuk di room | `{ roomId, message: {...} }` |

---

### RINGKASAN JUMLAH ENDPOINT

| Repository | Jumlah Endpoint |
|---|---|
| auth_repository | 5 |
| user (via auth_repository) | 2 |
| product_repository | 4 |
| product_repository (kategori) | 2 |
| cart_repository | 5 |
| order_repository | 5 |
| queue_repository | 3 |
| review_repository | 1 |
| chat_repository | 3 |
| cooperative_repository | 4 |
| notification_repository | 3 |
| **Total REST** | **37** |
| WebSocket events | 4+ |
