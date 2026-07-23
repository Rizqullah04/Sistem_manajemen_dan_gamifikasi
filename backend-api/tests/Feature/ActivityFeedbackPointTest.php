<?php

namespace Tests\Feature;

use App\Models\Kegiatan;
use App\Models\Ormawa;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ActivityFeedbackPointTest extends TestCase
{
    use RefreshDatabase;

    public function test_constructive_dislike_awards_only_one_point(): void
    {
        [$user, $activity] = $this->memberAndActivity();
        Sanctum::actingAs($user);

        $payload = [
            'id_kegiatan' => $activity->id_kegiatan,
            'alasan' => 'Pelaksanaan kegiatan kurang tepat waktu.',
            'solusi' => 'Panitia sebaiknya membuat susunan waktu yang lebih rinci.',
        ];

        $this->postJson('/api/dislike-kegiatans', $payload)->assertCreated();
        $this->postJson('/api/dislike-kegiatans', $payload)->assertCreated();

        $this->assertSame(1, $user->fresh()->poin);
        $this->assertDatabaseCount('dislike_kegiatans', 1);
        $this->assertDatabaseHas('poin_logs', [
            'id_user' => $user->id_user,
            'sumber' => 'dislike',
            'poin' => 1,
        ]);
        $this->assertDatabaseCount('poin_logs', 1);
    }

    public function test_switching_back_and_forth_keeps_one_interaction_point(): void
    {
        [$user, $activity] = $this->memberAndActivity();
        Sanctum::actingAs($user);

        $this->postJson('/api/dislike-kegiatans', [
            'id_kegiatan' => $activity->id_kegiatan,
            'alasan' => 'Informasi kegiatan diberikan terlalu mendadak.',
            'solusi' => 'Informasi sebaiknya diumumkan minimal satu minggu sebelumnya.',
        ])->assertCreated();

        $this->postJson('/api/like-kegiatans', [
            'id_kegiatan' => $activity->id_kegiatan,
        ])->assertCreated();

        $this->assertSame(1, $user->fresh()->poin);
        $this->assertDatabaseMissing('dislike_kegiatans', [
            'id_kegiatan' => $activity->id_kegiatan,
            'id_user' => $user->id_user,
        ]);
        $this->assertDatabaseMissing('poin_logs', [
            'id_user' => $user->id_user,
            'sumber' => 'dislike',
        ]);
        $this->assertDatabaseHas('poin_logs', [
            'id_user' => $user->id_user,
            'sumber' => 'like',
            'poin' => 1,
        ]);
        $this->assertDatabaseCount('poin_logs', 1);

        $this->postJson('/api/dislike-kegiatans', [
            'id_kegiatan' => $activity->id_kegiatan,
            'alasan' => 'Informasi kegiatan masih diberikan terlalu mendadak.',
            'solusi' => 'Jadwal publikasi perlu ditetapkan sejak awal periode.',
        ])->assertCreated();

        $this->assertSame(1, $user->fresh()->poin);
        $this->assertDatabaseMissing('like_kegiatans', [
            'id_kegiatan' => $activity->id_kegiatan,
            'id_user' => $user->id_user,
        ]);
        $this->assertDatabaseMissing('poin_logs', [
            'id_user' => $user->id_user,
            'sumber' => 'like',
        ]);
        $this->assertDatabaseHas('poin_logs', [
            'id_user' => $user->id_user,
            'sumber' => 'dislike',
            'poin' => 1,
        ]);
        $this->assertDatabaseCount('poin_logs', 1);
    }

    public function test_cancelling_dislike_revokes_its_point(): void
    {
        [$user, $activity] = $this->memberAndActivity();
        Sanctum::actingAs($user);

        $this->postJson('/api/dislike-kegiatans', [
            'id_kegiatan' => $activity->id_kegiatan,
            'alasan' => 'Lokasi kegiatan sulit dijangkau oleh peserta.',
            'solusi' => 'Pilih lokasi yang dekat dengan transportasi umum.',
        ])->assertCreated();

        $this->deleteJson(
            "/api/kegiatans/{$activity->id_kegiatan}/dislike"
        )->assertOk();

        $this->assertSame(0, $user->fresh()->poin);
        $this->assertDatabaseMissing('dislike_kegiatans', [
            'id_kegiatan' => $activity->id_kegiatan,
            'id_user' => $user->id_user,
        ]);
        $this->assertDatabaseMissing('poin_logs', [
            'id_user' => $user->id_user,
            'sumber' => 'dislike',
        ]);
    }

    /**
     * @return array{User, Kegiatan}
     */
    private function memberAndActivity(): array
    {
        $ormawa = Ormawa::create([
            'nama_ormawa' => 'BEM Fakultas Teknik',
            'deskripsi' => 'Organisasi mahasiswa',
        ]);
        $user = User::factory()->create([
            'role' => 'anggota',
            'status_akun' => 'aktif',
        ]);
        $activity = Kegiatan::create([
            'id_ormawa' => $ormawa->id_ormawa,
            'nama_kegiatan' => 'Seminar Teknologi',
            'deskripsi' => 'Seminar untuk mahasiswa fakultas teknik.',
            'tanggal' => now()->addWeek()->toDateString(),
            'status' => Kegiatan::STATUS_VALID,
        ]);

        return [$user, $activity];
    }
}
