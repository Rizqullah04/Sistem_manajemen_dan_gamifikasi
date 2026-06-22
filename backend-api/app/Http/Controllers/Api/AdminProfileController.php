<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\AdminProfileResource;
use App\Models\AdminProfile;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AdminProfileController extends Controller
{
    use ApiResponse;

    public function index(): JsonResponse
    {
        return $this->successResponse(
            'Data profil admin berhasil diambil',
            AdminProfileResource::collection(AdminProfile::with('user')->latest()->get())
        );
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'id_user' => ['required', Rule::exists('users', 'id_user')->where('role', 'admin'), 'unique:admin_profiles,id_user'],
            'tipe_admin' => ['required', Rule::in(['DPM', 'staff_dosen'])],
            'nip_nidn' => ['nullable', 'string', 'max:255'],
            'jabatan' => ['nullable', 'string', 'max:255'],
            'unit_kerja' => ['nullable', 'string', 'max:255'],
        ]);

        $profile = AdminProfile::create($data)->load('user');

        return $this->successResponse('Profil admin berhasil dibuat', new AdminProfileResource($profile), 201);
    }

    public function update(Request $request, AdminProfile $adminProfile): JsonResponse
    {
        $data = $request->validate([
            'tipe_admin' => ['sometimes', Rule::in(['DPM', 'staff_dosen'])],
            'nip_nidn' => ['nullable', 'string', 'max:255'],
            'jabatan' => ['nullable', 'string', 'max:255'],
            'unit_kerja' => ['nullable', 'string', 'max:255'],
        ]);

        $adminProfile->update($data);

        return $this->successResponse('Profil admin berhasil diperbarui', new AdminProfileResource($adminProfile->fresh('user')));
    }
}
