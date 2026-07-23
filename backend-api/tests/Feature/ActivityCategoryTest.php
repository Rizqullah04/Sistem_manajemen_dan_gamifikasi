<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ActivityCategoryTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_create_category_without_configuring_points(): void
    {
        Sanctum::actingAs(User::factory()->create([
            'role' => 'admin',
            'status_akun' => 'aktif',
        ]));

        $this->postJson('/api/kategori-kegiatans', [
            'nama_kategori' => 'Seminar',
        ])
            ->assertCreated()
            ->assertJsonPath('data.nama_kategori', 'Seminar')
            ->assertJsonPath('data.poin_dasar', 0);

        $this->assertDatabaseHas('kategori_kegiatans', [
            'nama_kategori' => 'Seminar',
            'poin_dasar' => 0,
        ]);
    }
}
