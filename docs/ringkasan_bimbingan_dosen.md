# Ringkasan Bimbingan Dosen

Tanggal ringkasan: 22 Juni 2026

## Judul Sistem

Sistem Manajemen dan Gamifikasi Ormawa.

## Deskripsi Singkat

Sistem ini adalah aplikasi berbasis Flutter dan Laravel API untuk mengelola aktivitas organisasi mahasiswa. Aplikasi menyediakan fitur pengajuan kegiatan, verifikasi kegiatan oleh admin fakultas, voting digital, diskusi, like, chat, leaderboard, poin, badge, dan reset periode.

Fokus utama sistem adalah menggabungkan manajemen kegiatan ormawa dengan gamifikasi agar partisipasi mahasiswa dan organisasi dapat dipantau secara lebih terukur.

## Aktor Sistem

| Aktor | Peran |
| --- | --- |
| Admin fakultas | Memverifikasi kegiatan, mengelola user, ormawa, poin, dan periode |
| Ormawa | Membuat kegiatan, membuat voting, membalas diskusi, dan memverifikasi anggota |
| Anggota | Melihat kegiatan, komentar, like, voting, dan mengikuti leaderboard |

## Fitur Utama

1. Autentikasi dan otorisasi berbasis role.
2. Registrasi anggota dengan verifikasi oleh ormawa.
3. Manajemen kegiatan ormawa.
4. Verifikasi kegiatan oleh admin.
5. Voting digital berbasis periode waktu.
6. Diskusi dan like pada kegiatan.
7. Chat antar user.
8. Leaderboard individu dan ormawa.
9. Sistem poin, badge, level, dan achievement.
10. Reset periode untuk mengarsipkan hasil dan memulai kompetisi baru.

## Teknologi yang Digunakan

| Bagian | Teknologi |
| --- | --- |
| Frontend | Flutter, Dart, Riverpod, GoRouter, Dio |
| Backend | Laravel 12, PHP 8.2, Laravel Sanctum |
| Database | MySQL |
| Testing | Flutter Test, PHPUnit |
| Dokumentasi database | DBML dan Markdown |

## Alur Sistem Utama

### Registrasi Anggota

1. Anggota mendaftar dan memilih ormawa.
2. Status akun menjadi `pending`.
3. Ormawa memverifikasi anggota.
4. Akun yang disetujui berubah menjadi `aktif`.
5. Anggota dapat login dan menggunakan sistem.

### Pengajuan Kegiatan

1. Ormawa membuat kegiatan.
2. Kegiatan masuk dengan status `pending`.
3. Admin memeriksa kegiatan.
4. Admin memberi status `valid` atau `ditolak`.
5. Jika valid, poin kegiatan masuk ke poin ormawa.

### Gamifikasi

1. Anggota mendapat poin dari komentar, voting, dan like.
2. Ormawa mendapat poin dari kegiatan valid dan balasan diskusi.
3. Poin disimpan dalam `poin_logs`.
4. Leaderboard menampilkan peringkat individu dan ormawa.
5. Periode dapat diakhiri untuk menyimpan snapshot dan mereset poin.

## Mekanisme Poin

| Aktivitas | Penerima | Poin |
| --- | --- | ---: |
| Kegiatan tervalidasi | Ormawa | Sesuai poin kegiatan |
| Komentar diskusi | Anggota | 15 |
| Balasan diskusi | Ormawa | 2 |
| Voting | Anggota | 1 |
| Like kegiatan | Anggota | 1 |

## Pembeda Sistem

- Tidak hanya menyimpan data kegiatan, tetapi juga mendorong partisipasi melalui poin dan leaderboard.
- Ada pembagian role yang jelas antara admin, ormawa, dan anggota.
- Ada mekanisme periode sehingga leaderboard dapat diarsipkan dan dimulai ulang.
- Poin ormawa mempertimbangkan kontribusi langsung ormawa dan aktivitas anggota yang berada di ormawa tersebut.

## Struktur Data Utama

Tabel penting:

- `users`
- `ormawas`
- `kegiatans`
- `verifikasis`
- `votings`
- `vote_details`
- `diskusis`
- `like_kegiatans`
- `chats`
- `poin_logs`
- `leaderboards`
- `leaderboard_details`
- `badges`
- `periods`
- `user_points`
- `organization_points`

Dokumen ERD tersedia di `docs/erd.dbml` dan penjelasan tabel tersedia di `docs/struktur_tabel.md`.

## Progres Implementasi

Bagian yang sudah tersedia di source code:

- Frontend Flutter dengan halaman login, register, dashboard admin, dashboard ormawa, dashboard anggota, activity list, leaderboard, achievement, chat, profil, pengaturan, dan voting.
- Backend Laravel API dengan autentikasi Sanctum.
- Endpoint role-based untuk admin, ormawa, dan anggota.
- Model dan migration database domain utama.
- Service poin terpusat melalui `PoinService`.
- Seeder kategori kegiatan dan badge.
- Smoke test halaman frontend.

## Rencana Lanjutan

1. Menambah test backend untuk alur kritis.
2. Menambah dokumentasi API dalam format Postman atau OpenAPI.
3. Menyempurnakan mekanisme pemberian badge otomatis.
4. Menambahkan pagination untuk data yang berpotensi besar.
5. Menyempurnakan fitur upload dokumentasi kegiatan.
6. Mengoptimalkan proses snapshot leaderboard jika jumlah user meningkat.

## Poin Diskusi Saat Bimbingan

- Apakah pembagian role admin, ormawa, dan anggota sudah sesuai kebutuhan kampus?
- Apakah skema poin perlu disesuaikan dengan bobot kegiatan akademik/non-akademik?
- Apakah periode leaderboard sebaiknya semesteran, tahunan, atau berdasarkan event tertentu?
- Apakah badge cukup berbasis poin, atau perlu syarat tambahan seperti jumlah kegiatan dan konsistensi partisipasi?
- Apakah data yang ditampilkan di dashboard sudah cukup untuk kebutuhan monitoring dosen/admin?

