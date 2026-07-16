<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::dropIfExists('admin_profiles');
    }

    public function down(): void
    {
        Schema::create('admin_profiles', function (Blueprint $table) {
            $table->id('id_admin_profile');
            $table->foreignId('id_user')->constrained('users', 'id_user')->cascadeOnDelete();
            $table->enum('tipe_admin', ['DPM', 'staff_dosen']);
            $table->string('nip_nidn')->nullable();
            $table->string('jabatan')->nullable();
            $table->string('unit_kerja')->nullable();
            $table->timestamps();

            $table->unique('id_user');
        });
    }
};
