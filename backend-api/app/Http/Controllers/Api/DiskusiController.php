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
            'komentar' => ['required', 'string'],
        ]);

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

    public function destroy(Diskusi $diskusi): JsonResponse
    {
        if ($diskusi->id_user !== request()->user()->id_user && request()->user()->role !== 'admin') {
            return $this->errorResponse('Anda tidak memiliki akses ke komentar ini.', status: 403);
        }

        $diskusi->delete();

        return $this->successResponse('Komentar berhasil dihapus');
    }
}
