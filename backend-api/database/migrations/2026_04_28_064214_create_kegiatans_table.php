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
        Schema::create('kegiatans', function (Blueprint $table) {
            $table->id('id_kegiatan');
            $table->foreignId('id_ormawa')->constrained('ormawas', 'id_ormawa')->cascadeOnDelete();
            $table->string('nama_kegiatan');
            $table->text('deskripsi');
            $table->date('tanggal');
            $table->unsignedInteger('poin_kegiatan')->default(0);
            $table->enum('status', ['pending', 'valid', 'ditolak'])->default('pending');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('kegiatans');
    }
};
