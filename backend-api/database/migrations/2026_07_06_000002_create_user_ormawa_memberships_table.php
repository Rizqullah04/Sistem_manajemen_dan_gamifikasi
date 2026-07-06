<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_ormawa_memberships', function (Blueprint $table) {
            $table->id();
            $table->foreignId('id_user')->constrained('users', 'id_user')->cascadeOnDelete();
            $table->foreignId('id_ormawa')->constrained('ormawas', 'id_ormawa')->cascadeOnDelete();
            $table->enum('status', ['aktif', 'nonaktif'])->default('aktif');
            $table->foreignId('appointed_by')->nullable()->constrained('users', 'id_user')->nullOnDelete();
            $table->timestamps();

            $table->unique(['id_user', 'id_ormawa']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_ormawa_memberships');
    }
};
