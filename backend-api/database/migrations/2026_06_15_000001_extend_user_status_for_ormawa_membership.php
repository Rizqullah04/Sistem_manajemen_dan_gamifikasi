<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        if (DB::getDriverName() === 'sqlite') {
            return;
        }

        DB::statement("ALTER TABLE users MODIFY status_akun ENUM('pending', 'aktif', 'nonaktif', 'ditolak') DEFAULT 'pending'");
    }

    public function down(): void
    {
        if (DB::getDriverName() === 'sqlite') {
            return;
        }

        DB::statement("UPDATE users SET status_akun = 'nonaktif' WHERE status_akun IN ('pending', 'ditolak')");
        DB::statement("ALTER TABLE users MODIFY status_akun ENUM('aktif', 'nonaktif') DEFAULT 'aktif'");
    }
};
