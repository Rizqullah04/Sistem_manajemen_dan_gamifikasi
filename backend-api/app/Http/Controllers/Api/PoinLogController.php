<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\PoinLogResource;
use App\Models\Ormawa;
use App\Models\PoinLog;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PoinLogController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $logs = PoinLog::with(['user', 'ormawa'])
            ->when($request->id_user, fn ($query, string $idUser) => $query->where('id_user', $idUser))
            ->when($request->id_ormawa, fn ($query, string $idOrmawa) => $query->where('id_ormawa', $idOrmawa))
            ->latest('tanggal')
            ->get();

        return $this->successResponse('Data poin log berhasil diambil', PoinLogResource::collection($logs));
    }

    public function recalculateOrmawa(Ormawa $ormawa): JsonResponse
    {
        $ormawa->recalculateTotalPoin();

        return $this->successResponse('Poin ormawa berhasil dihitung ulang', new \App\Http\Resources\OrmawaResource($ormawa->fresh('users')));
    }
}
