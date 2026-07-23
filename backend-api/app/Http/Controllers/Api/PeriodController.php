<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Leaderboard;
use App\Models\LeaderboardDetail;
use App\Models\OrganizationPoint;
use App\Models\Ormawa;
use App\Models\Period;
use App\Models\User;
use App\Models\UserPoint;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PeriodController extends Controller
{
    use ApiResponse;

    public function current(): JsonResponse
    {
        return $this->successResponse('Periode aktif berhasil diambil', [
            'active_period' => $this->serializePeriod($this->activePeriod()),
            'archived_periods' => Period::where('status', 'archived')
                ->orderByDesc('year')
                ->get()
                ->map(fn (Period $period) => $this->serializePeriod($period))
                ->values(),
        ]);
    }

    public function endCurrent(Request $request): JsonResponse
    {
        $payload = $request->validate([
            'next_year' => ['nullable', 'integer', 'min:2000', 'max:2100'],
            'next_name' => ['nullable', 'string', 'max:100'],
            'next_starts_on' => ['nullable', 'date'],
            'next_ends_on' => ['nullable', 'date', 'after_or_equal:next_starts_on'],
            'archive_name' => ['nullable', 'string', 'max:100'],
            'archive_ends_on' => ['nullable', 'date'],
        ]);

        $result = DB::transaction(function () use ($payload) {
            $active = $this->activePeriod();

            if (! empty($payload['archive_name'])) {
                $active->name = $payload['archive_name'];
            }

            if (! empty($payload['archive_ends_on'])) {
                $active->ends_on = $payload['archive_ends_on'];
            } elseif ($active->ends_on === null || $active->ends_on->isFuture()) {
                $active->ends_on = today();
            }

            $memberCount = $this->snapshotUsers($active);
            $ormawaCount = $this->snapshotOrmawas($active);

            $active->status = 'archived';
            $active->save();

            User::where('role', 'anggota')->update(['poin' => 0]);
            Ormawa::query()->update(['total_poin' => 0]);

            $nextYear = (int) ($payload['next_year'] ?? ($active->year + 1));
            $next = Period::updateOrCreate(
                ['year' => $nextYear],
                [
                    'name' => $payload['next_name'] ?? (string) $nextYear,
                    'starts_on' => $payload['next_starts_on'] ?? now()->addDay()->toDateString(),
                    'ends_on' => $payload['next_ends_on'] ?? now()->addYear()->toDateString(),
                    'status' => 'active',
                ],
            );

            Period::where('id_period', '!=', $next->id_period)
                ->where('status', 'active')
                ->update(['status' => 'archived']);

            return [
                'archived_period' => $this->serializePeriod($active->fresh()),
                'active_period' => $this->serializePeriod($next->fresh()),
                'snapshot' => [
                    'users' => $memberCount,
                    'ormawas' => $ormawaCount,
                ],
            ];
        });

        return $this->successResponse('Periode berhasil diakhiri dan poin sudah direset', $result);
    }

    private function activePeriod(): Period
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

    private function snapshotUsers(Period $period): int
    {
        $users = User::where('role', 'anggota')
            ->orderByDesc('poin')
            ->orderBy('nama')
            ->get()
            ->values();

        $leaderboard = $this->resetLeaderboard($period, 'individu');

        foreach ($users as $index => $user) {
            $rank = $index + 1;

            UserPoint::updateOrCreate(
                ['id_period' => $period->id_period, 'id_user' => $user->id_user],
                [
                    'total_points' => $user->poin,
                    'rank_position' => $rank,
                    'calculated_at' => now(),
                ],
            );

            LeaderboardDetail::create([
                'id_leaderboard' => $leaderboard->id_leaderboard,
                'id_user' => $user->id_user,
                'id_ormawa' => null,
                'poin' => $user->poin,
                'ranking' => $rank,
            ]);
        }

        return $users->count();
    }

    private function snapshotOrmawas(Period $period): int
    {
        $ormawas = Ormawa::query()
            ->where('eligible_for_award', true)
            ->orderByDesc('total_poin')
            ->orderBy('nama_ormawa')
            ->get()
            ->values();

        $leaderboard = $this->resetLeaderboard($period, 'ormawa');

        foreach ($ormawas as $index => $ormawa) {
            $rank = $index + 1;

            OrganizationPoint::updateOrCreate(
                ['id_period' => $period->id_period, 'id_ormawa' => $ormawa->id_ormawa],
                [
                    'total_event_points' => $ormawa->total_poin,
                    'member_points' => 0,
                    'rank_position' => $rank,
                    'calculated_at' => now(),
                ],
            );

            LeaderboardDetail::create([
                'id_leaderboard' => $leaderboard->id_leaderboard,
                'id_user' => null,
                'id_ormawa' => $ormawa->id_ormawa,
                'poin' => $ormawa->total_poin,
                'ranking' => $rank,
            ]);
        }

        return $ormawas->count();
    }

    private function resetLeaderboard(Period $period, string $type): Leaderboard
    {
        $leaderboard = Leaderboard::updateOrCreate(
            [
                'id_period' => $period->id_period,
                'tipe' => $type,
            ],
            [
                'periode' => $period->name,
                'tanggal_generate' => now(),
            ],
        );

        $leaderboard->details()->delete();

        return $leaderboard;
    }

    private function serializePeriod(Period $period): array
    {
        return [
            'id_period' => $period->id_period,
            'year' => $period->year,
            'name' => $period->name,
            'starts_on' => $period->starts_on?->toDateString(),
            'ends_on' => $period->ends_on?->toDateString(),
            'status' => $period->status,
        ];
    }
}
