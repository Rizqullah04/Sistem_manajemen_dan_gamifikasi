<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('poin_logs', function (Blueprint $table) {
            if (! Schema::hasColumn('poin_logs', 'id_period')) {
                $table->foreignId('id_period')
                    ->nullable()
                    ->after('id_poin_log')
                    ->constrained('periods', 'id_period')
                    ->nullOnDelete();

                $table->index(['id_period', 'tanggal']);
            }
        });

        $activePeriodId = DB::table('periods')
            ->where('status', 'active')
            ->orderByDesc('starts_on')
            ->value('id_period');

        if ($activePeriodId !== null) {
            DB::table('poin_logs')
                ->whereNull('id_period')
                ->update(['id_period' => $activePeriodId]);
        }
    }

    public function down(): void
    {
        Schema::table('poin_logs', function (Blueprint $table) {
            if (Schema::hasColumn('poin_logs', 'id_period')) {
                $table->dropIndex(['id_period', 'tanggal']);
                $table->dropConstrainedForeignId('id_period');
            }
        });
    }
};
