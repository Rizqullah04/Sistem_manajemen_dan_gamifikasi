<?php

namespace Tests\Feature;

use App\Models\Ormawa;
use App\Models\Period;
use App\Models\User;
use App\Models\UserOrmawaMembership;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class OrmawaOfficerAppointmentTest extends TestCase
{
    use RefreshDatabase;

    public function test_himpunan_account_can_appoint_its_active_citizen_with_position_and_period(): void
    {
        [$himpunan, , $account, $citizen] = $this->organizationData();
        $period = $this->activePeriod();
        Sanctum::actingAs($account);

        $this->postJson("/api/ormawa/members/{$citizen->id_user}/appointment", [
            'position' => 'sekretaris',
            'division' => 'Kominfo',
        ])
            ->assertOk()
            ->assertJsonPath('data.organization_membership.position', 'sekretaris')
            ->assertJsonPath('data.organization_membership.division', 'Kominfo')
            ->assertJsonPath('data.organization_membership.id_period', $period->id_period);

        $this->assertDatabaseHas('user_ormawa_memberships', [
            'id_user' => $citizen->id_user,
            'id_ormawa' => $himpunan->id_ormawa,
            'id_period' => $period->id_period,
            'position' => 'sekretaris',
            'status' => 'aktif',
        ]);
    }

    public function test_himpunan_cannot_appoint_student_from_another_study_program(): void
    {
        [, $otherHimpunan, $account] = $this->organizationData();
        $outsider = User::factory()->create([
            'id_ormawa' => $otherHimpunan->id_ormawa,
            'status_akun' => 'aktif',
        ]);
        $this->activePeriod();
        Sanctum::actingAs($account);

        $this->postJson("/api/ormawa/members/{$outsider->id_user}/appointment", [
            'position' => 'anggota_pengurus',
        ])->assertForbidden();
    }

    public function test_student_cannot_hold_active_structural_positions_in_two_organizations(): void
    {
        [$himpunan, $otherHimpunan, $account, $citizen] = $this->organizationData();
        $period = $this->activePeriod();
        UserOrmawaMembership::create([
            'id_user' => $citizen->id_user,
            'id_ormawa' => $otherHimpunan->id_ormawa,
            'id_period' => $period->id_period,
            'position' => 'bendahara',
            'status' => 'aktif',
        ]);
        Sanctum::actingAs($account);

        $this->postJson("/api/ormawa/members/{$citizen->id_user}/appointment", [
            'position' => 'ketua',
        ])
            ->assertUnprocessable()
            ->assertJsonFragment([
                'message' => "Mahasiswa masih menjabat sebagai pengurus {$otherHimpunan->nama_ormawa} pada periode yang sama.",
            ]);

        $this->assertDatabaseMissing('user_ormawa_memberships', [
            'id_user' => $citizen->id_user,
            'id_ormawa' => $himpunan->id_ormawa,
            'id_period' => $period->id_period,
        ]);
    }

    public function test_dpm_admin_can_appoint_an_active_student_to_dpm(): void
    {
        [$himpunan, , , $student] = $this->organizationData();
        $dpm = Ormawa::create([
            'nama_ormawa' => 'DPM Fakultas Teknik',
            'eligible_for_award' => false,
        ]);
        $admin = User::factory()->create([
            'role' => 'admin',
            'id_ormawa' => $dpm->id_ormawa,
            'status_akun' => 'aktif',
        ]);
        $period = $this->activePeriod();
        Sanctum::actingAs($admin);

        $this->postJson('/api/dpm/members', [
            'id_user' => $student->id_user,
            'position' => 'wakil_ketua',
        ])
            ->assertOk()
            ->assertJsonPath('data.dpm_membership.position', 'wakil_ketua');

        $this->assertDatabaseHas('user_ormawa_memberships', [
            'id_user' => $student->id_user,
            'id_ormawa' => $dpm->id_ormawa,
            'id_period' => $period->id_period,
            'position' => 'wakil_ketua',
            'status' => 'aktif',
        ]);

        $this->assertSame($himpunan->id_ormawa, $student->fresh()->id_ormawa);
    }

    /**
     * @return array{Ormawa, Ormawa, User, User}
     */
    private function organizationData(): array
    {
        $himpunan = Ormawa::create([
            'nama_ormawa' => 'HMJTI - Himpunan Mahasiswa Teknik Informatika',
        ]);
        $otherHimpunan = Ormawa::create([
            'nama_ormawa' => 'HMTM - Himpunan Mahasiswa Teknik Mesin',
        ]);
        $account = User::factory()->create([
            'role' => 'ormawa',
            'id_ormawa' => $himpunan->id_ormawa,
            'status_akun' => 'aktif',
        ]);
        $citizen = User::factory()->create([
            'role' => 'anggota',
            'id_ormawa' => $himpunan->id_ormawa,
            'status_akun' => 'aktif',
        ]);

        return [$himpunan, $otherHimpunan, $account, $citizen];
    }

    private function activePeriod(): Period
    {
        return Period::create([
            'year' => 2026,
            'name' => 'Periode 2026',
            'starts_on' => '2026-01-01',
            'ends_on' => '2026-12-31',
            'status' => 'active',
        ]);
    }
}
