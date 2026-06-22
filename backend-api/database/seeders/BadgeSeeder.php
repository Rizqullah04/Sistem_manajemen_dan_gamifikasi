<?php

namespace Database\Seeders;

use App\Models\Badge;
use Illuminate\Database\Seeder;

class BadgeSeeder extends Seeder
{
    public function run(): void
    {
        $badges = [
            [
                'nama_badge' => 'First Vote',
                'deskripsi' => 'Diberikan kepada mahasiswa yang pertama kali berpartisipasi dalam voting.',
                'minimal_poin' => 2,
                'icon' => 'first-vote.png',
            ],
            [
                'nama_badge' => 'Active Participant',
                'deskripsi' => 'Diberikan kepada pengguna yang aktif berpartisipasi dalam kegiatan.',
                'minimal_poin' => 50,
                'icon' => 'active-participant.png',
            ],
            [
                'nama_badge' => 'Top Contributor',
                'deskripsi' => 'Diberikan kepada kontributor dengan akumulasi poin tinggi.',
                'minimal_poin' => 250,
                'icon' => 'top-contributor.png',
            ],
            [
                'nama_badge' => 'Event Leader',
                'deskripsi' => 'Diberikan kepada pengguna yang memimpin kegiatan atau event.',
                'minimal_poin' => 100,
                'icon' => 'event-leader.png',
            ],
        ];

        foreach ($badges as $badge) {
            Badge::updateOrCreate(
                ['nama_badge' => $badge['nama_badge']],
                $badge
            );
        }
    }
}
