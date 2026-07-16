<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\DiskusiResource;
use App\Models\Diskusi;
use App\Models\PoinLog;
use App\Services\PoinService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DiskusiController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $diskusis = Diskusi::with('user')
            ->when($request->id_kegiatan, fn ($query, string $idKegiatan) => $query->where('id_kegiatan', $idKegiatan))
            ->oldest('tanggal')
            ->get();

        return $this->successResponse('Data diskusi berhasil diambil', DiskusiResource::collection($diskusis));
    }

    public function store(Request $request, PoinService $poinService): JsonResponse
    {
        $data = $request->validate([
            'id_kegiatan' => ['required', 'exists:kegiatans,id_kegiatan'],
            'parent_id' => ['nullable', 'exists:diskusis,id_diskusi'],
            'komentar' => ['required', 'string', 'min:5', 'max:1000'],
        ]);

        $spamResponse = $this->cekSpamKomentar($request, $data);
        if ($spamResponse !== null) {
            return $spamResponse;
        }

        $priorCommentIds = Diskusi::query()
            ->where('id_user', $request->user()->id_user)
            ->where('id_kegiatan', $data['id_kegiatan'])
            ->pluck('id_diskusi');
        $rewardedCommentCount = $priorCommentIds->isEmpty()
            ? 0
            : PoinLog::query()
                ->where('sumber', 'komentar')
                ->whereIn('referensi_id', $priorCommentIds)
                ->count();

        $data['id_user'] = $request->user()->id_user;
        $data['tanggal'] = now();

        $diskusi = Diskusi::create($data)->load('user');

        $pointsAwarded = false;
        if ($rewardedCommentCount < 3 && $request->user()->role === 'anggota') {
            $poinService->tambahPoinUser($request->user(), 'komentar', $diskusi->id_diskusi, 5, 'Menulis komentar berkualitas');
            $pointsAwarded = true;
        }

        $message = match (true) {
            $pointsAwarded => 'Komentar berhasil dibuat dan poin diberikan.',
            $request->user()->role === 'admin' => 'Komentar berhasil dibuat. Admin tidak memperoleh poin komentar.',
            $rewardedCommentCount >= 3 => 'Komentar berhasil dibuat tanpa poin karena batas 3 komentar berpoin per kegiatan telah tercapai.',
            default => 'Komentar berhasil dibuat tanpa poin.',
        };

        return $this->successResponse($message, new DiskusiResource($diskusi), 201);
    }

    public function destroy(Diskusi $diskusi, PoinService $poinService): JsonResponse
    {
        if ($diskusi->id_user !== request()->user()->id_user && request()->user()->role !== 'admin') {
            return $this->errorResponse('Anda tidak memiliki akses ke komentar ini.', status: 403);
        }

        if ($diskusi->user?->role === 'anggota') {
            $poinService->batalkanPoinUser($diskusi->user, 'komentar', $diskusi->id_diskusi);
        }

        $diskusi->delete();

        return $this->successResponse('Komentar berhasil dihapus');
    }

    private function cekSpamKomentar(Request $request, array $data): ?JsonResponse
    {
        if ($request->user()->role === 'admin') {
            return null;
        }

        $userId = $request->user()->id_user;
        $kegiatanId = $data['id_kegiatan'];
        $normalizedComment = $this->normalisasiKomentar($data['komentar']);

        $hasRecentComment = Diskusi::query()
            ->where('id_user', $userId)
            ->where('id_kegiatan', $kegiatanId)
            ->where('tanggal', '>=', now()->subSeconds(30))
            ->exists();

        if ($hasRecentComment) {
            return $this->errorResponse('Tunggu 30 detik sebelum mengirim komentar lagi.', status: 429);
        }

        $recentCommentCount = Diskusi::query()
            ->where('id_user', $userId)
            ->where('id_kegiatan', $kegiatanId)
            ->where('tanggal', '>=', now()->subMinutes(10))
            ->count();

        if ($recentCommentCount >= 5) {
            return $this->errorResponse('Komentar terlalu sering. Coba lagi beberapa menit lagi.', status: 429);
        }

        $previousComments = Diskusi::query()
            ->where('id_user', $userId)
            ->where('id_kegiatan', $kegiatanId)
            ->get(['komentar', 'tanggal']);

        $sameCommentExists = $previousComments->contains(
            fn (Diskusi $diskusi) => $this->normalisasiKomentar($diskusi->komentar) === $normalizedComment
        );

        if ($sameCommentExists) {
            return $this->errorResponse('Komentar yang sama sudah pernah dikirim pada kegiatan ini.', status: 422);
        }

        $nearDuplicateExists = $previousComments
            ->where('tanggal', '>=', now()->subDays(7))
            ->contains(function (Diskusi $diskusi) use ($normalizedComment): bool {
                $previous = $this->normalisasiKomentar($diskusi->komentar);

                return $this->kemiripanKomentar($normalizedComment, $previous) >= 85.0;
            });

        if ($nearDuplicateExists) {
            return $this->errorResponse('Komentar terlalu mirip dengan komentar Anda dalam 7 hari terakhir.', status: 422);
        }

        return null;
    }

    private function normalisasiKomentar(string $komentar): string
    {
        $tanpaTandaBaca = preg_replace('/[^\p{L}\p{N}\s]/u', ' ', $komentar);

        return mb_strtolower(trim((string) preg_replace('/\s+/', ' ', (string) $tanpaTandaBaca)));
    }

    private function kemiripanKomentar(string $first, string $second): float
    {
        if ($first === '' || $second === '') {
            return 0.0;
        }

        similar_text($first, $second, $percentage);

        return $percentage;
    }
}
