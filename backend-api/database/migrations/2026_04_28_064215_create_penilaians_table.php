<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('verifikasis', function (Blueprint $table) {
            $table->id('id_verifikasi');
            $table->foreignId('id_kegiatan')->constrained('kegiatans', 'id_kegiatan')->cascadeOnDelete();
            $table->foreignId('id_admin')->constrained('users', 'id_user')->restrictOnDelete();
            $table->text('catatan')->nullable();
            $table->enum('status', ['valid', 'ditolak']);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('verifikasis');
    }
};
