<?php

namespace Database\Seeders;

use App\Models\AdminProfile;
use App\Models\Leaderboard;
use App\Models\Period;
use App\Models\Ormawa;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call([
            PeriodSeeder::class,
            ActivityTypeSeeder::class,
            KategoriKegiatanSeeder::class,
            BadgeSeeder::class,
        ]);

        User::whereIn('email', [
            'admin@ormawa-app.test',
            'ormawa@ormawa-app.test',
        ])->delete();

        $admin = User::updateOrCreate([
            'email' => 'dpm.ft@ormawa-app.test',
        ], [
            'nama' => 'DPM Fakultas Teknik',
            'password' => 'password',
            'role' => 'admin',
            'status_akun' => 'aktif',
            'id_ormawa' => null,
        ]);

        AdminProfile::updateOrCreate([
            'id_user' => $admin->id_user,
        ], [
            'tipe_admin' => 'DPM',
            'jabatan' => 'Admin Fakultas Teknik',
            'unit_kerja' => 'Fakultas Teknik',
        ]);

        $ormawaSeeds = [
            'BEM Fakultas Teknik' => 'Badan Eksekutif Mahasiswa Fakultas Teknik',
            'HMJTI - Himpunan Mahasiswa Jurusan Teknik Informatika' => 'Organisasi mahasiswa Jurusan Teknik Informatika',
            'HMTM - Himpunan Mahasiswa Teknik Mesin' => 'Organisasi mahasiswa Teknik Mesin',
            'HMJTK - Himpunan Mahasiswa Jurusan Teknik Kimia' => 'Organisasi mahasiswa Jurusan Teknik Kimia',
        ];

        $ormawaEmails = [
            'BEM Fakultas Teknik' => 'bem.fakultas.teknik@ormawa-app.test',
            'HMJTI - Himpunan Mahasiswa Jurusan Teknik Informatika' => 'hmjti.himpunan.mahasiswa.jurusan.teknik.informatika@ormawa-app.test',
            'HMTM - Himpunan Mahasiswa Teknik Mesin' => 'hmtm.himpunan.mahasiswa.teknik.mesin@ormawa-app.test',
            'HMJTK - Himpunan Mahasiswa Jurusan Teknik Kimia' => 'hmjtk.himpunan.mahasiswa.jurusan.teknik.kimia@ormawa-app.test',
        ];

        Ormawa::whereNotIn('nama_ormawa', array_keys($ormawaSeeds))->delete();

        foreach ($ormawaSeeds as $namaOrmawa => $deskripsi) {
            $ormawa = Ormawa::updateOrCreate([
                'nama_ormawa' => $namaOrmawa,
            ], [
                'deskripsi' => $deskripsi,
                'total_poin' => 0,
            ]);

            User::updateOrCreate([
                'id_ormawa' => $ormawa->id_ormawa,
                'role' => 'ormawa',
            ], [
                'nama' => 'Akun '.$namaOrmawa,
                'email' => $ormawaEmails[$namaOrmawa],
                'password' => 'password',
                'status_akun' => 'aktif',
            ]);
        }

        $periods = Period::query()->orderBy('year')->get();

        foreach ($periods as $period) {
            Leaderboard::updateOrCreate(
                [
                    'id_period' => $period->id_period,
                    'tipe' => 'individu',
                ],
                [
                    'tanggal_generate' => now(),
                ]
            );

            Leaderboard::updateOrCreate(
                [
                    'id_period' => $period->id_period,
                    'tipe' => 'ormawa',
                ],
                [
                    'tanggal_generate' => now(),
                ]
            );
        }
    }
}
