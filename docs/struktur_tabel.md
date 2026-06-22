# Urutan Struktur Tabel Database

Urutan ini disusun berdasarkan migration Laravel dan ketergantungan foreign key, sehingga tabel induk diletakkan sebelum tabel anak.

## 1. users

Menyimpan data akun pengguna.

- `id_user` sebagai primary key
- `id_ormawa` relasi ke `ormawas`, nullable
- Digunakan oleh banyak tabel lain seperti `admin_profiles`, `verifikasis`, `vote_details`, `diskusis`, `like_kegiatans`, `chats`, `poin_logs`, `leaderboard_details`, dan `penilaians`

## 2. ormawas

Menyimpan data organisasi mahasiswa.

- `id_ormawa` sebagai primary key
- Menjadi induk untuk `users`, `kegiatans`, `dokumentasi_kegiatans`, `votings`, `poin_logs`, `leaderboard_details`, dan `ormawa_badges`

## 3. kategori_kegiatans

Menyimpan master kategori kegiatan.

- `id` sebagai primary key
- `nama_kategori` bersifat unique
- Menjadi induk untuk `kegiatans` melalui kolom `kategori_id`

## 4. admin_profiles

Menyimpan detail tambahan untuk user yang berperan sebagai admin.

- `id_admin_profile` sebagai primary key
- `id_user` relasi one-to-one ke `users`

## 5. badges

Menyimpan master badge yang bisa diperoleh ormawa.

- `id` sebagai primary key
- `nama_badge` bersifat unique
- Menjadi induk untuk `ormawa_badges`

## 6. kegiatans

Menyimpan data kegiatan yang dibuat oleh ormawa.

- `id_kegiatan` sebagai primary key
- `id_ormawa` relasi ke `ormawas`
- `kategori_id` relasi ke `kategori_kegiatans`, nullable
- Menjadi induk untuk `dokumentasi_kegiatans`, `verifikasis`, `votings`, `diskusis`, `like_kegiatans`, dan `penilaians`

## 7. dokumentasi_kegiatans

Menyimpan file atau dokumentasi kegiatan.

- `id_dokumentasi` sebagai primary key
- `id_kegiatan` relasi ke `kegiatans`
- `id_ormawa` relasi ke `ormawas`

## 8. verifikasis

Menyimpan proses verifikasi kegiatan oleh admin.

- `id_verifikasi` sebagai primary key
- `id_kegiatan` relasi ke `kegiatans`
- `id_admin` relasi ke `users`

## 9. penilaians

Menyimpan nilai kegiatan dari juri/admin.

- `id` sebagai primary key
- `kegiatan_id` relasi ke `kegiatans`
- `juri_id` relasi ke `users`
- Kombinasi `kegiatan_id` dan `juri_id` bersifat unique

## 10. votings

Menyimpan data voting yang berhubungan dengan kegiatan.

- `id_voting` sebagai primary key
- `id_kegiatan` relasi ke `kegiatans`
- `id_ormawa` relasi ke `ormawas`, nullable
- Menjadi induk untuk `vote_details`

## 11. vote_details

Menyimpan detail pilihan user dalam voting.

- `id_vote` sebagai primary key
- `id_voting` relasi ke `votings`
- `id_user` relasi ke `users`
- Kombinasi `id_voting` dan `id_user` bersifat unique

## 12. diskusis

Menyimpan komentar atau diskusi pada kegiatan.

- `id_diskusi` sebagai primary key
- `id_kegiatan` relasi ke `kegiatans`
- `id_user` relasi ke `users`
- `parent_id` relasi ke `diskusis.id_diskusi` untuk balasan komentar

## 13. like_kegiatans

Menyimpan data like dari user pada kegiatan.

- `id_like` sebagai primary key
- `id_kegiatan` relasi ke `kegiatans`
- `id_user` relasi ke `users`
- Kombinasi `id_kegiatan` dan `id_user` bersifat unique

## 14. chats

Menyimpan pesan antar user.

- `id_chat` sebagai primary key
- `id_pengirim` relasi ke `users`
- `id_penerima` relasi ke `users`

## 15. poin_logs

Menyimpan riwayat perubahan poin.

- `id_poin_log` sebagai primary key
- `id_user` relasi ke `users`, nullable
- `id_ormawa` relasi ke `ormawas`, nullable
- `referensi_id` menyimpan ID sumber poin, tetapi tidak dibuat sebagai foreign key langsung karena sumbernya bisa berbeda-beda

## 16. leaderboards

Menyimpan data header leaderboard.

- `id_leaderboard` sebagai primary key
- Menjadi induk untuk `leaderboard_details`

## 17. leaderboard_details

Menyimpan detail ranking leaderboard.

- `id_detail` sebagai primary key
- `id_leaderboard` relasi ke `leaderboards`
- `id_user` relasi ke `users`, nullable
- `id_ormawa` relasi ke `ormawas`, nullable
- Constraint: hanya salah satu dari `id_user` atau `id_ormawa` yang boleh terisi

## 18. ormawa_badges

Menyimpan badge yang sudah diperoleh tiap ormawa.

- `id` sebagai primary key
- `ormawa_id` relasi ke `ormawas`
- `badge_id` relasi ke `badges`
- Kombinasi `ormawa_id` dan `badge_id` bersifat unique

## 19. personal_access_tokens

Menyimpan token autentikasi Laravel Sanctum.

- `id` sebagai primary key
- `tokenable_type` dan `tokenable_id` digunakan untuk relasi polymorphic ke model pemilik token

## Tabel Teknis Laravel

Tabel berikut ada dari migration bawaan Laravel, tetapi biasanya tidak dimasukkan ke ERD domain utama:

- `password_reset_tokens`
- `sessions`
- `cache`
- `cache_locks`
- `jobs`
- `job_batches`
- `failed_jobs`
