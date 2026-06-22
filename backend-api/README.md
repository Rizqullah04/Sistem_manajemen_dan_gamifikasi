# Ormawa Awards Backend API

Backend REST API Laravel untuk aplikasi mobile Flutter "Ormawa Awards". API memakai Laravel 12, MySQL, dan Laravel Sanctum token auth. Tidak ada Blade UI.

## Fitur

- Auth mobile: register, login, logout, profile
- Role user: `admin`, `ormawa`, `juri`
- CRUD ormawa
- CRUD kategori kegiatan
- CRUD kegiatan dengan upload bukti
- Verifikasi kegiatan oleh admin
- Penilaian kegiatan oleh juri
- CRUD badge
- Badge otomatis saat total poin ormawa mencapai `minimal_poin`
- Leaderboard berdasarkan total poin

## Setup Dari Awal

```bash
cd backend-api
composer install
cp .env.example .env
php artisan key:generate
php artisan storage:link
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8000
```

## Setup Dengan Database MySQL Yang Sudah Ada

Kalau kamu sudah import `ormawa_awards.sql` ke MySQL/phpMyAdmin, jangan jalankan `migrate:fresh` karena itu akan menghapus tabel lama.

Pakai langkah ini:

```bash
cd backend-api
composer install
cp .env.example .env
php artisan key:generate
php artisan storage:link
php artisan migrate --path=database/migrations/2026_04_28_064232_create_personal_access_tokens_table.php
php artisan serve --host=0.0.0.0 --port=8000
```

Kenapa masih perlu migrate satu file? File SQL kamu sudah punya tabel utama aplikasi, tetapi belum punya tabel Sanctum `personal_access_tokens`. Tabel itu wajib untuk login token Flutter.

Untuk reset database lokal:

```bash
php artisan migrate:fresh --seed
```

Admin bawaan dari seeder:

```text
email: admin@ormawa-awards.test
password: password
```

## Contoh .env MySQL

```env
APP_NAME="Ormawa Awards API"
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost:8000

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=ormawa_awards
DB_USERNAME=root
DB_PASSWORD=

SESSION_DRIVER=file
QUEUE_CONNECTION=sync
CACHE_STORE=file
FILESYSTEM_DISK=public
```

Buat database MySQL dahulu:

```sql
CREATE DATABASE ormawa_awards;
```

Untuk Android emulator, gunakan base URL:

```text
http://10.0.2.2:8000/api
```

Untuk device fisik, gunakan IP laptop di jaringan yang sama:

```text
http://192.168.x.x:8000/api
```

## Format Response

Semua endpoint memakai format:

```json
{
  "status": true,
  "message": "Pesan berhasil",
  "data": {}
}
```

Untuk endpoint protected, kirim header:

```http
Authorization: Bearer TOKEN_SANCTUM
Accept: application/json
```

Untuk upload file dari Flutter, gunakan `multipart/form-data`.

## Endpoint API

### Authentication

| Method | Endpoint | Role | Keterangan |
| --- | --- | --- | --- |
| POST | `/api/register` | public | Register user |
| POST | `/api/login` | public | Login user |
| POST | `/api/logout` | auth | Logout token aktif |
| GET | `/api/profile` | auth | Profile user |

### Ormawa

| Method | Endpoint | Role |
| --- | --- | --- |
| GET | `/api/ormawas` | auth |
| POST | `/api/ormawas` | admin |
| GET | `/api/ormawas/{id}` | auth |
| POST/PATCH | `/api/ormawas/{id}` | admin |
| DELETE | `/api/ormawas/{id}` | admin |

Gunakan POST dengan `_method=PATCH` untuk update multipart upload dari Flutter bila client sulit mengirim PATCH multipart.

### Kategori Kegiatan

| Method | Endpoint | Role |
| --- | --- | --- |
| GET | `/api/kategori-kegiatans` | auth |
| POST | `/api/kategori-kegiatans` | admin |
| GET | `/api/kategori-kegiatans/{id}` | auth |
| PUT/PATCH | `/api/kategori-kegiatans/{id}` | admin |
| DELETE | `/api/kategori-kegiatans/{id}` | admin |

### Kegiatan

| Method | Endpoint | Role |
| --- | --- | --- |
| GET | `/api/kegiatans` | admin, ormawa |
| POST | `/api/kegiatans` | admin, ormawa |
| GET | `/api/kegiatans/{id}` | admin, ormawa |
| POST/PATCH | `/api/kegiatans/{id}` | admin, ormawa |
| DELETE | `/api/kegiatans/{id}` | admin, ormawa |
| PATCH | `/api/kegiatans/{id}/verifikasi` | admin |

Filter list kegiatan:

```text
GET /api/kegiatans?status=menunggu
GET /api/kegiatans?ormawa_id=1
```

### Penilaian Juri

| Method | Endpoint | Role |
| --- | --- | --- |
| GET | `/api/penilaians` | juri |
| POST | `/api/penilaians` | juri |
| GET | `/api/penilaians/{id}` | juri |
| PUT/PATCH | `/api/penilaians/{id}` | juri |
| DELETE | `/api/penilaians/{id}` | juri |

Filter:

```text
GET /api/penilaians?kegiatan_id=1
```

### Badge

| Method | Endpoint | Role |
| --- | --- | --- |
| GET | `/api/badges` | auth |
| POST | `/api/badges` | admin |
| GET | `/api/badges/{id}` | auth |
| PUT/PATCH | `/api/badges/{id}` | admin |
| DELETE | `/api/badges/{id}` | admin |

### Leaderboard

| Method | Endpoint | Role |
| --- | --- | --- |
| GET | `/api/leaderboard` | auth |

## Contoh Request dan Response

### Register

```http
POST /api/register
Content-Type: application/json
Accept: application/json
```

```json
{
  "name": "Juri Satu",
  "email": "juri@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "role": "juri"
}
```

Response:

```json
{
  "status": true,
  "message": "Register berhasil",
  "data": {
    "user": {
      "id": 2,
      "name": "Juri Satu",
      "email": "juri@example.com",
      "role": "juri"
    },
    "token": "1|token-sanctum",
    "token_type": "Bearer"
  }
}
```

### Login

```json
{
  "email": "admin@ormawa-awards.test",
  "password": "password"
}
```

Response:

```json
{
  "status": true,
  "message": "Login berhasil",
  "data": {
    "user": {
      "id": 1,
      "name": "Admin Ormawa Awards",
      "email": "admin@ormawa-awards.test",
      "role": "admin"
    },
    "token": "1|token-sanctum",
    "token_type": "Bearer"
  }
}
```

### Buat Ormawa

```http
POST /api/ormawas
Authorization: Bearer TOKEN_ADMIN
Content-Type: multipart/form-data
```

Field:

```text
user_id=3
nama_ormawa=BEM Fakultas
nama_ketua=Andi
pembina=Dr. Sari
periode=2026
logo=@logo.png
```

### Buat Kegiatan

```http
POST /api/kegiatans
Authorization: Bearer TOKEN_ORMAWA
Content-Type: multipart/form-data
```

Field:

```text
ormawa_id=1
kategori_id=1
nama_kegiatan=Seminar Kepemimpinan
tanggal_kegiatan=2026-04-28
lokasi=Aula Kampus
deskripsi=Seminar kepemimpinan mahasiswa.
bukti_file=@proposal.pdf
```

Response ringkas:

```json
{
  "status": true,
  "message": "Kegiatan berhasil dibuat",
  "data": {
    "id": 1,
    "status": "menunggu",
    "poin": 0
  }
}
```

### Verifikasi Kegiatan

```http
PATCH /api/kegiatans/1/verifikasi
Authorization: Bearer TOKEN_ADMIN
Content-Type: application/json
```

```json
{
  "status": "disetujui",
  "catatan_verifikasi": "Bukti valid."
}
```

Jika disetujui, `poin` otomatis mengikuti `poin_dasar` kategori dan badge ormawa dihitung ulang.

### Penilaian Juri

```http
POST /api/penilaians
Authorization: Bearer TOKEN_JURI
Content-Type: application/json
```

```json
{
  "kegiatan_id": 1,
  "nilai_kreativitas": 85,
  "nilai_dampak": 90,
  "nilai_partisipasi": 80,
  "nilai_publikasi": 75,
  "komentar": "Kegiatan berdampak baik."
}
```

Response:

```json
{
  "status": true,
  "message": "Penilaian berhasil disimpan",
  "data": {
    "kegiatan_id": 1,
    "juri_id": 2,
    "nilai_kreativitas": 85,
    "nilai_dampak": 90,
    "nilai_partisipasi": 80,
    "nilai_publikasi": 75,
    "total_nilai": 330,
    "komentar": "Kegiatan berdampak baik."
  }
}
```

### Leaderboard

```http
GET /api/leaderboard
Authorization: Bearer TOKEN
Accept: application/json
```

Response:

```json
{
  "status": true,
  "message": "Leaderboard berhasil diambil",
  "data": [
    {
      "nama_ormawa": "BEM Fakultas",
      "total_poin": 500,
      "total_kegiatan": 4,
      "badge": ["Starter Ormawa", "Aktif Berkegiatan"],
      "peringkat": 1
    }
  ]
}
```

## Catatan Flutter

Contoh header Dio/http:

```dart
final headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer $token',
};
```

Untuk upload:

```dart
final formData = FormData.fromMap({
  'ormawa_id': 1,
  'kategori_id': 1,
  'nama_kegiatan': 'Seminar Kepemimpinan',
  'tanggal_kegiatan': '2026-04-28',
  'lokasi': 'Aula Kampus',
  'deskripsi': 'Seminar kepemimpinan mahasiswa.',
  'bukti_file': await MultipartFile.fromFile(file.path),
});
```
