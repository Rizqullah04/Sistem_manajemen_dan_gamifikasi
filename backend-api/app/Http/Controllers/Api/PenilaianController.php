<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Penilaian\StorePenilaianRequest;
use App\Http\Requests\Penilaian\UpdatePenilaianRequest;
use App\Http\Resources\PenilaianResource;
use App\Models\Penilaian;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PenilaianController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $penilaians = Penilaian::with(['kegiatan', 'juri'])
            ->where('juri_id', $request->user()->id)
            ->when($request->kegiatan_id, fn ($query, string $kegiatanId) => $query->where('kegiatan_id', $kegiatanId))
            ->latest()
            ->get();

        return $this->successResponse('Data penilaian berhasil diambil', PenilaianResource::collection($penilaians));
    }

    public function store(StorePenilaianRequest $request): JsonResponse
    {
        $data = $request->validated();
        $data['juri_id'] = $request->user()->id;
        $data['total_nilai'] = $this->hitungTotalNilai($data);

        $penilaian = Penilaian::updateOrCreate(
            [
                'kegiatan_id' => $data['kegiatan_id'],
                'juri_id' => $data['juri_id'],
            ],
            $data
        );

        return $this->successResponse('Penilaian berhasil disimpan', new PenilaianResource($penilaian->load(['kegiatan', 'juri'])), 201);
    }

    public function show(Penilaian $penilaian): JsonResponse
    {
        if ($penilaian->juri_id !== request()->user()->id) {
            return $this->errorResponse('Anda tidak memiliki akses ke penilaian ini.', status: 403);
        }

        return $this->successResponse(
            'Detail penilaian berhasil diambil',
            new PenilaianResource($penilaian->load(['kegiatan', 'juri']))
        );
    }

    public function update(UpdatePenilaianRequest $request, Penilaian $penilaian): JsonResponse
    {
        if ($penilaian->juri_id !== $request->user()->id) {
            return $this->errorResponse('Anda tidak memiliki akses ke penilaian ini.', status: 403);
        }

        $data = $request->validated();
        $data['total_nilai'] = $this->hitungTotalNilai(array_merge($penilaian->toArray(), $data));

        $penilaian->update($data);

        return $this->successResponse(
            'Penilaian berhasil diperbarui',
            new PenilaianResource($penilaian->fresh(['kegiatan', 'juri']))
        );
    }

    public function destroy(Penilaian $penilaian): JsonResponse
    {
        if ($penilaian->juri_id !== request()->user()->id) {
            return $this->errorResponse('Anda tidak memiliki akses ke penilaian ini.', status: 403);
        }

        $penilaian->delete();

        return $this->successResponse('Penilaian berhasil dihapus');
    }

    private function hitungTotalNilai(array $data): int
    {
        return (int) (
            $data['nilai_kreativitas']
            + $data['nilai_dampak']
            + $data['nilai_partisipasi']
            + $data['nilai_publikasi']
        );
    }
}
