<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Diskusi;
use App\Models\Kegiatan;
use App\Models\Leaderboard;
use App\Models\LeaderboardDetail;
use App\Models\Ormawa;
use App\Models\OrmawaAwardResult;
use App\Models\Period;
use App\Models\PoinLog;
use App\Models\VoteDetail;
use App\Models\Voting;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class OrmawaAwardController extends Controller
{
    use ApiResponse;

    private const DEFAULT_WEIGHTS = [
        'points' => 40,
        'voting' => 20,
        'discussion' => 20,
        'attendance' => 20,
    ];

    public function preview(Request $request): JsonResponse
    {
        $payload = $this->validatePayload($request);

        return $this->successResponse(
            'Preview penilaian Ormawa Awards berhasil diambil',
            $this->buildPayload($payload)
        );
    }

    public function generate(Request $request): JsonResponse
    {
        $payload = $this->validatePayload($request);
        $awardPayload = $this->buildPayload($payload);

        if (empty($awardPayload['entries'])) {
            throw ValidationException::withMessages([
                'periode' => ['Tidak ada Ormawa yang dapat dinilai pada periode ini.'],
            ]);
        }

        $result = DB::transaction(function () use ($payload, $awardPayload) {
            $periode = $awardPayload['period']['name'];

            OrmawaAwardResult::where('periode', $periode)->delete();

            $leaderboard = Leaderboard::updateOrCreate(
                [
                    'tipe' => 'ormawa',
                    'periode' => 'ormawa_awards:'.$periode,
                ],
                [
                    'id_period' => null,
                    'tanggal_generate' => now(),
                ],
            );
            $leaderboard->details()->delete();

            foreach ($awardPayload['entries'] as $entry) {
                OrmawaAwardResult::create([
                    'id_period' => $awardPayload['period']['id_period'],
                    'id_ormawa' => $entry['id_ormawa'],
                    'periode' => $periode,
                    'starts_on' => $payload['starts_on'],
                    'ends_on' => $payload['ends_on'],
                    'criteria_weights' => $awardPayload['criteria_weights'],
                    'metrics' => $entry['metrics'],
                    'total_score' => $entry['total_score'],
                    'ranking' => $entry['ranking'],
                    'calculated_at' => now(),
                ]);

                LeaderboardDetail::create([
                    'id_leaderboard' => $leaderboard->id_leaderboard,
                    'id_user' => null,
                    'id_ormawa' => $entry['id_ormawa'],
                    'poin' => (int) round($entry['total_score'] * 100),
                    'ranking' => $entry['ranking'],
                ]);
            }

            return [
                ...$awardPayload,
                'leaderboard_id' => $leaderboard->id_leaderboard,
            ];
        });

        return $this->successResponse('Hasil Ormawa Awards berhasil disimpan', $result, 201);
    }

    private function validatePayload(Request $request): array
    {
        $active = Period::where('status', 'active')->latest('starts_on')->first();

        $payload = $request->validate([
            'period_id' => ['nullable', 'exists:periods,id_period'],
            'period_name' => ['nullable', 'string', 'max:100'],
            'starts_on' => ['nullable', 'date'],
            'ends_on' => ['nullable', 'date', 'after_or_equal:starts_on'],
            'weights' => ['nullable', 'array'],
            'weights.points' => ['nullable', 'numeric', 'min:0', 'max:100'],
            'weights.voting' => ['nullable', 'numeric', 'min:0', 'max:100'],
            'weights.discussion' => ['nullable', 'numeric', 'min:0', 'max:100'],
            'weights.attendance' => ['nullable', 'numeric', 'min:0', 'max:100'],
        ]);

        $period = isset($payload['period_id'])
            ? Period::find($payload['period_id'])
            : $active;

        $startsOn = $payload['starts_on'] ?? $period?->starts_on?->toDateString() ?? now()->startOfYear()->toDateString();
        $endsOn = $payload['ends_on'] ?? $period?->ends_on?->toDateString() ?? now()->endOfYear()->toDateString();
        $weights = array_merge(self::DEFAULT_WEIGHTS, $payload['weights'] ?? []);
        $weightTotal = array_sum($weights);

        if ($weightTotal <= 0) {
            throw ValidationException::withMessages([
                'weights' => ['Total bobot penilaian harus lebih dari 0.'],
            ]);
        }

        return [
            'period' => $period,
            'period_name' => $payload['period_name'] ?? $period?->name ?? Carbon::parse($startsOn)->format('Y'),
            'starts_on' => Carbon::parse($startsOn)->toDateString(),
            'ends_on' => Carbon::parse($endsOn)->toDateString(),
            'weights' => array_map(fn ($value) => (float) $value, $weights),
            'weight_total' => (float) $weightTotal,
        ];
    }

    private function buildPayload(array $payload): array
    {
        $entries = Ormawa::query()
            ->withCount(['users as member_count' => fn ($query) => $query->where('role', 'anggota')])
            ->orderBy('nama_ormawa')
            ->get()
            ->map(fn (Ormawa $ormawa) => $this->buildEntry($ormawa, $payload))
            ->values();

        $max = [
            'points' => max(1, (int) $entries->max(fn (array $entry) => $entry['metrics']['points'])),
            'voting' => max(1, (int) $entries->max(fn (array $entry) => $entry['metrics']['voting_votes'])),
            'discussion' => max(1, (int) $entries->max(fn (array $entry) => $entry['metrics']['discussions'])),
            'attendance' => max(1, (int) $entries->max(fn (array $entry) => $entry['metrics']['attendance'])),
        ];

        $ranked = $entries
            ->map(fn (array $entry) => $this->scoreEntry($entry, $payload, $max))
            ->sortBy([
                ['total_score', 'desc'],
                ['name', 'asc'],
            ])
            ->values()
            ->map(function (array $entry, int $index) {
                $entry['ranking'] = $index + 1;

                return $entry;
            })
            ->all();

        return [
            'period' => [
                'id_period' => $payload['period']?->id_period,
                'name' => $payload['period_name'],
                'starts_on' => $payload['starts_on'],
                'ends_on' => $payload['ends_on'],
            ],
            'criteria_weights' => $payload['weights'],
            'criteria_weight_total' => $payload['weight_total'],
            'normalization_max' => $max,
            'entries' => $ranked,
        ];
    }

    private function buildEntry(Ormawa $ormawa, array $payload): array
    {
        $dateRange = [$payload['starts_on'].' 00:00:00', $payload['ends_on'].' 23:59:59'];

        $validActivities = Kegiatan::query()
            ->where('id_ormawa', $ormawa->id_ormawa)
            ->where('status', Kegiatan::STATUS_VALID)
            ->whereBetween('tanggal', [$payload['starts_on'], $payload['ends_on']])
            ->count();

        $points = (int) PoinLog::query()
            ->whereBetween('tanggal', $dateRange)
            ->where(function ($query) use ($ormawa) {
                $query->where('id_ormawa', $ormawa->id_ormawa)
                    ->orWhereHas('user', fn ($userQuery) => $userQuery->where('id_ormawa', $ormawa->id_ormawa));
            })
            ->sum('poin');

        $votingIds = Voting::query()
            ->where('id_ormawa', $ormawa->id_ormawa)
            ->whereBetween('tanggal_mulai', $dateRange)
            ->pluck('id_voting');

        $voteCount = $votingIds->isEmpty()
            ? 0
            : VoteDetail::query()->whereIn('id_voting', $votingIds)->count();

        $discussionCount = Diskusi::query()
            ->whereBetween('tanggal', $dateRange)
            ->whereHas('kegiatan', fn ($query) => $query->where('id_ormawa', $ormawa->id_ormawa))
            ->count();

        $attendance = PoinLog::query()
            ->where('sumber', 'kegiatan')
            ->whereBetween('tanggal', $dateRange)
            ->whereHas('user', fn ($query) => $query->where('id_ormawa', $ormawa->id_ormawa))
            ->count();

        return [
            'id_ormawa' => $ormawa->id_ormawa,
            'name' => $ormawa->nama_ormawa,
            'member_count' => $ormawa->member_count,
            'metrics' => [
                'activities' => $validActivities,
                'points' => $points,
                'votings' => $votingIds->count(),
                'voting_votes' => $voteCount,
                'discussions' => $discussionCount,
                'attendance' => $attendance,
            ],
        ];
    }

    private function scoreEntry(array $entry, array $payload, array $max): array
    {
        $metrics = $entry['metrics'];
        $components = [
            'points' => ($metrics['points'] / $max['points']) * $payload['weights']['points'],
            'voting' => ($metrics['voting_votes'] / $max['voting']) * $payload['weights']['voting'],
            'discussion' => ($metrics['discussions'] / $max['discussion']) * $payload['weights']['discussion'],
            'attendance' => ($metrics['attendance'] / $max['attendance']) * $payload['weights']['attendance'],
        ];

        $entry['score_components'] = array_map(fn ($value) => round($value, 2), $components);
        $entry['total_score'] = round(array_sum($components) / $payload['weight_total'] * 100, 2);

        return $entry;
    }
}
