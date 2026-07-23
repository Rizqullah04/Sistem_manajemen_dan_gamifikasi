<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('ormawas', function (Blueprint $table) {
            $table->boolean('eligible_for_award')
                ->default(true)
                ->after('total_poin');
        });

        DB::table('ormawas')
            ->where('nama_ormawa', 'like', 'DPM%')
            ->update(['eligible_for_award' => false]);
    }

    public function down(): void
    {
        Schema::table('ormawas', function (Blueprint $table) {
            $table->dropColumn('eligible_for_award');
        });
    }
};
