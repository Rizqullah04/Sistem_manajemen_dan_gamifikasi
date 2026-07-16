# Dokumentasi Teknis Sistem Manajemen dan Gamifikasi Ormawa

Tanggal dokumen: 22 Juni 2026

## 1. Ringkasan Sistem

Sistem Manajemen dan Gamifikasi Ormawa adalah aplikasi untuk mengelola aktivitas organisasi mahasiswa, verifikasi kegiatan, leaderboard, voting, diskusi, chat, dan pemberian poin. Sistem terdiri dari aplikasi frontend Flutter dan backend Laravel API.

Tujuan utama sistem:

- Memudahkan admin fakultas memonitor kegiatan ormawa.
- Memfasilitasi ormawa dalam membuat kegiatan dan mengelola anggota.
- Memberikan ruang partisipasi anggota melalui komentar, like, voting, dan leaderboard.
- Menggunakan mekanisme gamifikasi berupa poin, peringkat, badge, dan periode kompetisi.

## 2. Stack Teknologi

### Frontend

- Flutter SDK dengan Dart.
- Riverpod untuk state management.
- GoRouter untuk navigasi.
- Dio dan HTTP untuk komunikasi API.
- Shared Preferences untuk penyimpanan token lokal.
- fl_chart untuk visualisasi chart.
- image_picker untuk pemilihan gambar.

### Backend

- Laravel 12.
- PHP 8.2 atau lebih baru.
- Laravel Sanctum untuk autentikasi token.
- MySQL sebagai basis data utama.
- PHPUnit untuk pengujian backend.

## 3. Struktur Direktori Penting

```text
lib/
  main.dart
  src/
    app.dart
    router/
    theme/
    core/
    common/
    features/
      auth/
      dashboard/
      activities/
      gamification/
      leaderboard/
      voting/
      discussion/
      ormawa/

backend-api/
  app/
    Http/Controllers/Api/
    Http/Requests/
    Http/Resources/
    Models/
    Services/
    Support/
  database/
    migrations/
    seeders/
  routes/
    api.php

docs/
  erd.dbml
  struktur_tabel.md
  dokumentasi_teknis.md
  ringkasan_bimbingan_dosen.md

test/
  pages/
  features/
```

## 4. Arsitektur Umum

Arsitektur sistem dipisahkan menjadi frontend dan backend.

Frontend Flutter menggunakan pendekatan feature-based structure. Setiap fitur memiliki lapisan data, domain, dan presentation jika dibutuhkan. Lapisan presentation berisi halaman, widget, dan provider. Lapisan domain berisi entity dan repository contract. Lapisan data berisi implementasi repository dan komunikasi API.

Backend Laravel menyediakan REST API. Controller menerima request, melakukan validasi melalui Form Request atau validator lokal, memanggil model/service, lalu mengembalikan response JSON menggunakan format response yang konsisten.

Alur data umum:

```text
User Interface Flutter
  -> Riverpod Controller/Provider
  -> Repository
  -> Dio HTTP Client
  -> Laravel API Route
  -> Controller
  -> Model/Service
  -> Database
  -> JSON Response
  -> Repository
  -> UI State
```

## 5. Role dan Hak Akses

Sistem memiliki tiga role utama.

| Role | Fungsi Utama | Contoh Akses |
| --- | --- | --- |
| admin | Mengelola sistem di tingkat fakultas | Verifikasi kegiatan, kelola user, kelola ormawa, reset periode |
| ormawa | Mengelola data organisasi | Buat kegiatan, buat voting, verifikasi anggota ormawa |
| anggota | Berpartisipasi dalam sistem | Melihat kegiatan, diskusi, like, voting, leaderboard |

Hak akses backend diterapkan melalui middleware `auth:sanctum` dan `role`. Endpoint sensitif dibatasi dengan role tertentu.

## 6. Modul Frontend

### 6.1 Auth

Lokasi utama:

- `lib/src/features/auth/`
- `lib/src/features/auth/data/datasources/auth_remote_data_source.dart`
- `lib/src/features/auth/presentation/pages/login_page.dart`
- `lib/src/features/auth/presentation/pages/register_page.dart`

Fungsi:

- Login user.
- Register anggota.
- Menyimpan token autentikasi.
- Memetakan role backend ke role frontend.
- Mengarahkan user ke dashboard sesuai role.

### 6.2 Dashboard

Lokasi utama:

- `lib/src/features/dashboard/`

Fungsi:

- Dashboard admin fakultas.
- Dashboard ormawa.
- Dashboard anggota.
- Ringkasan jumlah kegiatan, poin, peringkat, aktivitas bulanan, notifikasi, dan status periode.
- Halaman profil, pengaturan, achievement, chat, dan leaderboard.

### 6.3 Activities

Lokasi utama:

- `lib/src/features/activities/`

Fungsi:

- Menampilkan feed kegiatan.
- Mengambil data kegiatan dari API.
- Mendukung status kegiatan seperti `pending`, `valid`, dan `ditolak`.
- Menjadi sumber interaksi komentar, like, dan dokumentasi.

### 6.4 Voting

Lokasi utama:

- `lib/src/features/voting/`

Fungsi:

- Menampilkan daftar voting.
- Membuat voting dengan opsi polling.
- Melakukan vote pada periode aktif.
- Mencegah vote ganda melalui backend.

### 6.5 Leaderboard dan Gamification

Lokasi utama:

- `lib/src/features/leaderboard/`
- `lib/src/features/gamification/`
- `lib/src/core/utils/level_calculator.dart`

Fungsi:

- Menampilkan peringkat individu dan ormawa.
- Menghitung level user berdasarkan poin.
- Menampilkan highlight user, podium, rank list, dan badge/achievement.

## 7. Routing Frontend

Konfigurasi route berada di `lib/src/router/app_router.dart`.

| Path | Halaman |
| --- | --- |
| `/login` | Login |
| `/register` | Register |
| `/admin` | Dashboard Admin |
| `/ormawa` | Dashboard Ormawa |
| `/ormawa/members` | Manajemen Anggota Ormawa |
| `/member` | Dashboard Anggota |
| `/activities` | Feed Kegiatan |
| `/leaderboard` | Leaderboard |
| `/achievement` | Achievement |
| `/chat` | Chat |
| `/profile` | Profil |
| `/settings` | Pengaturan |
| `/voting` | Voting |

## 8. Konfigurasi API Frontend

Konfigurasi base URL berada di `lib/src/core/config/api_config.dart`.

Perilaku default:

- Android emulator: `http://10.0.2.2:8000/api`
- Platform lain: `http://127.0.0.1:8000/api`
- Bisa dioverride dengan compile-time environment `API_BASE_URL`.

Contoh menjalankan Flutter dengan base URL khusus:

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

## 9. Modul Backend

### 9.1 AuthController

Endpoint utama:

- `POST /api/register`
- `POST /api/login`
- `GET /api/profile`
- `POST /api/logout`

Catatan:

- Register membuat akun dengan role `anggota`.
- Akun baru memiliki status `pending` jika memilih ormawa.
- Login hanya berhasil jika `status_akun` bernilai `aktif`.
- Token dibuat menggunakan Laravel Sanctum.

### 9.2 KegiatanController

Fungsi:

- Menampilkan daftar kegiatan.
- Membuat kegiatan baru.
- Mengubah kegiatan.
- Menghapus kegiatan.
- Verifikasi kegiatan oleh admin.

Aturan penting:

- Ormawa hanya bisa mengakses kegiatan milik ormawanya.
- Anggota dapat melihat kegiatan.
- Kegiatan baru disimpan sebagai `pending`.
- Saat kegiatan diverifikasi `valid`, sistem menambahkan poin ormawa melalui `PoinService`.

### 9.3 LeaderboardController

Fungsi:

- Menghasilkan leaderboard individu dan ormawa.
- Menyimpan snapshot leaderboard ke tabel `leaderboards` dan `leaderboard_details`.

Parameter:

- `tipe=individu`
- `tipe=ormawa`
- `periode=all_time` atau nama periode tertentu.

### 9.4 PeriodController

Fungsi:

- Mengambil periode aktif.
- Mengakhiri periode berjalan.
- Membuat snapshot poin user dan ormawa.
- Mengarsipkan periode lama.
- Mereset poin user anggota dan total poin ormawa.
- Membuat periode aktif berikutnya.

Endpoint:

- `GET /api/periods/current`
- `POST /api/periods/end-current`

### 9.5 VotingController dan VoteDetailController

Fungsi:

- Membuat voting.
- Mengatur opsi polling.
- Menampilkan detail voting.
- Mencatat pilihan user.

Aturan penting:

- Voting hanya bisa dipilih saat status `aktif` dan tanggal berada dalam rentang voting.
- User hanya bisa vote satu kali pada satu voting.
- Pilihan harus termasuk dalam `poll_options`.
- Vote berhasil memberi 1 poin kepada user.

### 9.6 DiskusiController

Fungsi:

- Menampilkan komentar berdasarkan kegiatan.
- Membuat komentar dan balasan.
- Menghapus komentar.

Aturan poin:

- Anggota yang menulis komentar mendapat 15 poin.
- Ormawa yang membalas komentar mendapat 2 poin ormawa.

### 9.7 LikeKegiatanController

Fungsi:

- Memberi like pada kegiatan.
- Menghapus like.

Aturan poin:

- Like pertama pada kegiatan memberi 1 poin kepada user.
- Like menggunakan `firstOrCreate`, sehingga like ganda tidak menambah poin.

### 9.8 UserController

Fungsi:

- Admin mengelola user.
- Ormawa melihat anggota yang memilih ormawanya.
- Ormawa mengubah status anggota menjadi `aktif`, `nonaktif`, atau `ditolak`.
- Admin dapat menghitung ulang poin user.

## 10. Endpoint API

### Endpoint Publik

| Method | Endpoint | Fungsi |
| --- | --- | --- |
| POST | `/api/register` | Registrasi anggota |
| POST | `/api/login` | Login dan mendapatkan token |
| GET | `/api/ormawas` | Daftar ormawa |
| GET | `/api/ormawas/{id}` | Detail ormawa |

### Endpoint Autentikasi

Semua endpoint berikut membutuhkan header:

```text
Authorization: Bearer {token}
```

| Method | Endpoint | Role | Fungsi |
| --- | --- | --- | --- |
| POST | `/api/logout` | semua | Logout |
| GET | `/api/profile` | semua | Profil user |
| GET | `/api/leaderboard` | semua | Leaderboard |
| GET | `/api/kegiatans` | semua | Daftar kegiatan |
| GET | `/api/kegiatans/{id}` | semua sesuai akses | Detail kegiatan |
| GET | `/api/votings` | semua | Daftar voting |
| GET | `/api/votings/{id}` | semua | Detail voting |
| GET | `/api/diskusis` | semua | Daftar diskusi |
| POST | `/api/diskusis` | semua | Tambah komentar |
| DELETE | `/api/diskusis/{id}` | pemilik/admin | Hapus komentar |
| POST | `/api/like-kegiatans` | semua | Like kegiatan |
| DELETE | `/api/like-kegiatans/{id}` | pemilik/admin | Hapus like |
| GET | `/api/chats` | semua | Daftar chat |
| POST | `/api/chats` | semua | Kirim chat |
| PUT/PATCH | `/api/chats/{id}` | semua sesuai akses | Update chat |
| POST | `/api/vote-details` | anggota | Vote |

### Endpoint Admin

| Method | Endpoint | Fungsi |
| --- | --- | --- |
| GET | `/api/users` | Daftar user |
| PUT/PATCH | `/api/users/{id}` | Update user |
| PATCH | `/api/users/{id}/recalculate-poin` | Hitung ulang poin user |
| POST/PUT/PATCH/DELETE | `/api/ormawas` | Kelola ormawa |
| GET | `/api/periods/current` | Status periode |
| POST | `/api/periods/end-current` | Akhiri periode dan reset poin |
| GET | `/api/poin-logs` | Riwayat poin |
| PATCH | `/api/ormawas/{id}/recalculate-poin` | Hitung ulang poin ormawa |
| PATCH | `/api/kegiatans/{id}/verifikasi` | Verifikasi kegiatan |

### Endpoint Admin dan Ormawa

| Method | Endpoint | Fungsi |
| --- | --- | --- |
| POST | `/api/kegiatans` | Buat kegiatan |
| PUT/PATCH | `/api/kegiatans/{id}` | Update kegiatan |
| DELETE | `/api/kegiatans/{id}` | Hapus kegiatan |
| POST | `/api/votings` | Buat voting |
| PUT/PATCH | `/api/votings/{id}` | Update voting |
| DELETE | `/api/votings/{id}` | Hapus voting |

### Endpoint Ormawa

| Method | Endpoint | Fungsi |
| --- | --- | --- |
| GET | `/api/ormawa/members` | Daftar anggota yang memilih ormawa |
| PATCH | `/api/ormawa/members/{id}` | Update status anggota |

## 11. Basis Data

Dokumen basis data detail tersedia di:

- `docs/erd.dbml`
- `docs/struktur_tabel.md`

Tabel domain utama:

- `users`
- `ormawas`
- `kategori_kegiatans`
- `kegiatans`
- `dokumentasi_kegiatans`
- `verifikasis`
- `votings`
- `vote_details`
- `diskusis`
- `like_kegiatans`
- `chats`
- `poin_logs`
- `leaderboards`
- `leaderboard_details`
- `penilaians`
- `badges`
- `ormawa_badges`
- `periods`
- `user_points`
- `organization_points`
- `point_histories`
- `personal_access_tokens`

## 12. Mekanisme Gamifikasi

Gamifikasi dibangun dari empat komponen utama.

### 12.1 Poin

Poin dicatat pada tabel `poin_logs`. Setiap log memiliki:

- periode aktif,
- target user atau ormawa,
- sumber poin,
- referensi data sumber,
- nilai poin,
- keterangan,
- tanggal.

Sumber poin yang sudah digunakan:

| Sumber | Target | Poin | Trigger |
| --- | --- | ---: | --- |
| kegiatan | ormawa | sesuai `poin_kegiatan` | Admin memvalidasi kegiatan |
| komentar | user anggota | 15 | Anggota menulis komentar diskusi |
| balasan | ormawa | 2 | Ormawa membalas diskusi |
| voting | user anggota | 1 | Anggota melakukan vote |
| like | user anggota | 1 | User memberi like kegiatan |

### 12.2 Leaderboard

Leaderboard memiliki dua tipe:

- Individu: berdasarkan poin user anggota.
- Ormawa: berdasarkan total poin ormawa, termasuk poin langsung ormawa dan kontribusi poin anggota pada ormawa tersebut.

Snapshot leaderboard disimpan ke tabel:

- `leaderboards`
- `leaderboard_details`

### 12.3 Badge dan Achievement

Badge awal disediakan melalui seeder:

| Badge | Minimal Poin | Deskripsi |
| --- | ---: | --- |
| First Vote | 2 | Partisipasi awal dalam voting |
| Active Participant | 50 | Aktif berpartisipasi |
| Event Leader | 100 | Memimpin kegiatan/event |
| Top Contributor | 250 | Kontributor dengan poin tinggi |

### 12.4 Periode

Periode gamifikasi digunakan untuk membatasi akumulasi poin pada rentang waktu tertentu dan disarankan mengikuti satu semester. Saat periode diakhiri:

1. Sistem membuat snapshot peringkat user dan ormawa.
2. Periode aktif diarsipkan.
3. Poin anggota dan ormawa direset.
4. Periode baru dibuat sebagai periode aktif.

Periode gamifikasi berbeda dari rentang penilaian Ormawa Awards. Rentang penilaian dapat dibuat bulanan dan hanya menyaring data yang dinilai; menyimpan hasil Ormawa Awards tidak mengakhiri periode gamifikasi dan tidak mereset poin.

## 13. Status Penting

### Status Akun

- `pending`: menunggu verifikasi ormawa.
- `aktif`: dapat login dan menggunakan sistem.
- `nonaktif`: akun tidak aktif.
- `ditolak`: akun anggota tidak disetujui.

### Status Kegiatan

- `pending`: kegiatan menunggu verifikasi.
- `valid`: kegiatan disetujui.
- `ditolak`: kegiatan ditolak.

### Status Voting

- `aktif`: voting dapat digunakan jika tanggal masih dalam rentang.
- `selesai`: voting ditutup.

## 14. Alur Utama Sistem

### 14.1 Registrasi dan Verifikasi Anggota

1. Anggota mendaftar melalui frontend.
2. Backend membuat user role `anggota` dengan status `pending`.
3. Ormawa membuka daftar anggota pada `/ormawa/members`.
4. Ormawa mengubah status menjadi `aktif` atau `ditolak`.
5. User hanya bisa login setelah status menjadi `aktif`.

### 14.2 Pengajuan dan Verifikasi Kegiatan

1. Ormawa membuat kegiatan.
2. Kegiatan otomatis berstatus `pending`.
3. Admin melihat daftar kegiatan pending.
4. Admin memvalidasi atau menolak kegiatan.
5. Jika valid, poin kegiatan ditambahkan ke ormawa.
6. Leaderboard ormawa akan memperhitungkan poin terbaru.

### 14.3 Interaksi Anggota

1. Anggota login.
2. Anggota melihat feed kegiatan.
3. Anggota dapat memberi komentar, like, atau mengikuti voting.
4. Sistem mencatat poin sesuai aktivitas.
5. Poin user dan total poin ormawa diperbarui.

### 14.4 Reset Periode

1. Admin membuka status periode.
2. Admin mengakhiri periode aktif.
3. Sistem menyimpan snapshot user dan ormawa.
4. Sistem mengarsipkan periode lama.
5. Sistem mereset poin dan membuat periode baru.

## 15. Instalasi dan Menjalankan Proyek

### 15.1 Backend Laravel

Masuk ke folder backend:

```bash
cd backend-api
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve
```

Pastikan konfigurasi database pada `.env` sudah sesuai.

Contoh konfigurasi umum:

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=sistem_manajemen_dan_gamifikasi
DB_USERNAME=root
DB_PASSWORD=
```

### 15.2 Frontend Flutter

Dari root project:

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

Untuk Android emulator, base URL default sudah diarahkan ke:

```text
http://10.0.2.2:8000/api
```

## 16. Testing

### Frontend

Test frontend berada di:

- `test/pages/all_pages_smoke_test.dart`
- `test/features/auth/auth_controller_test.dart`

Perintah:

```bash
flutter test
```

Smoke test memastikan halaman utama dapat dirender tanpa exception, termasuk login, dashboard admin, dashboard ormawa, dashboard anggota, activity list, leaderboard, achievement, chat, profile, settings, dan voting.

### Backend

Test backend berada di:

- `backend-api/tests/`

Perintah:

```bash
cd backend-api
php artisan test
```

## 17. Risiko Teknis dan Catatan Pengembangan

Beberapa hal yang perlu diperhatikan untuk pengembangan lanjutan:

- Konsistensi status akun perlu dijaga karena register membuat status `pending`, sementara login hanya mengizinkan `aktif`.
- Poin berbasis aktivitas sebaiknya selalu dicatat melalui `PoinService` agar log, total user, dan total ormawa tetap konsisten.
- Endpoint leaderboard menyimpan snapshot setiap kali dipanggil. Jika traffic meningkat, proses snapshot dapat dipindah ke job terjadwal.
- Upload dokumentasi kegiatan perlu dipastikan strategi penyimpanannya, misalnya local storage, public disk, atau cloud storage.
- Badge sudah memiliki data seeder, tetapi mekanisme pemberian otomatis dapat diperluas.
- Pengujian backend saat ini masih perlu diperluas untuk skenario role, verifikasi kegiatan, voting ganda, dan reset periode.

## 18. Rekomendasi Pengembangan Berikutnya

- Menambahkan API dashboard khusus agar frontend tidak perlu menghitung banyak summary dari beberapa endpoint.
- Menambahkan audit log untuk aksi admin dan ormawa.
- Menambahkan test feature Laravel untuk alur penting: login, registrasi, verifikasi anggota, verifikasi kegiatan, vote, dan reset periode.
- Menambahkan dokumentasi Postman atau OpenAPI.
- Menambahkan mekanisme auto-award badge berdasarkan poin.
- Menambahkan validasi file upload dokumentasi kegiatan.
- Menambahkan pagination untuk data kegiatan, user, diskusi, dan leaderboard.
