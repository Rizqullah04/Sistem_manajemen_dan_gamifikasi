<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('votings', function (Blueprint $table) {
            if (! Schema::hasColumn('votings', 'poll_options')) {
                $table->json('poll_options')->nullable()->after('status');
            }
        });

        if (DB::getDriverName() === 'mysql') {
            DB::statement('ALTER TABLE votings MODIFY id_kegiatan BIGINT UNSIGNED NULL');
        }
    }

    public function down(): void
    {
        if (DB::getDriverName() === 'mysql') {
            DB::statement('ALTER TABLE votings MODIFY id_kegiatan BIGINT UNSIGNED NOT NULL');
        }

        Schema::table('votings', function (Blueprint $table) {
            if (Schema::hasColumn('votings', 'poll_options')) {
                $table->dropColumn('poll_options');
            }
        });
    }
};