<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\DiskusiResource;
use App\Models\Diskusi;
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

        $data['id_user'] = $request->user()->id_user;
        $data['tanggal'] = now();

        $diskusi = Diskusi::create($data)->load('user');

        if ($diskusi->parent_id && $request->user()->role === 'ormawa' && $request->user()->ormawa) {
            $poinService->tambahPoinOrmawa($request->user()->ormawa, 'balasan', $diskusi->id_diskusi, 2, 'Membalas komentar diskusi');
        } elseif ($request->user()->role === 'anggota') {
            $poinService->tambahPoinUser($request->user(), 'komentar', $diskusi->id_diskusi, 15, 'Menulis komentar diskusi');
        }

        return $this->successResponse('Komentar berhasil dibuat', new DiskusiResource($diskusi), 201);
    }

    public function destroy(Diskusi $diskusi, PoinService $poinService): JsonResponse
    {
        if ($diskusi->id_user !== request()->user()->id_user && request()->user()->role !== 'admin') {
            return $this->errorResponse('Anda tidak memiliki akses ke komentar ini.', status: 403);
        }

        if ($diskusi->parent_id && $diskusi->user?->role === 'ormawa' && $diskusi->user->ormawa) {
            $poinService->batalkanPoinOrmawa($diskusi->user->ormawa, 'balasan', $diskusi->id_diskusi);
        } elseif ($diskusi->user?->role === 'anggota') {
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

        $sameCommentExists = Diskusi::query()
            ->where('id_user', $userId)
            ->where('id_kegiatan', $kegiatanId)
            ->whereDate('tanggal', today())
            ->get(['komentar'])
            ->contains(fn (Diskusi $diskusi) => $this->normalisasiKomentar($diskusi->komentar) === $normalizedComment);

        if ($sameCommentExists) {
            return $this->errorResponse('Komentar yang sama sudah pernah dikirim hari ini.', status: 422);
        }

        return null;
    }

    private function normalisasiKomentar(string $komentar): string
    {
        return mb_strtolower(trim((string) preg_replace('/\s+/', ' ', $komentar)));
    }
}
