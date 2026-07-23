<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('user_ormawa_memberships', function (Blueprint $table) {
            $table->dropUnique(['id_user', 'id_ormawa']);
            $table->string('position', 40)->default('anggota_pengurus')->after('status');
            $table->string('division', 100)->nullable()->after('position');
            $table->foreignId('id_period')
                ->nullable()
                ->after('division')
                ->constrained('periods', 'id_period')
                ->nullOnDelete();
            $table->date('starts_at')->nullable()->after('id_period');
            $table->date('ends_at')->nullable()->after('starts_at');
            $table->unique(
                ['id_user', 'id_ormawa', 'id_period'],
                'membership_user_ormawa_period_unique'
            );
        });

        $activePeriod = DB::table('periods')
            ->where('status', 'active')
            ->orderByDesc('starts_on')
            ->first();

        if ($activePeriod !== null) {
            DB::table('user_ormawa_memberships')
                ->whereNull('id_period')
                ->update([
                    'id_period' => $activePeriod->id_period,
                    'starts_at' => $activePeriod->starts_on,
                    'ends_at' => $activePeriod->ends_on,
                ]);
        }
    }

    public function down(): void
    {
        Schema::table('user_ormawa_memberships', function (Blueprint $table) {
            $table->dropUnique('membership_user_ormawa_period_unique');
            $table->dropConstrainedForeignId('id_period');
            $table->dropColumn([
                'position',
                'division',
                'starts_at',
                'ends_at',
            ]);
            $table->unique(['id_user', 'id_ormawa']);
        });
    }
};
