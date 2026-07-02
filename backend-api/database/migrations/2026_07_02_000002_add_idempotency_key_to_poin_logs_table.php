<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('poin_logs', function (Blueprint $table) {
            if (! Schema::hasColumn('poin_logs', 'idempotency_key')) {
                $table->string('idempotency_key')->nullable()->after('referensi_id')->unique();
            }
        });
    }

    public function down(): void
    {
        Schema::table('poin_logs', function (Blueprint $table) {
            if (Schema::hasColumn('poin_logs', 'idempotency_key')) {
                $table->dropUnique(['idempotency_key']);
                $table->dropColumn('idempotency_key');
            }
        });
    }
};
