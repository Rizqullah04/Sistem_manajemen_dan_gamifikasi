<?php

namespace App\Console\Commands;

use App\Models\Period;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Throwable;

class ResetGamification extends Command
{
    protected $signature = 'app:reset-gamification
        {--dry-run : Tampilkan data yang akan dihapus tanpa mengubah database}
        {--force : Lewati pertanyaan konfirmasi}';

    protected $description = 'Reset data transaksi gamifikasi tanpa menghapus akun, Ormawa, kegiatan, atau master data';

    /** @var list<string> */
    private const RESET_TABLES = [
        'leaderboard_details',
        'leaderboards',
        'ormawa_award_results',
        'user_points',
        'organization_points',
        'point_histories',
        'poin_logs',
        'user_badges',
        'ormawa_badges',
        'periods',
    ];

    public function handle(): int
    {
        if (app()->environment('production')) {
            $this->error('Command reset gamifikasi tidak boleh dijalankan pada environment production.');

            return self::FAILURE;
        }

        $counts = collect(self::RESET_TABLES)
            ->filter(fn (string $table): bool => Schema::hasTable($table))
            ->mapWithKeys(fn (string $table): array => [$table => DB::table($table)->count()]);

        $this->info('Ringkasan data gamifikasi:');
        $this->table(
            ['Tabel', 'Jumlah record'],
            $counts->map(fn (int $count, string $table): array => [$table, $count])->values()->all()
        );
        $this->line('Poin pada tabel users dan ormawas juga akan dikembalikan menjadi 0.');

        if ($this->option('dry-run')) {
            $this->comment('Dry run selesai. Tidak ada data yang diubah.');

            return self::SUCCESS;
        }

        if (! $this->option('force') && ! $this->confirm(
            'Hapus seluruh data gamifikasi di atas dan buat periode aktif baru?',
            false
        )) {
            $this->comment('Reset dibatalkan.');

            return self::SUCCESS;
        }

        try {
            DB::transaction(function (): void {
                foreach (self::RESET_TABLES as $table) {
                    if (Schema::hasTable($table)) {
                        DB::table($table)->delete();
                    }
                }

                DB::table('users')->update(['poin' => 0]);
                DB::table('ormawas')->update(['total_poin' => 0]);

                Period::create([
                    'year' => (int) now()->year,
                    'name' => 'Periode '.now()->year,
                    'starts_on' => now()->startOfYear()->toDateString(),
                    'ends_on' => now()->endOfYear()->toDateString(),
                    'status' => 'active',
                ]);
            });
        } catch (Throwable $exception) {
            $this->error('Reset gagal: '.$exception->getMessage());

            return self::FAILURE;
        }

        $this->newLine();
        $this->info('Data gamifikasi berhasil direset.');
        $this->line('Akun, Ormawa, kegiatan, voting, diskusi, chat, kategori, badge, dan tipe aktivitas tetap dipertahankan.');

        return self::SUCCESS;
    }
}
