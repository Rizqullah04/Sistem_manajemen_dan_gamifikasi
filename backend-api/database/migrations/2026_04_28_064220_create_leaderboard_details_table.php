<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('leaderboard_details', function (Blueprint $table) {
            $table->id('id_detail');
            $table->foreignId('id_leaderboard')->constrained('leaderboards', 'id_leaderboard')->cascadeOnDelete();
            $table->foreignId('id_user')->nullable()->constrained('users', 'id_user')->cascadeOnDelete();
            $table->foreignId('id_ormawa')->nullable()->constrained('ormawas', 'id_ormawa')->cascadeOnDelete();
            $table->unsignedInteger('poin')->default(0);
            $table->timestamps();
        });

        if (DB::getDriverName() !== 'sqlite') {
            DB::statement(
                'ALTER TABLE leaderboard_details ADD CONSTRAINT leaderboard_details_target_check '.
                'CHECK ((id_user IS NOT NULL AND id_ormawa IS NULL) OR (id_user IS NULL AND id_ormawa IS NOT NULL))'
            );
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('leaderboard_details');
    }
};
