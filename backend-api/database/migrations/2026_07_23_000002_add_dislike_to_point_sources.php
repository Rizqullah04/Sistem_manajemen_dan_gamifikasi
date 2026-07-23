<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        if (DB::getDriverName() !== 'mysql') {
            return;
        }

        DB::statement(
            "ALTER TABLE poin_logs MODIFY sumber ENUM('kegiatan', 'komentar', 'balasan', 'voting', 'like', 'dislike') NOT NULL"
        );
    }

    public function down(): void
    {
        if (DB::getDriverName() !== 'mysql') {
            return;
        }

        DB::table('poin_logs')->where('sumber', 'dislike')->delete();
        DB::statement(
            "ALTER TABLE poin_logs MODIFY sumber ENUM('kegiatan', 'komentar', 'balasan', 'voting', 'like') NOT NULL"
        );
    }
};
