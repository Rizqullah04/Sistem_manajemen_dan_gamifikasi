<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\LikeKegiatanResource;
use App\Models\LikeKegiatan;
use App\Models\Kegiatan;
use App\Models\DislikeKegiatan;
use App\Services\PoinService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LikeKegiatanController extends Controller
{
    use ApiResponse;

    public function store(Request $request, PoinService $poinService): JsonResponse
    {
        if ($request->user()->role !== 'anggota' || $request->user()->status_akun !== 'aktif') {
            return $this->errorResponse(
                'Like hanya tersedia untuk mahasiswa aktif.',
                status: 403
            );
        }

        $data = $request->validate([
            'id_kegiatan' => ['required', 'exists:kegiatans,id_kegiatan'],
        ]);
        $kegiatan = Kegiatan::findOrFail($data['id_kegiatan']);
        if (! $kegiatan->dapatDiinteraksikan()) {
            return $this->errorResponse(
                'Interaksi hanya tersedia untuk kegiatan yang telah disetujui.',
                status: 422
            );
        }

        $like = LikeKegiatan::firstOrCreate([
            'id_kegiatan' => $data['id_kegiatan'],
            'id_user' => $request->user()->id_user,
        ], [
            'tanggal' => now(),
        ]);

        $dislike = DislikeKegiatan::where('id_kegiatan', $data['id_kegiatan'])
            ->where('id_user', $request->user()->id_user)
            ->first();

        if ($dislike !== null) {
            $poinService->batalkanPoinUser(
                $request->user(),
                'dislike',
                $dislike->id_dislike
            );
            $dislike->delete();
        }

        if ($like->wasRecentlyCreated) {
            $poinService->tambahPoinUser($request->user(), 'like', $like->id_like, 1, 'Memberi like kegiatan');
        }

        return $this->successResponse(
            'Like kegiatan berhasil disimpan dan 1 poin diberikan.',
            new LikeKegiatanResource($like->load('user')),
            201
        );
    }

    public function destroy(LikeKegiatan $likeKegiatan, PoinService $poinService): JsonResponse
    {
        if ($likeKegiatan->id_user !== request()->user()->id_user && request()->user()->role !== 'admin') {
            return $this->errorResponse('Anda tidak memiliki akses ke like ini.', status: 403);
        }

        if ($likeKegiatan->user) {
            $poinService->batalkanPoinUser($likeKegiatan->user, 'like', $likeKegiatan->id_like);
        }

        $likeKegiatan->delete();

        return $this->successResponse('Like kegiatan berhasil dihapus');
    }

    public function destroyForActivity(Kegiatan $kegiatan, PoinService $poinService): JsonResponse
    {
        $like = LikeKegiatan::where('id_kegiatan', $kegiatan->id_kegiatan)
            ->where('id_user', request()->user()->id_user)
            ->first();
        if ($like === null) {
            return $this->successResponse('Like kegiatan sudah tidak aktif.');
        }

        $poinService->batalkanPoinUser(request()->user(), 'like', $like->id_like);
        $like->delete();

        return $this->successResponse('Like kegiatan berhasil dihapus.');
    }
}
