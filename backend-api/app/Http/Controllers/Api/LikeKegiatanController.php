<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\LikeKegiatanResource;
use App\Models\LikeKegiatan;
use App\Services\PoinService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LikeKegiatanController extends Controller
{
    use ApiResponse;

    public function store(Request $request, PoinService $poinService): JsonResponse
    {
        $data = $request->validate([
            'id_kegiatan' => ['required', 'exists:kegiatans,id_kegiatan'],
        ]);

        $like = LikeKegiatan::firstOrCreate([
            'id_kegiatan' => $data['id_kegiatan'],
            'id_user' => $request->user()->id_user,
        ], [
            'tanggal' => now(),
        ]);

        if ($like->wasRecentlyCreated) {
            $poinService->tambahPoinUser($request->user(), 'like', $like->id_like, 1, 'Memberi like kegiatan');
        }

        return $this->successResponse('Like kegiatan berhasil disimpan', new LikeKegiatanResource($like->load('user')), 201);
    }

    public function destroy(LikeKegiatan $likeKegiatan): JsonResponse
    {
        if ($likeKegiatan->id_user !== request()->user()->id_user && request()->user()->role !== 'admin') {
            return $this->errorResponse('Anda tidak memiliki akses ke like ini.', status: 403);
        }

        $likeKegiatan->delete();

        return $this->successResponse('Like kegiatan berhasil dihapus');
    }
}
