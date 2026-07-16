<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('dislike_kegiatans', function (Blueprint $table) {
            $table->id('id_dislike');
            $table->foreignId('id_kegiatan')->constrained('kegiatans', 'id_kegiatan')->cascadeOnDelete();
            $table->foreignId('id_user')->constrained('users', 'id_user')->cascadeOnDelete();
            $table->text('alasan');
            $table->text('solusi');
            $table->timestamps();

            $table->unique(['id_kegiatan', 'id_user']);
            $table->index(['id_kegiatan', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('dislike_kegiatans');
    }
};
