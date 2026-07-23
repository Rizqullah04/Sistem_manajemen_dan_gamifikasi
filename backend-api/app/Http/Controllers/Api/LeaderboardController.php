<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\LeaderboardResource;
use App\Models\Leaderboard;
use App\Models\LeaderboardDetail;
use App\Models\Ormawa;
use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LeaderboardController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $tipe = $request->query('tipe') === 'ormawa' ? 'ormawa' : 'individu';
        $periode = $request->query('periode', 'all_time');

        if ($tipe === 'individu') {
            $users = User::with('ormawa')
                ->where('role', 'anggota')
                ->orderByDesc('poin')
                ->orderBy('nama')
                ->get()
                ->values()
                ->map(function (User $user, int $index) {
                    $user->peringkat = $index + 1;

                    return $user;
                });

            $this->simpanSnapshot('individu', $periode, $users);

            return $this->successResponse('Leaderboard individu berhasil diambil', LeaderboardResource::collection($users));
        }

        $ormawas = Ormawa::where('eligible_for_award', true)
            ->withCount(['kegiatans as total_kegiatan'])
            ->get()
            ->each(function (Ormawa $ormawa) {
                $ormawa->total_poin = $ormawa->calculateTotalPoinFromLogs();
            })
            ->sortBy([
                ['total_poin', 'desc'],
                ['nama_ormawa', 'asc'],
            ])
            ->values()
            ->map(function (Ormawa $ormawa, int $index) {
                $ormawa->peringkat = $index + 1;

                return $ormawa;
            });

        $this->simpanSnapshot('ormawa', $periode, $ormawas);

        return $this->successResponse('Leaderboard berhasil diambil', LeaderboardResource::collection($ormawas));
    }

    private function simpanSnapshot(string $tipe, string $periode, $entries): void
    {
        $leaderboard = Leaderboard::updateOrCreate([
            'tipe' => $tipe,
            'periode' => $periode,
        ], [
            'tanggal_generate' => now(),
        ]);

        $leaderboard->details()->delete();

        foreach ($entries as $entry) {
            LeaderboardDetail::create([
                'id_leaderboard' => $leaderboard->id_leaderboard,
                'id_user' => $tipe === 'individu' ? $entry->id_user : null,
                'id_ormawa' => $tipe === 'ormawa' ? $entry->id_ormawa : null,
                'poin' => $tipe === 'individu' ? $entry->poin : $entry->total_poin,
                'ranking' => $entry->peringkat,
            ]);
        }
    }
}
