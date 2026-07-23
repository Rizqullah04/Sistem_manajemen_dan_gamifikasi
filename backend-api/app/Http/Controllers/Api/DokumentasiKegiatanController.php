<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\DokumentasiKegiatanResource;
use App\Models\DokumentasiKegiatan;
use App\Models\Kegiatan;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rules\File;

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

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'id_kegiatan' => ['required', 'exists:kegiatans,id_kegiatan'],
            'caption' => ['nullable', 'string'],
            'file_url' => ['nullable', 'url:http,https', 'max:2048', 'required_without:file'],
            'file' => [
                'nullable',
                'required_without:file_url',
                File::image()->types(['jpg', 'jpeg', 'png'])->max(5 * 1024),
            ],
        ]);

        $kegiatan = Kegiatan::findOrFail($data['id_kegiatan']);

        if (! $this->bolehAksesOrmawa($request, $kegiatan->id_ormawa)) {
            return $this->errorResponse('Anda tidak memiliki akses ke kegiatan ini.', status: 403);
        }

        if ($request->hasFile('file')) {
            $path = $request->file('file')->store(
                "activity-documentation/{$kegiatan->id_kegiatan}",
                'public'
            );
            $data['file_url'] = asset(Storage::url($path));
        }

        $dokumentasi = DokumentasiKegiatan::create([
            'id_kegiatan' => $kegiatan->id_kegiatan,
            'id_ormawa' => $kegiatan->id_ormawa,
            'caption' => $data['caption'] ?? null,
            'file_url' => $data['file_url'],
            'tanggal_upload' => now(),
        ]);

        return $this->successResponse('Dokumentasi berhasil dibuat', new DokumentasiKegiatanResource($dokumentasi), 201);
    }

    private function bolehAksesOrmawa(Request $request, int $idOrmawa): bool
    {
        return $request->user()->role === 'admin'
            || ($request->user()->role === 'ormawa' && (int) $request->user()->id_ormawa === $idOrmawa);
    }
}
