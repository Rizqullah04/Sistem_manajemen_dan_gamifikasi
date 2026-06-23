<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Services\PoinService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $users = User::with(['ormawa', 'adminProfile'])
            ->when($request->role, fn ($query, string $role) => $query->where('role', $role))
            ->latest()
            ->get();

        return $this->successResponse('Data user berhasil diambil', UserResource::collection($users));
    }

    public function ormawaMembers(Request $request): JsonResponse
    {
        $ormawaId = $request->user()->id_ormawa;

        if (! $ormawaId) {
            return $this->errorResponse('Akun Ormawa belum terhubung ke data Ormawa.', status: 422);
        }

        $members = User::with('ormawa')
            ->where('role', 'anggota')
            ->where('id_ormawa', $ormawaId)
            ->latest()
            ->get();

        return $this->successResponse('Data anggota Ormawa berhasil diambil', UserResource::collection($members));
    }

    public function updateOrmawaMember(Request $request, User $user): JsonResponse
    {
        $ormawaId = $request->user()->id_ormawa;

        if (! $ormawaId) {
            return $this->errorResponse('Akun Ormawa belum terhubung ke data Ormawa.', status: 422);
        }

        if ($user->role !== 'anggota' || (int) $user->id_ormawa !== (int) $ormawaId) {
            return $this->errorResponse('Anggota tidak terdaftar pada Ormawa Anda.', status: 403);
        }

        $data = $request->validate([
            'status_akun' => ['required', Rule::in(['aktif', 'nonaktif', 'ditolak'])],
        ]);

        $user->update($data);

        return $this->successResponse('Status anggota berhasil diperbarui', new UserResource($user->fresh('ormawa')));
    }

    public function update(Request $request, User $user): JsonResponse
    {
        $data = $request->validate([
            'nama' => ['sometimes', 'string', 'max:100'],
            'email' => ['sometimes', 'email', 'max:100', Rule::unique('users', 'email')->ignore($user->id_user, 'id_user')],
            'role' => ['sometimes', Rule::in(['admin', 'ormawa', 'anggota'])],
            'status_akun' => ['sometimes', Rule::in(['pending', 'aktif', 'nonaktif', 'ditolak'])],
            'id_ormawa' => ['nullable', 'exists:ormawas,id_ormawa'],
        ]);

        if (isset($data['role']) && in_array($data['role'], ['ormawa', 'anggota'], true) && empty($data['id_ormawa']) && empty($user->id_ormawa)) {
            return $this->errorResponse('Akun ormawa dan anggota wajib terhubung ke ormawa.', status: 422);
        }

        $user->update($data);

        return $this->successResponse('User berhasil diperbarui', new UserResource($user->fresh(['ormawa', 'adminProfile'])));
    }

    public function recalculatePoin(User $user, PoinService $poinService): JsonResponse
    {
        $user->forceFill(['poin' => $poinService->hitungPoinUser($user)])->save();
        $poinService->evaluasiBadgeUser($user);
        $user->ormawa?->recalculateTotalPoin();

        return $this->successResponse('Poin user berhasil dihitung ulang', new UserResource($user->fresh(['ormawa', 'userBadges.badge'])));
    }
}
