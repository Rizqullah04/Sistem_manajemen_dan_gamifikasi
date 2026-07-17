<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::table('activity_types')->updateOrInsert(
            ['code' => 'VERIFIED_ACTIVITY'],
            [
                'name' => 'Kegiatan Terverifikasi',
                'frequency_level' => 'medium',
                'difficulty_level' => 'medium',
                'organizational_impact' => 'medium',
                'point_value' => 10,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        );
    }

    public function down(): void
    {
        DB::table('activity_types')->where('code', 'VERIFIED_ACTIVITY')->delete();
    }
};
