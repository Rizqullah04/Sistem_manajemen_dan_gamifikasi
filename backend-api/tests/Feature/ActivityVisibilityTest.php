<?php

namespace Tests\Feature;

use App\Models\Kegiatan;
use App\Models\Ormawa;
use App\Models\PoinLog;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ActivityVisibilityTest extends TestCase
{
    use RefreshDatabase;

    public function test_member_only_sees_approved_activities_from_all_organizations(): void
    {
        [$firstOrmawa, $secondOrmawa] = $this->organizations();
        $this->activity($firstOrmawa, 'Kegiatan Valid Pertama', Kegiatan::STATUS_VALID);
        $this->activity($firstOrmawa, 'Draft Rahasia Pertama', Kegiatan::STATUS_PENDING);
        $this->activity($secondOrmawa, 'Kegiatan Valid Kedua', Kegiatan::STATUS_VALID);
        $this->activity($secondOrmawa, 'Kegiatan Ditolak Kedua', Kegiatan::STATUS_DITOLAK);

        Sanctum::actingAs(User::factory()->create([
            'role' => 'anggota',
            'status_akun' => 'aktif',
        ]));

        $response = $this->getJson('/api/kegiatans')->assertOk();

        $response
            ->assertJsonFragment(['nama_kegiatan' => 'Kegiatan Valid Pertama'])
            ->assertJsonFragment(['nama_kegiatan' => 'Kegiatan Valid Kedua'])
            ->assertJsonMissing(['nama_kegiatan' => 'Draft Rahasia Pertama'])
            ->assertJsonMissing(['nama_kegiatan' => 'Kegiatan Ditolak Kedua']);
    }

    public function test_organization_sees_all_own_activities_and_approved_external_activities(): void
    {
        [$firstOrmawa, $secondOrmawa] = $this->organizations();
        $externalValid = $this->activity(
            $firstOrmawa,
            'Kegiatan Valid Organisasi Lain',
            Kegiatan::STATUS_VALID
        );
        $externalPending = $this->activity(
            $firstOrmawa,
            'Draft Organisasi Lain',
            Kegiatan::STATUS_PENDING
        );
        $this->activity($secondOrmawa, 'Draft Milik Sendiri', Kegiatan::STATUS_PENDING);
        $this->activity($secondOrmawa, 'Kegiatan Milik Sendiri', Kegiatan::STATUS_VALID);

        Sanctum::actingAs(User::factory()->create([
            'role' => 'ormawa',
            'id_ormawa' => $secondOrmawa->id_ormawa,
            'status_akun' => 'aktif',
        ]));

        $response = $this->getJson('/api/kegiatans')->assertOk();

        $response
            ->assertJsonFragment(['nama_kegiatan' => 'Kegiatan Valid Organisasi Lain'])
            ->assertJsonFragment(['nama_kegiatan' => 'Draft Milik Sendiri'])
            ->assertJsonFragment(['nama_kegiatan' => 'Kegiatan Milik Sendiri'])
            ->assertJsonMissing(['nama_kegiatan' => 'Draft Organisasi Lain']);

        $this->getJson("/api/kegiatans/{$externalValid->id_kegiatan}")
            ->assertOk();
        $this->getJson("/api/kegiatans/{$externalPending->id_kegiatan}")
            ->assertForbidden();
    }

    public function test_pending_activity_rejects_member_interactions(): void
    {
        [$ormawa] = $this->organizations();
        $activity = $this->activity(
            $ormawa,
            'Kegiatan Menunggu Verifikasi',
            Kegiatan::STATUS_PENDING
        );
        Sanctum::actingAs(User::factory()->create([
            'role' => 'anggota',
            'status_akun' => 'aktif',
        ]));

        $this->postJson('/api/like-kegiatans', [
            'id_kegiatan' => $activity->id_kegiatan,
        ])->assertUnprocessable();

        $this->postJson('/api/dislike-kegiatans', [
            'id_kegiatan' => $activity->id_kegiatan,
            'alasan' => 'Informasi kegiatan masih belum cukup jelas.',
            'solusi' => 'Lengkapi informasi setelah kegiatan disetujui.',
        ])->assertUnprocessable();

        $this->postJson('/api/diskusis', [
            'id_kegiatan' => $activity->id_kegiatan,
            'komentar' => 'Komentar belum boleh dikirim.',
        ])->assertUnprocessable();
    }

    public function test_dpm_admin_can_publish_activity_without_organization_points(): void
    {
        $admin = User::factory()->create([
            'role' => 'admin',
            'id_ormawa' => null,
            'status_akun' => 'aktif',
        ]);
        Sanctum::actingAs($admin);

        $response = $this->postJson('/api/kegiatans', [
            'nama_kegiatan' => 'Sidang Terbuka DPM',
            'deskripsi' => 'Kegiatan transparansi dan aspirasi mahasiswa.',
            'tanggal' => now()->addWeek()->toDateString(),
            'poin_kegiatan' => 100,
        ])->assertCreated();

        $activityId = $response->json('data.id_kegiatan');
        $dpm = Ormawa::where('nama_ormawa', 'DPM Fakultas Teknik')->firstOrFail();

        $this->assertDatabaseHas('kegiatans', [
            'id_kegiatan' => $activityId,
            'id_ormawa' => $dpm->id_ormawa,
            'status' => Kegiatan::STATUS_VALID,
            'poin_kegiatan' => 0,
        ]);
        $this->assertSame(0, PoinLog::query()
            ->where('referensi_tipe', 'kegiatan')
            ->where('referensi_id', $activityId)
            ->count());

        $this->patchJson("/api/kegiatans/{$activityId}/verifikasi", [
            'status' => Kegiatan::STATUS_VALID,
        ])->assertUnprocessable();
    }

    public function test_dpm_activity_remains_published_after_admin_edits_it(): void
    {
        $dpm = Ormawa::create(['nama_ormawa' => 'DPM Fakultas Teknik']);
        $activity = $this->activity(
            $dpm,
            'Agenda DPM',
            Kegiatan::STATUS_VALID
        );
        Sanctum::actingAs(User::factory()->create([
            'role' => 'admin',
            'id_ormawa' => $dpm->id_ormawa,
            'status_akun' => 'aktif',
        ]));

        $this->putJson("/api/kegiatans/{$activity->id_kegiatan}", [
            'nama_kegiatan' => 'Agenda DPM Diperbarui',
            'deskripsi' => 'Deskripsi agenda yang telah diperbarui.',
            'tanggal' => now()->addWeeks(2)->toDateString(),
            'poin_kegiatan' => 50,
        ])->assertOk();

        $this->assertDatabaseHas('kegiatans', [
            'id_kegiatan' => $activity->id_kegiatan,
            'nama_kegiatan' => 'Agenda DPM Diperbarui',
            'status' => Kegiatan::STATUS_VALID,
            'poin_kegiatan' => 0,
        ]);
    }

    public function test_activity_owner_can_upload_a_documentation_photo(): void
    {
        Storage::fake('public');
        $ormawa = Ormawa::create(['nama_ormawa' => 'Himpunan Dokumentasi']);
        $activity = $this->activity($ormawa, 'Kegiatan Dokumentasi', Kegiatan::STATUS_VALID);
        Sanctum::actingAs(User::factory()->create([
            'role' => 'ormawa',
            'id_ormawa' => $ormawa->id_ormawa,
            'status_akun' => 'aktif',
        ]));

        $response = $this->postJson('/api/dokumentasi-kegiatans', [
            'id_kegiatan' => $activity->id_kegiatan,
            'caption' => 'Foto kegiatan',
            'file' => UploadedFile::fake()->create(
                'kegiatan.jpg',
                100,
                'image/jpeg'
            ),
        ])->assertCreated();

        $fileUrl = $response->json('data.file_url');
        $this->assertStringContainsString('/storage/activity-documentation/', $fileUrl);
        $this->assertDatabaseHas('dokumentasi_kegiatans', [
            'id_kegiatan' => $activity->id_kegiatan,
            'caption' => 'Foto kegiatan',
            'file_url' => $fileUrl,
        ]);
    }

    /**
     * @return array{Ormawa, Ormawa}
     */
    private function organizations(): array
    {
        return [
            Ormawa::create(['nama_ormawa' => 'Himpunan Pertama']),
            Ormawa::create(['nama_ormawa' => 'Himpunan Kedua']),
        ];
    }

    private function activity(
        Ormawa $ormawa,
        string $name,
        string $status
    ): Kegiatan {
        return Kegiatan::create([
            'id_ormawa' => $ormawa->id_ormawa,
            'nama_kegiatan' => $name,
            'deskripsi' => "Deskripsi $name",
            'tanggal' => now()->addWeek()->toDateString(),
            'status' => $status,
        ]);
    }
}
