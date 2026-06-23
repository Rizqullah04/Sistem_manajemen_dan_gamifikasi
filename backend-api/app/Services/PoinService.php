<?php

namespace App\Services;

use App\Models\Badge;
use App\Models\Ormawa;
use App\Models\Period;
use App\Models\PoinLog;
use App\Models\User;
use App\Models\UserBadge;

class PoinService
{
    public function tambahPoinUser(User $user, string $sumber, int $referensiId, int $poin, ?string $keterangan = null): PoinLog
    {
        $period = $this->activePeriod();

        $log = PoinLog::create([
            'id_period' => $period->id_period,
            'id_user' => $user->id_user,
            'id_ormawa' => null,
            'sumber' => $sumber,
            'referensi_id' => $referensiId,
            'poin' => $poin,
            'keterangan' => $keterangan,
            'tanggal' => now(),
        ]);

        $user->forceFill(['poin' => $this->hitungPoinUser($user)])->save();
        $this->evaluasiBadgeUser($user);
        $user->ormawa?->recalculateTotalPoin();

        return $log;
    }

    public function tambahPoinOrmawa(Ormawa $ormawa, string $sumber, int $referensiId, int $poin, ?string $keterangan = null): PoinLog
    {
        $period = $this->activePeriod();

        $log = PoinLog::create([
            'id_period' => $period->id_period,
            'id_user' => null,
            'id_ormawa' => $ormawa->id_ormawa,
            'sumber' => $sumber,
            'referensi_id' => $referensiId,
            'poin' => $poin,
            'keterangan' => $keterangan,
            'tanggal' => now(),
        ]);

        $ormawa->recalculateTotalPoin();

        return $log;
    }

    public function hitungPoinUser(User $user): int
    {
        return (int) PoinLog::where('id_user', $user->id_user)
            ->where('id_period', $this->activePeriod()->id_period)
            ->sum('poin');
    }

    public function hitungPoinOrmawa(Ormawa $ormawa): int
    {
        return $ormawa->calculateTotalPoinFromLogs();
    }

    public function evaluasiBadgeUser(User $user): int
    {
        $period = $this->activePeriod();
        $user->refresh();
        $totalPoin = (int) $user->poin;
        $badges = Badge::where('minimal_poin', '<=', $totalPoin)
            ->orderBy('minimal_poin')
            ->get();

        $awardedCount = 0;
        foreach ($badges as $badge) {
            $award = UserBadge::firstOrCreate(
                [
                    'id_user' => $user->id_user,
                    'id_badge' => $badge->id,
                ],
                [
                    'id_period' => $period->id_period,
                    'awarded_at' => now(),
                    'notes' => 'Disematkan otomatis setelah mencapai '.$badge->minimal_poin.' poin.',
                ]
            );

            if ($award->wasRecentlyCreated) {
                $awardedCount++;
            }
        }

        return $awardedCount;
    }

    public function activePeriod(): Period
    {
        $active = Period::where('status', 'active')->latest('starts_on')->first();
        if ($active !== null) {
            return $active;
        }

        $year = (int) now()->year;

        return Period::create([
            'year' => $year,
            'name' => (string) $year,
            'starts_on' => now()->startOfYear()->toDateString(),
            'ends_on' => now()->endOfYear()->toDateString(),
            'status' => 'active',
        ]);
    }
}
