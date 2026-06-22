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
        Schema::create('ormawas', function (Blueprint $table) {
            $table->id('id_ormawa');
            $table->string('nama_ormawa');
            $table->text('deskripsi')->nullable();
            $table->unsignedInteger('total_poin')->default(0);
            $table->timestamps();
        });

        Schema::table('users', function (Blueprint $table) {
            $table->foreignId('id_ormawa')
                ->nullable()
                ->after('role')
                ->constrained('ormawas', 'id_ormawa')
                ->nullOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropConstrainedForeignId('id_ormawa');
        });

        Schema::dropIfExists('ormawas');
    }
};
