<?php

namespace Database\Seeders;

use App\Models\KategoriKegiatan;
use Illuminate\Database\Seeder;

class KategoriKegiatanSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $kategoris = [
            [
                'nama_kategori' => 'Akademik',
                'deskripsi' => 'Kegiatan seminar, workshop, lomba karya ilmiah, atau pelatihan akademik.',
                'poin_dasar' => 100,
            ],
            [
                'nama_kategori' => 'Pengabdian Masyarakat',
                'deskripsi' => 'Kegiatan sosial, bakti masyarakat, edukasi publik, atau pemberdayaan komunitas.',
                'poin_dasar' => 150,
            ],
            [
                'nama_kategori' => 'Minat dan Bakat',
                'deskripsi' => 'Kegiatan seni, olahraga, kreativitas, dan pengembangan talenta mahasiswa.',
                'poin_dasar' => 120,
            ],
            [
                'nama_kategori' => 'Organisasi dan Kepemimpinan',
                'deskripsi' => 'Kegiatan kaderisasi, rapat kerja, pelatihan kepemimpinan, dan tata kelola ormawa.',
                'poin_dasar' => 90,
            ],
            [
                'nama_kategori' => 'Prestasi',
                'deskripsi' => 'Keikutsertaan atau capaian ormawa pada kompetisi tingkat kampus, regional, nasional, atau internasional.',
                'poin_dasar' => 200,
            ],
        ];

        foreach ($kategoris as $kategori) {
            KategoriKegiatan::updateOrCreate(
                ['nama_kategori' => $kategori['nama_kategori']],
                $kategori
            );
        }
    }
}
