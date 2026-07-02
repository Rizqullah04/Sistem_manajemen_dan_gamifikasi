<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Kegiatan\StoreKegiatanRequest;
use App\Http\Requests\Kegiatan\UpdateKegiatanRequest;
use App\Http\Requests\Kegiatan\VerifikasiKegiatanRequest;
use App\Http\Resources\KegiatanResource;
use App\Models\Kegiatan;
use App\Models\Ormawa;
use App\Models\Verifikasi;
use App\Services\PoinService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class KegiatanController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $kegiatans = Kegiatan::with(['ormawa', 'votings', 'verifikasis.admin', 'dokumentasiKegiatans'])
            ->withCount('likeKegiatans')
            ->when($request->user()->role === 'ormawa', function ($query) use ($request) {
                $query->where('id_ormawa', $request->user()->id_ormawa);
            })
            ->when($request->status, fn ($query, string $status) => $query->where('status', $status))
            ->when($request->id_ormawa, fn ($query, string $ormawaId) => $query->where('id_ormawa', $ormawaId))
            ->latest()
            ->get();

        return $this->successResponse('Data kegiatan berhasil diambil', KegiatanResource::collection($kegiatans));
    }

    public function store(StoreKegiatanRequest $request): JsonResponse
    {
        $data = $request->validated();

        if (! $this->userDapatMengaksesOrmawa($request, (int) $data['id_ormawa'])) {
            return $this->errorResponse('Anda tidak memiliki akses ke ormawa ini.', status: 403);
        }

        $data['status'] = Kegiatan::STATUS_PENDING;

        $kegiatan = Kegiatan::create($data)->load(['ormawa', 'votings', 'verifikasis.admin'])->loadCount('likeKegiatans');

        return $this->successResponse('Kegiatan berhasil dibuat', new KegiatanResource($kegiatan), 201);
    }

    public function show(Kegiatan $kegiatan): JsonResponse
    {
        if (! $this->userDapatMelihatKegiatan(request(), $kegiatan->id_ormawa)) {
            return $this->errorResponse('Anda tidak memiliki akses ke kegiatan ini.', status: 403);
        }

        return $this->successResponse(
            'Detail kegiatan berhasil diambil',
            new KegiatanResource($kegiatan->load(['ormawa', 'votings', 'verifikasis.admin', 'dokumentasiKegiatans', 'diskusis.user'])->loadCount('likeKegiatans'))
        );
    }

    public function update(UpdateKegiatanRequest $request, Kegiatan $kegiatan, PoinService $poinService): JsonResponse
    {
        if (! $this->userDapatMengaksesOrmawa($request, $kegiatan->id_ormawa)) {
            return $this->errorResponse('Anda tidak memiliki akses ke kegiatan ini.', status: 403);
        }

        $data = $request->validated();

        if (isset($data['id_ormawa']) && ! $this->userDapatMengaksesOrmawa($request, (int) $data['id_ormawa'])) {
            return $this->errorResponse('Anda tidak memiliki akses ke ormawa tujuan.', status: 403);
        }

        $statusLama = $kegiatan->status;
        if ($kegiatan->status !== Kegiatan::STATUS_PENDING) {
            $data['status'] = Kegiatan::STATUS_PENDING;
        }

        $kegiatan->update($data);
        if ($statusLama === Kegiatan::STATUS_VALID && $kegiatan->status !== Kegiatan::STATUS_VALID) {
            $poinService->batalkanPoinOrmawa($kegiatan->ormawa, 'kegiatan', $kegiatan->id_kegiatan);
        }
        $kegiatan->ormawa->recalculateTotalPoin();

        return $this->successResponse(
            'Kegiatan berhasil diperbarui',
            new KegiatanResource($kegiatan->fresh(['ormawa', 'votings', 'verifikasis.admin'])->loadCount('likeKegiatans'))
        );
    }

    public function destroy(Kegiatan $kegiatan, PoinService $poinService): JsonResponse
    {
        if (! $this->userDapatMengaksesOrmawa(request(), $kegiatan->id_ormawa)) {
            return $this->errorResponse('Anda tidak memiliki akses ke kegiatan ini.', status: 403);
        }

        $ormawa = $kegiatan->ormawa;
        $referensiIds = [
            $kegiatan->id_kegiatan,
            ...$kegiatan->dokumentasiKegiatans()->pluck('id_dokumentasi')->all(),
        ];

        $poinService->batalkanPoinOrmawa($ormawa, 'kegiatan', $referensiIds);
        $kegiatan->delete();
        $ormawa->recalculateTotalPoin();

        return $this->successResponse('Kegiatan berhasil dihapus');
    }

    public function verifikasi(VerifikasiKegiatanRequest $request, Kegiatan $kegiatan, PoinService $poinService): JsonResponse
    {
        $data = $request->validated();
        $kegiatan = DB::transaction(function () use ($request, $kegiatan, $data, $poinService): Kegiatan {
            $lockedKegiatan = Kegiatan::whereKey($kegiatan->id_kegiatan)
                ->lockForUpdate()
                ->firstOrFail();
            $statusLama = $lockedKegiatan->status;
            $lockedKegiatan->update([
                'status' => $data['status'],
            ]);

            Verifikasi::create([
                'id_kegiatan' => $lockedKegiatan->id_kegiatan,
                'id_admin' => $request->user()->id_user,
                'catatan' => $data['catatan'] ?? null,
                'status' => $data['status'],
                'tanggal_verifikasi' => now(),
            ]);

            if ($data['status'] === Kegiatan::STATUS_VALID && $statusLama !== Kegiatan::STATUS_VALID) {
                $poinService->tambahPoinOrmawa($lockedKegiatan->ormawa, 'kegiatan', $lockedKegiatan->id_kegiatan, $lockedKegiatan->poin_kegiatan, 'Kegiatan valid');
            } elseif ($statusLama === Kegiatan::STATUS_VALID && $data['status'] !== Kegiatan::STATUS_VALID) {
                $poinService->batalkanPoinOrmawa($lockedKegiatan->ormawa, 'kegiatan', $lockedKegiatan->id_kegiatan);
            } else {
                $lockedKegiatan->ormawa->recalculateTotalPoin();
            }

            return $lockedKegiatan;
        });

        return $this->successResponse(
            'Kegiatan berhasil diverifikasi',
            new KegiatanResource($kegiatan->fresh(['ormawa', 'votings', 'verifikasis.admin'])->loadCount('likeKegiatans'))
        );
    }

    private function userDapatMengaksesOrmawa(Request $request, int $ormawaId): bool
    {
        if ($request->user()->role === 'admin') {
            return true;
        }

        return Ormawa::whereKey($ormawaId)
            ->whereHas('users', fn ($query) => $query->whereKey($request->user()->id_user))
            ->exists();
    }

    private function userDapatMelihatKegiatan(Request $request, int $ormawaId): bool
    {
        if ($request->user()->role === 'anggota') {
            return true;
        }

        return $this->userDapatMengaksesOrmawa($request, $ormawaId);
    }
}
