<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\DokumentasiKegiatanResource;
use App\Models\DokumentasiKegiatan;
use App\Models\Kegiatan;
use App\Services\PoinService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DokumentasiKegiatanController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $items = DokumentasiKegiatan::query()
            ->when($request->id_kegiatan, fn ($query, string $idKegiatan) => $query->where('id_kegiatan', $idKegiatan))
            ->latest('tanggal_upload')
            ->get();

        return $this->successResponse('Data dokumentasi berhasil diambil', DokumentasiKegiatanResource::collection($items));
    }

    public function store(Request $request, PoinService $poinService): JsonResponse
    {
        $data = $request->validate([
            'id_kegiatan' => ['required', 'exists:kegiatans,id_kegiatan'],
            'caption' => ['nullable', 'string'],
            'file_url' => ['required', 'string', 'max:255'],
        ]);

        $kegiatan = Kegiatan::findOrFail($data['id_kegiatan']);

        if (! $this->bolehAksesOrmawa($request, $kegiatan->id_ormawa)) {
            return $this->errorResponse('Anda tidak memiliki akses ke kegiatan ini.', status: 403);
        }

        $data['id_ormawa'] = $kegiatan->id_ormawa;
        $data['tanggal_upload'] = now();

        $dokumentasi = DokumentasiKegiatan::create($data);

        if ($kegiatan->status === Kegiatan::STATUS_VALID) {
            $poinService->tambahPoinOrmawa($kegiatan->ormawa, 'kegiatan', $dokumentasi->id_dokumentasi, $kegiatan->poin_kegiatan, 'Upload dokumentasi kegiatan valid');
        }

        return $this->successResponse('Dokumentasi berhasil dibuat', new DokumentasiKegiatanResource($dokumentasi), 201);
    }

    private function bolehAksesOrmawa(Request $request, int $idOrmawa): bool
    {
        return $request->user()->role === 'admin'
            || ($request->user()->role === 'ormawa' && (int) $request->user()->id_ormawa === $idOrmawa);
    }
}
