<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Badge\StoreBadgeRequest;
use App\Http\Requests\Badge\UpdateBadgeRequest;
use App\Http\Resources\BadgeResource;
use App\Models\Badge;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

class BadgeController extends Controller
{
    use ApiResponse;

    public function index(): JsonResponse
    {
        return $this->successResponse('Data badge berhasil diambil', BadgeResource::collection(Badge::orderBy('minimal_poin')->get()));
    }

    public function store(StoreBadgeRequest $request): JsonResponse
    {
        $badge = Badge::create($request->validated());

        return $this->successResponse('Badge berhasil dibuat', new BadgeResource($badge), 201);
    }

    public function show(Badge $badge): JsonResponse
    {
        return $this->successResponse('Detail badge berhasil diambil', new BadgeResource($badge));
    }

    public function update(UpdateBadgeRequest $request, Badge $badge): JsonResponse
    {
        $badge->update($request->validated());

        return $this->successResponse('Badge berhasil diperbarui', new BadgeResource($badge));
    }

    public function destroy(Badge $badge): JsonResponse
    {
        $badge->delete();

        return $this->successResponse('Badge berhasil dihapus');
    }
}
