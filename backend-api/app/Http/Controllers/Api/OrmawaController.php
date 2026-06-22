<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Ormawa\StoreOrmawaRequest;
use App\Http\Requests\Ormawa\UpdateOrmawaRequest;
use App\Http\Resources\OrmawaResource;
use App\Models\Ormawa;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

class OrmawaController extends Controller
{
    use ApiResponse;

    public function index(): JsonResponse
    {
        $ormawas = Ormawa::with('users')->latest()->get();

        return $this->successResponse('Data ormawa berhasil diambil', OrmawaResource::collection($ormawas));
    }

    public function store(StoreOrmawaRequest $request): JsonResponse
    {
        $data = $request->validated();

        $ormawa = Ormawa::create($data)->load('users');

        return $this->successResponse('Data ormawa berhasil dibuat', new OrmawaResource($ormawa), 201);
    }

    public function show(Ormawa $ormawa): JsonResponse
    {
        return $this->successResponse(
            'Detail ormawa berhasil diambil',
            new OrmawaResource($ormawa->load('users'))
        );
    }

    public function update(UpdateOrmawaRequest $request, Ormawa $ormawa): JsonResponse
    {
        $data = $request->validated();

        $ormawa->update($data);

        return $this->successResponse(
            'Data ormawa berhasil diperbarui',
            new OrmawaResource($ormawa->fresh('users'))
        );
    }

    public function destroy(Ormawa $ormawa): JsonResponse
    {
        $ormawa->delete();

        return $this->successResponse('Data ormawa berhasil dihapus');
    }
}
