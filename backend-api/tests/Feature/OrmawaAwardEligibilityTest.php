<?php

namespace Tests\Feature;

use App\Models\Ormawa;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class OrmawaAwardEligibilityTest extends TestCase
{
    use RefreshDatabase;

    public function test_dpm_is_excluded_from_award_preview_and_organization_leaderboard(): void
    {
        Ormawa::create([
            'nama_ormawa' => 'DPM Fakultas Teknik',
            'eligible_for_award' => false,
        ]);
        Ormawa::create([
            'nama_ormawa' => 'BEM Fakultas Teknik',
            'eligible_for_award' => true,
        ]);
        Sanctum::actingAs(User::factory()->create([
            'role' => 'admin',
            'status_akun' => 'aktif',
        ]));

        $this->postJson('/api/ormawa-awards/preview')
            ->assertOk()
            ->assertJsonFragment(['name' => 'BEM Fakultas Teknik'])
            ->assertJsonMissing(['name' => 'DPM Fakultas Teknik']);

        $this->getJson('/api/leaderboard?tipe=ormawa')
            ->assertOk()
            ->assertJsonFragment(['nama' => 'BEM Fakultas Teknik'])
            ->assertJsonMissing(['nama' => 'DPM Fakultas Teknik']);
    }
}
