<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (! Schema::hasColumn('users', 'status_akun')) {
                $table->enum('status_akun', ['aktif', 'nonaktif'])->default('aktif')->after('role');
            }
        });

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

        Schema::create('dokumentasi_kegiatans', function (Blueprint $table) {
            $table->id('id_dokumentasi');
            $table->foreignId('id_kegiatan')->constrained('kegiatans', 'id_kegiatan')->cascadeOnDelete();
            $table->foreignId('id_ormawa')->constrained('ormawas', 'id_ormawa')->cascadeOnDelete();
            $table->text('caption')->nullable();
            $table->string('file_url');
            $table->dateTime('tanggal_upload');
            $table->timestamps();
        });

        Schema::table('verifikasis', function (Blueprint $table) {
            if (! Schema::hasColumn('verifikasis', 'tanggal_verifikasi')) {
                $table->dateTime('tanggal_verifikasi')->nullable()->after('status');
            }
        });

        Schema::table('votings', function (Blueprint $table) {
            if (! Schema::hasColumn('votings', 'id_ormawa')) {
                $table->foreignId('id_ormawa')->nullable()->after('id_kegiatan')->constrained('ormawas', 'id_ormawa')->nullOnDelete();
            }

            if (! Schema::hasColumn('votings', 'judul_voting')) {
                $table->string('judul_voting')->nullable()->after('id_ormawa');
            }

            if (! Schema::hasColumn('votings', 'status')) {
                $table->enum('status', ['aktif', 'selesai'])->default('aktif')->after('jenis_voting');
            }
        });

        Schema::table('vote_details', function (Blueprint $table) {
            if (! Schema::hasColumn('vote_details', 'tanggal_vote')) {
                $table->dateTime('tanggal_vote')->nullable()->after('pilihan');
            }
        });

        Schema::table('diskusis', function (Blueprint $table) {
            if (! Schema::hasColumn('diskusis', 'parent_id')) {
                $table->foreignId('parent_id')->nullable()->after('id_user')->constrained('diskusis', 'id_diskusi')->nullOnDelete();
            }
        });

        Schema::create('like_kegiatans', function (Blueprint $table) {
            $table->id('id_like');
            $table->foreignId('id_kegiatan')->constrained('kegiatans', 'id_kegiatan')->cascadeOnDelete();
            $table->foreignId('id_user')->constrained('users', 'id_user')->cascadeOnDelete();
            $table->dateTime('tanggal');
            $table->timestamps();

            $table->unique(['id_kegiatan', 'id_user']);
        });

        Schema::create('chats', function (Blueprint $table) {
            $table->id('id_chat');
            $table->foreignId('id_pengirim')->constrained('users', 'id_user')->cascadeOnDelete();
            $table->foreignId('id_penerima')->constrained('users', 'id_user')->cascadeOnDelete();
            $table->text('pesan');
            $table->enum('status_baca', ['terkirim', 'dibaca'])->default('terkirim');
            $table->dateTime('tanggal');
            $table->timestamps();
        });

        Schema::create('poin_logs', function (Blueprint $table) {
            $table->id('id_poin_log');
            $table->foreignId('id_user')->nullable()->constrained('users', 'id_user')->cascadeOnDelete();
            $table->foreignId('id_ormawa')->nullable()->constrained('ormawas', 'id_ormawa')->cascadeOnDelete();
            $table->enum('sumber', ['kegiatan', 'komentar', 'balasan', 'voting', 'like']);
            $table->unsignedBigInteger('referensi_id');
            $table->integer('poin');
            $table->text('keterangan')->nullable();
            $table->dateTime('tanggal');
            $table->timestamps();
        });

        Schema::table('leaderboards', function (Blueprint $table) {
            if (! Schema::hasColumn('leaderboards', 'periode')) {
                $table->string('periode')->default('all_time')->after('tipe');
            }

            if (! Schema::hasColumn('leaderboards', 'tanggal_generate')) {
                $table->dateTime('tanggal_generate')->nullable()->after('periode');
            }
        });

        Schema::table('leaderboard_details', function (Blueprint $table) {
            if (! Schema::hasColumn('leaderboard_details', 'ranking')) {
                $table->unsignedInteger('ranking')->default(0)->after('poin');
            }
        });
    }

    public function down(): void
    {
        Schema::table('leaderboard_details', function (Blueprint $table) {
            if (Schema::hasColumn('leaderboard_details', 'ranking')) {
                $table->dropColumn('ranking');
            }
        });

        Schema::table('leaderboards', function (Blueprint $table) {
            if (Schema::hasColumn('leaderboards', 'tanggal_generate')) {
                $table->dropColumn('tanggal_generate');
            }

            if (Schema::hasColumn('leaderboards', 'periode')) {
                $table->dropColumn('periode');
            }
        });

        Schema::dropIfExists('poin_logs');
        Schema::dropIfExists('chats');
        Schema::dropIfExists('like_kegiatans');

        Schema::table('diskusis', function (Blueprint $table) {
            if (Schema::hasColumn('diskusis', 'parent_id')) {
                $table->dropConstrainedForeignId('parent_id');
            }
        });

        Schema::table('vote_details', function (Blueprint $table) {
            if (Schema::hasColumn('vote_details', 'tanggal_vote')) {
                $table->dropColumn('tanggal_vote');
            }
        });

        Schema::table('votings', function (Blueprint $table) {
            if (Schema::hasColumn('votings', 'status')) {
                $table->dropColumn('status');
            }

            if (Schema::hasColumn('votings', 'judul_voting')) {
                $table->dropColumn('judul_voting');
            }

            if (Schema::hasColumn('votings', 'id_ormawa')) {
                $table->dropConstrainedForeignId('id_ormawa');
            }
        });

        Schema::table('verifikasis', function (Blueprint $table) {
            if (Schema::hasColumn('verifikasis', 'tanggal_verifikasi')) {
                $table->dropColumn('tanggal_verifikasi');
            }
        });

        Schema::dropIfExists('dokumentasi_kegiatans');
        Schema::dropIfExists('admin_profiles');

        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'status_akun')) {
                $table->dropColumn('status_akun');
            }
        });
    }
};
