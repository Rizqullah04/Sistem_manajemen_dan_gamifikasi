<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('nama', 100)->change();
            $table->char('nim', 11)->nullable()->change();
            $table->string('email', 100)->change();
        });

        Schema::table('ormawas', function (Blueprint $table) {
            $table->string('nama_ormawa', 150)->change();
        });

        Schema::table('kategori_kegiatans', function (Blueprint $table) {
            $table->string('nama_kategori', 100)->change();
        });

        Schema::table('kegiatans', function (Blueprint $table) {
            $table->string('nama_kegiatan', 150)->change();
        });

        Schema::table('dokumentasi_kegiatans', function (Blueprint $table) {
            // A URL may legitimately exceed the old VARCHAR(255) limit.
            $table->string('file_url', 2048)->change();
        });

        Schema::table('votings', function (Blueprint $table) {
            $table->string('judul_voting', 150)->nullable()->change();
        });

        Schema::table('vote_details', function (Blueprint $table) {
            $table->string('pilihan', 150)->change();
        });

        Schema::table('penilaians', function (Blueprint $table) {
            $table->unsignedTinyInteger('nilai_kreativitas')->default(0)->change();
            $table->unsignedTinyInteger('nilai_dampak')->default(0)->change();
            $table->unsignedTinyInteger('nilai_partisipasi')->default(0)->change();
            $table->unsignedTinyInteger('nilai_publikasi')->default(0)->change();
            $table->unsignedSmallInteger('total_nilai')->default(0)->change();
        });

        Schema::table('badges', function (Blueprint $table) {
            $table->string('nama_badge', 100)->change();
            $table->string('activity_type', 50)->change();
            $table->string('icon', 255)->nullable()->change();
        });

        Schema::table('periods', function (Blueprint $table) {
            $table->string('name', 100)->change();
        });

        Schema::table('activity_types', function (Blueprint $table) {
            $table->string('code', 50)->change();
            $table->string('name', 100)->change();
        });

        Schema::table('point_histories', function (Blueprint $table) {
            $table->string('source_model', 150)->nullable()->change();
        });

        Schema::table('poin_logs', function (Blueprint $table) {
            $table->string('idempotency_key', 191)->nullable()->change();
        });

        Schema::table('leaderboards', function (Blueprint $table) {
            $table->string('periode', 100)->default('all_time')->change();
        });

        Schema::table('ormawa_award_results', function (Blueprint $table) {
            $table->string('periode', 100)->change();
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('nama')->change();
            $table->string('nim', 11)->nullable()->change();
            $table->string('email')->change();
        });

        Schema::table('ormawas', fn (Blueprint $table) => $table->string('nama_ormawa')->change());
        Schema::table('kategori_kegiatans', fn (Blueprint $table) => $table->string('nama_kategori')->change());
        Schema::table('kegiatans', fn (Blueprint $table) => $table->string('nama_kegiatan')->change());
        Schema::table('dokumentasi_kegiatans', fn (Blueprint $table) => $table->string('file_url')->change());
        Schema::table('votings', fn (Blueprint $table) => $table->string('judul_voting')->nullable()->change());
        Schema::table('vote_details', fn (Blueprint $table) => $table->string('pilihan')->change());

        Schema::table('penilaians', function (Blueprint $table) {
            $table->unsignedInteger('nilai_kreativitas')->default(0)->change();
            $table->unsignedInteger('nilai_dampak')->default(0)->change();
            $table->unsignedInteger('nilai_partisipasi')->default(0)->change();
            $table->unsignedInteger('nilai_publikasi')->default(0)->change();
            $table->unsignedInteger('total_nilai')->default(0)->change();
        });

        Schema::table('badges', function (Blueprint $table) {
            $table->string('nama_badge')->change();
            $table->string('activity_type')->change();
            $table->string('icon')->nullable()->change();
        });

        Schema::table('periods', fn (Blueprint $table) => $table->string('name')->change());
        Schema::table('activity_types', function (Blueprint $table) {
            $table->string('code')->change();
            $table->string('name')->change();
        });
        Schema::table('point_histories', fn (Blueprint $table) => $table->string('source_model')->nullable()->change());
        Schema::table('poin_logs', fn (Blueprint $table) => $table->string('idempotency_key')->nullable()->change());
        Schema::table('leaderboards', fn (Blueprint $table) => $table->string('periode')->default('all_time')->change());
        Schema::table('ormawa_award_results', fn (Blueprint $table) => $table->string('periode')->change());
    }
};
