<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DislikeKegiatan;
use App\Models\Kegiatan;
use App\Models\LikeKegiatan;
use App\Services\PoinService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DislikeKegiatanController extends Controller
{
    use ApiResponse;

    public function index(Request $request, Kegiatan $kegiatan): JsonResponse
    {
        $user = $request->user();
        if ($user->role !== 'admin' &&
            ($user->role !== 'ormawa' || (int) $user->id_ormawa !== (int) $kegiatan->id_ormawa)) {
            return $this->errorResponse('Masukan perbaikan hanya dapat dilihat pengelola kegiatan dan admin.', status: 403);
        }

        $items = DislikeKegiatan::with('user')
            ->where('id_kegiatan', $kegiatan->id_kegiatan)
            ->latest()
            ->get()
            ->map(fn (DislikeKegiatan $item): array => [
                'id_dislike' => $item->id_dislike,
                'alasan' => $item->alasan,
                'solusi' => $item->solusi,
                'created_at' => $item->created_at?->toISOString(),
                'user' => [
                    'id_user' => $item->user?->id_user,
                    'nama' => $item->user?->nama,
                ],
            ]);

        return $this->successResponse('Masukan perbaikan berhasil diambil.', $items);
    }

    public function store(Request $request, PoinService $poinService): JsonResponse
    {
        if ($request->user()->role !== 'anggota') {
            return $this->errorResponse('Masukan perbaikan hanya dapat diberikan oleh mahasiswa.', status: 403);
        }
        $data = $request->validate([
            'id_kegiatan' => ['required', 'exists:kegiatans,id_kegiatan'],
            'alasan' => ['required', 'string', 'min:10', 'max:1000'],
            'solusi' => ['required', 'string', 'min:10', 'max:1000'],
        ]);

        $dislike = DB::transaction(function () use ($request, $data, $poinService) {
            $like = LikeKegiatan::where('id_kegiatan', $data['id_kegiatan'])
                ->where('id_user', $request->user()->id_user)
                ->first();
            if ($like !== null) {
                $poinService->batalkanPoinUser($request->user(), 'like', $like->id_like);
                $like->delete();
            }

            return DislikeKegiatan::updateOrCreate([
                'id_kegiatan' => $data['id_kegiatan'],
                'id_user' => $request->user()->id_user,
            ], [
                'alasan' => $data['alasan'],
                'solusi' => $data['solusi'],
            ]);
        });

        return $this->successResponse('Masukan perbaikan berhasil disimpan.', $dislike, 201);
    }

    public function destroy(Request $request, Kegiatan $kegiatan): JsonResponse
    {
        DislikeKegiatan::where('id_kegiatan', $kegiatan->id_kegiatan)
            ->where('id_user', $request->user()->id_user)
            ->delete();

        return $this->successResponse('Dislike kegiatan berhasil dibatalkan.');
    }
}
