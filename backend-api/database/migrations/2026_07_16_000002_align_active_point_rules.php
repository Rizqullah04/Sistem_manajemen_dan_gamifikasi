<?php

use App\Models\Ormawa;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::transaction(function (): void {
            DB::table('poin_logs')->whereIn('sumber', ['kegiatan', 'balasan'])->delete();
            DB::table('poin_logs')->where('sumber', 'komentar')->update([
                'poin' => 5,
                'keterangan' => 'Menulis komentar berkualitas',
            ]);
            DB::table('kegiatans')->update(['poin_kegiatan' => 0]);

            DB::table('activity_types')->whereIn('code', [
                'JOIN_EVENT',
                'COMMITTEE_MEMBER',
                'EVENT_COORDINATOR',
                'EVENT_LEADER',
            ])->update(['is_active' => false]);
            DB::table('activity_types')->where('code', 'COMMENT')->update([
                'point_value' => 5,
                'is_active' => true,
            ]);
            DB::table('activity_types')->where('code', 'VOTING')->update([
                'point_value' => 1,
                'is_active' => true,
            ]);

            $activePeriodId = DB::table('periods')
                ->where('status', 'active')
                ->orderByDesc('starts_on')
                ->value('id_period');

            DB::table('users')->select('id_user')->orderBy('id_user')->each(
                function (object $user) use ($activePeriodId): void {
                    $points = DB::table('poin_logs')
                        ->where('id_user', $user->id_user)
                        ->when($activePeriodId, fn ($query) => $query->where('id_period', $activePeriodId))
                        ->sum('poin');
                    DB::table('users')->where('id_user', $user->id_user)->update(['poin' => $points]);
                }
            );

            Ormawa::query()->each(fn (Ormawa $ormawa) => $ormawa->recalculateTotalPoin());
        });
    }

    public function down(): void
    {
        // Normalisasi poin bersifat satu arah agar log yang sudah dibatalkan
        // tidak dibuat ulang tanpa bukti aktivitas yang valid.
    }
};
