<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ActivityType;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ActivityTypeController extends Controller
{
    use ApiResponse;

    public function index(): JsonResponse
    {
        return $this->successResponse(
            'Tipe aktivitas berhasil diambil.',
            ActivityType::query()->orderBy('name')->get()
        );
    }

    public function store(Request $request): JsonResponse
    {
        $item = ActivityType::create($this->validated($request));

        return $this->successResponse('Tipe aktivitas berhasil dibuat.', $item, 201);
    }

    public function show(ActivityType $activityType): JsonResponse
    {
        return $this->successResponse('Tipe aktivitas berhasil diambil.', $activityType);
    }

    public function update(Request $request, ActivityType $activityType): JsonResponse
    {
        $activityType->update($this->validated($request, $activityType));

        return $this->successResponse('Tipe aktivitas berhasil diperbarui.', $activityType->fresh());
    }

    public function destroy(ActivityType $activityType): JsonResponse
    {
        if ($activityType->pointHistories()->exists()) {
            return $this->errorResponse('Tipe aktivitas sudah dipakai dan tidak dapat dihapus.', status: 422);
        }

        $activityType->delete();

        return $this->successResponse('Tipe aktivitas berhasil dihapus.');
    }

    private function validated(Request $request, ?ActivityType $activityType = null): array
    {
        return $request->validate([
            'code' => ['required', 'string', 'max:100', Rule::unique('activity_types', 'code')->ignore($activityType?->id_activity_type, 'id_activity_type')],
            'name' => ['required', 'string', 'max:150', Rule::unique('activity_types', 'name')->ignore($activityType?->id_activity_type, 'id_activity_type')],
            'frequency_level' => ['required', Rule::in(['low', 'medium', 'high'])],
            'difficulty_level' => ['required', Rule::in(['easy', 'medium', 'hard'])],
            'organizational_impact' => ['required', Rule::in(['low', 'medium', 'high'])],
            'point_value' => ['required', 'integer', 'min:0'],
            'is_active' => ['required', 'boolean'],
        ]);
    }
}
