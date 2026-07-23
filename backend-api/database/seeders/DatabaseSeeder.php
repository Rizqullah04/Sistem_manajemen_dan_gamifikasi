<?php

namespace Database\Seeders;

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

        User::updateOrCreate([
            'email' => 'dpm.ft@ormawa-app.test',
        ], [
            'nama' => 'DPM Fakultas Teknik',
            'password' => 'password',
            'role' => 'admin',
            'status_akun' => 'aktif',
            'id_ormawa' => null,
        ]);

        $ormawaSeeds = [
            'DPM Fakultas Teknik' => 'Dewan Perwakilan Mahasiswa Fakultas Teknik',
            'BEM Fakultas Teknik' => 'Badan Eksekutif Mahasiswa Fakultas Teknik',
            'HMJTI - Himpunan Mahasiswa Jurusan Teknik Informatika' => 'Organisasi mahasiswa Jurusan Teknik Informatika',
            'HMTM - Himpunan Mahasiswa Teknik Mesin' => 'Organisasi mahasiswa Teknik Mesin',
            'HMJTK - Himpunan Mahasiswa Jurusan Teknik Kimia' => 'Organisasi mahasiswa Jurusan Teknik Kimia',
        ];

        $ormawaEmails = [
            'BEM Fakultas Teknik' => 'bem@ormawa-app.test',
            'HMJTI - Himpunan Mahasiswa Jurusan Teknik Informatika' => 'hmjti@ormawa-app.test',
            'HMTM - Himpunan Mahasiswa Teknik Mesin' => 'hmtm@ormawa-app.test',
            'HMJTK - Himpunan Mahasiswa Jurusan Teknik Kimia' => 'hmjtk@ormawa-app.test',
        ];

        $ormawaAccountNames = [
            'BEM Fakultas Teknik' => 'BEM',
            'HMJTI - Himpunan Mahasiswa Jurusan Teknik Informatika' => 'HMJTI',
            'HMTM - Himpunan Mahasiswa Teknik Mesin' => 'HMTM',
            'HMJTK - Himpunan Mahasiswa Jurusan Teknik Kimia' => 'HMJTK',
        ];

        Ormawa::whereNotIn('nama_ormawa', array_keys($ormawaSeeds))->delete();

        foreach ($ormawaSeeds as $namaOrmawa => $deskripsi) {
            $ormawa = Ormawa::updateOrCreate([
                'nama_ormawa' => $namaOrmawa,
            ], [
                'deskripsi' => $deskripsi,
                'total_poin' => 0,
            ]);

            if (isset($ormawaEmails[$namaOrmawa])) {
                User::updateOrCreate([
                    'id_ormawa' => $ormawa->id_ormawa,
                    'role' => 'ormawa',
                ], [
                    'nama' => $ormawaAccountNames[$namaOrmawa],
                    'email' => $ormawaEmails[$namaOrmawa],
                    'password' => 'password',
                    'status_akun' => 'aktif',
                ]);
            }
        }

        User::where('email', 'dpm.ft@ormawa-app.test')->update([
            'id_ormawa' => Ormawa::where('nama_ormawa', 'DPM Fakultas Teknik')
                ->value('id_ormawa'),
        ]);

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
