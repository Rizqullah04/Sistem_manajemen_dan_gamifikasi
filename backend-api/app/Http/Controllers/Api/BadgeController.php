<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Badge\StoreBadgeRequest;
use App\Http\Requests\Badge\UpdateBadgeRequest;
use App\Http\Resources\BadgeResource;
use App\Models\Badge;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Validation\ValidationException;
use Illuminate\Support\Facades\Storage;

class BadgeController extends Controller
{
    use ApiResponse;

    public function index(): JsonResponse
    {
        return $this->successResponse('Data badge berhasil diambil', BadgeResource::collection(Badge::orderBy('minimal_poin')->get()));
    }

    public function store(StoreBadgeRequest $request): JsonResponse
    {
        $data = $request->validated();
        if (! $request->hasFile('icon')) {
            throw ValidationException::withMessages([
                'icon' => ['Icon lencana wajib berupa file PNG.'],
            ]);
        }

        $data['icon'] = $request->file('icon')->store('badges', 'public');

        $badge = Badge::create($data);

        return $this->successResponse('Badge berhasil dibuat', new BadgeResource($badge), 201);
    }

    public function show(Badge $badge): JsonResponse
    {
        return $this->successResponse('Detail badge berhasil diambil', new BadgeResource($badge));
    }

    public function update(UpdateBadgeRequest $request, Badge $badge): JsonResponse
    {
        $data = $request->validated();

        if ($request->hasFile('icon')) {
            if ($badge->icon) {
                Storage::disk('public')->delete($badge->icon);
            }
            $data['icon'] = $request->file('icon')->store('badges', 'public');
        }

        $badge->update($data);

        return $this->successResponse('Badge berhasil diperbarui', new BadgeResource($badge));
    }

    public function destroy(Badge $badge): JsonResponse
    {
        if ($badge->icon) {
            Storage::disk('public')->delete($badge->icon);
        }

        $badge->delete();

        return $this->successResponse('Badge berhasil dihapus');
    }
}
