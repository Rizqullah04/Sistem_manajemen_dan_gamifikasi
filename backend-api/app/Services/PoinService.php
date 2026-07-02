<?php

namespace App\Services;

use App\Models\Badge;
use App\Models\Ormawa;
use App\Models\Period;
use App\Models\PoinLog;
use App\Models\User;
use App\Models\UserBadge;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;

class PoinService
{
    public function tambahPoinUser(User $user, string $sumber, int $referensiId, int $poin, ?string $keterangan = null): PoinLog
    {
        return DB::transaction(function () use ($user, $sumber, $referensiId, $poin, $keterangan): PoinLog {
            $period = $this->activePeriod();
            $idempotencyKey = $this->idempotencyKey($period->id_period, 'user', $user->id_user, $sumber, $referensiId);

            $log = $this->createPoinLogOnce($idempotencyKey, [
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
        });
    }

    public function tambahPoinOrmawa(Ormawa $ormawa, string $sumber, int $referensiId, int $poin, ?string $keterangan = null): PoinLog
    {
        return DB::transaction(function () use ($ormawa, $sumber, $referensiId, $poin, $keterangan): PoinLog {
            $period = $this->activePeriod();
            $idempotencyKey = $this->idempotencyKey($period->id_period, 'ormawa', $ormawa->id_ormawa, $sumber, $referensiId);

            $log = $this->createPoinLogOnce($idempotencyKey, [
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
        });
    }

    public function batalkanPoinUser(User $user, string $sumber, int|array $referensiIds): int
    {
        return DB::transaction(function () use ($user, $sumber, $referensiIds): int {
            $period = $this->activePeriod();
            $deleted = PoinLog::query()
                ->where('id_period', $period->id_period)
                ->where('id_user', $user->id_user)
                ->where('sumber', $sumber)
                ->whereIn('referensi_id', (array) $referensiIds)
                ->delete();

            $user->forceFill(['poin' => $this->hitungPoinUser($user)])->save();
            $user->ormawa?->recalculateTotalPoin();

            return $deleted;
        });
    }

    public function batalkanPoinOrmawa(Ormawa $ormawa, string $sumber, int|array $referensiIds): int
    {
        return DB::transaction(function () use ($ormawa, $sumber, $referensiIds): int {
            $period = $this->activePeriod();
            $deleted = PoinLog::query()
                ->where('id_period', $period->id_period)
                ->where('id_ormawa', $ormawa->id_ormawa)
                ->where('sumber', $sumber)
                ->whereIn('referensi_id', (array) $referensiIds)
                ->delete();

            $ormawa->recalculateTotalPoin();

            return $deleted;
        });
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

    private function idempotencyKey(int $periodId, string $ownerType, int $ownerId, string $sumber, int $referensiId): string
    {
        return implode(':', [$periodId, $ownerType, $ownerId, $sumber, $referensiId]);
    }

    /**
     * Create once by idempotency key. If two requests race, the unique index
     * wins and the loser reads the already-created log.
     */
    private function createPoinLogOnce(string $idempotencyKey, array $attributes): PoinLog
    {
        $existing = PoinLog::where('idempotency_key', $idempotencyKey)->first();
        if ($existing !== null) {
            return $existing;
        }

        try {
            return PoinLog::create([
                'idempotency_key' => $idempotencyKey,
                ...$attributes,
            ]);
        } catch (QueryException $exception) {
            if ($exception->getCode() !== '23000') {
                throw $exception;
            }

            return PoinLog::where('idempotency_key', $idempotencyKey)->firstOrFail();
        }
    }
}
