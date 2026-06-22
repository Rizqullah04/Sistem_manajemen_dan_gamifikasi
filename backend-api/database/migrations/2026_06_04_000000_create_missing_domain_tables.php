<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('kategori_kegiatans')) {
            Schema::create('kategori_kegiatans', function (Blueprint $table) {
                $table->id();
                $table->string('nama_kategori')->unique();
                $table->text('deskripsi')->nullable();
                $table->unsignedInteger('poin_dasar')->default(0);
                $table->timestamps();
            });
        }

        Schema::table('kegiatans', function (Blueprint $table) {
            if (! Schema::hasColumn('kegiatans', 'kategori_id')) {
                $table->foreignId('kategori_id')
                    ->nullable()
                    ->after('id_ormawa')
                    ->constrained('kategori_kegiatans')
                    ->nullOnDelete();
            }
        });

        if (! Schema::hasTable('penilaians')) {
            Schema::create('penilaians', function (Blueprint $table) {
                $table->id();
                $table->foreignId('kegiatan_id')->constrained('kegiatans', 'id_kegiatan')->cascadeOnDelete();
                $table->foreignId('juri_id')->constrained('users', 'id_user')->restrictOnDelete();
                $table->unsignedInteger('nilai_kreativitas')->default(0);
                $table->unsignedInteger('nilai_dampak')->default(0);
                $table->unsignedInteger('nilai_partisipasi')->default(0);
                $table->unsignedInteger('nilai_publikasi')->default(0);
                $table->unsignedInteger('total_nilai')->default(0);
                $table->text('komentar')->nullable();
                $table->timestamps();

                $table->unique(['kegiatan_id', 'juri_id']);
            });
        }

        if (! Schema::hasTable('badges')) {
            Schema::create('badges', function (Blueprint $table) {
                $table->id();
                $table->string('nama_badge')->unique();
                $table->text('deskripsi')->nullable();
                $table->unsignedInteger('minimal_poin')->default(0);
                $table->string('icon')->nullable();
                $table->timestamps();
            });
        }

        if (! Schema::hasTable('ormawa_badges')) {
            Schema::create('ormawa_badges', function (Blueprint $table) {
                $table->id();
                $table->foreignId('ormawa_id')->constrained('ormawas', 'id_ormawa')->cascadeOnDelete();
                $table->foreignId('badge_id')->constrained('badges')->cascadeOnDelete();
                $table->date('tanggal_diperoleh')->nullable();
                $table->timestamps();

                $table->unique(['ormawa_id', 'badge_id']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('ormawa_badges');
        Schema::dropIfExists('badges');
        Schema::dropIfExists('penilaians');

        Schema::table('kegiatans', function (Blueprint $table) {
            if (Schema::hasColumn('kegiatans', 'kategori_id')) {
                $table->dropConstrainedForeignId('kategori_id');
            }
        });

        Schema::dropIfExists('kategori_kegiatans');
    }
};
