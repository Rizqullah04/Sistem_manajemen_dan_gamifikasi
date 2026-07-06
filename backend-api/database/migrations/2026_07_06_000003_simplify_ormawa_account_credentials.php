<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    private const ACCOUNTS = [
        'BEM Fakultas Teknik' => [
            'name' => 'BEM',
            'email' => 'bem@ormawa-app.test',
            'old_email' => 'bem.fakultas.teknik@ormawa-app.test',
        ],
        'HMJTI - Himpunan Mahasiswa Jurusan Teknik Informatika' => [
            'name' => 'HMJTI',
            'email' => 'hmjti@ormawa-app.test',
            'old_email' => 'hmjti.himpunan.mahasiswa.jurusan.teknik.informatika@ormawa-app.test',
        ],
        'HMTM - Himpunan Mahasiswa Teknik Mesin' => [
            'name' => 'HMTM',
            'email' => 'hmtm@ormawa-app.test',
            'old_email' => 'hmtm.himpunan.mahasiswa.teknik.mesin@ormawa-app.test',
        ],
        'HMJTK - Himpunan Mahasiswa Jurusan Teknik Kimia' => [
            'name' => 'HMJTK',
            'email' => 'hmjtk@ormawa-app.test',
            'old_email' => 'hmjtk.himpunan.mahasiswa.jurusan.teknik.kimia@ormawa-app.test',
        ],
    ];

    public function up(): void
    {
        foreach (self::ACCOUNTS as $ormawaName => $account) {
            $ormawaId = DB::table('ormawas')
                ->where('nama_ormawa', $ormawaName)
                ->value('id_ormawa');

            if ($ormawaId === null) {
                continue;
            }

            DB::table('users')
                ->where('role', 'ormawa')
                ->where('id_ormawa', $ormawaId)
                ->update([
                    'nama' => $account['name'],
                    'email' => $account['email'],
                    'updated_at' => now(),
                ]);
        }
    }

    public function down(): void
    {
        foreach (self::ACCOUNTS as $ormawaName => $account) {
            $ormawaId = DB::table('ormawas')
                ->where('nama_ormawa', $ormawaName)
                ->value('id_ormawa');

            if ($ormawaId === null) {
                continue;
            }

            DB::table('users')
                ->where('role', 'ormawa')
                ->where('id_ormawa', $ormawaId)
                ->update([
                    'nama' => 'Akun '.$ormawaName,
                    'email' => $account['old_email'],
                    'updated_at' => now(),
                ]);
        }
    }
};
