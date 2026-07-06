<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\Ormawa;
use App\Models\User;
use App\Models\UserOrmawaMembership;
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
        $bemId = Ormawa::query()
            ->where('nama_ormawa', 'like', '%BEM%')
            ->value('id_ormawa');
        $users = User::with([
            'ormawa',
            'adminProfile',
            'ormawaMemberships' => fn ($query) => $query
                ->when($bemId, fn ($membershipQuery, $id) => $membershipQuery->where('id_ormawa', $id))
                ->with('ormawa'),
        ])
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

    public function bemMembers(Request $request): JsonResponse
    {
        $bem = $this->resolveBemOrmawa($request);
        if ($bem instanceof JsonResponse) {
            return $bem;
        }

        $members = User::with([
            'ormawa',
            'ormawaMemberships' => fn ($query) => $query
                ->where('id_ormawa', $bem->id_ormawa)
                ->with('ormawa'),
        ])
            ->where('role', 'anggota')
            ->latest()
            ->get();

        return $this->successResponse('Data anggota BEM berhasil diambil', UserResource::collection($members));
    }

    public function appointBemMember(Request $request): JsonResponse
    {
        $bem = $this->resolveBemOrmawa($request);
        if ($bem instanceof JsonResponse) {
            return $bem;
        }

        $data = $request->validate([
            'id_user' => ['required', 'exists:users,id_user'],
        ]);
        $user = User::where('role', 'anggota')->findOrFail($data['id_user']);

        UserOrmawaMembership::updateOrCreate([
            'id_user' => $user->id_user,
            'id_ormawa' => $bem->id_ormawa,
        ], [
            'status' => 'aktif',
            'appointed_by' => $request->user()->id_user,
        ]);

        return $this->successResponse(
            'Anggota berhasil ditambahkan ke BEM.',
            new UserResource($user->fresh([
                'ormawa',
                'ormawaMemberships' => fn ($query) => $query
                    ->where('id_ormawa', $bem->id_ormawa)
                    ->with('ormawa'),
            ]))
        );
    }

    public function removeBemMember(Request $request, User $user): JsonResponse
    {
        $bem = $this->resolveBemOrmawa($request);
        if ($bem instanceof JsonResponse) {
            return $bem;
        }

        UserOrmawaMembership::where('id_user', $user->id_user)
            ->where('id_ormawa', $bem->id_ormawa)
            ->delete();

        return $this->successResponse('Anggota berhasil dikeluarkan dari BEM.');
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

    private function resolveBemOrmawa(Request $request): Ormawa|JsonResponse
    {
        $user = $request->user();
        if ($user->role === 'ormawa') {
            $ormawa = $user->ormawa;
            if ($ormawa === null || ! $this->isBemOrmawa($ormawa)) {
                return $this->errorResponse('Fitur ini hanya tersedia untuk akun BEM.', status: 403);
            }

            return $ormawa;
        }

        $bem = Ormawa::query()
            ->where('nama_ormawa', 'like', '%BEM%')
            ->first();

        if ($bem === null) {
            return $this->errorResponse('Data BEM belum tersedia.', status: 422);
        }

        return $bem;
    }

    private function isBemOrmawa(Ormawa $ormawa): bool
    {
        return str_contains(strtolower($ormawa->nama_ormawa.' '.$ormawa->deskripsi), 'bem');
    }
}
