<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\Ormawa;
use App\Models\Period;
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

    private const POSITIONS = [
        'ketua',
        'wakil_ketua',
        'sekretaris',
        'bendahara',
        'anggota_pengurus',
    ];

    public function index(Request $request): JsonResponse
    {
        $activePeriodId = $this->activePeriod()?->id_period;
        $users = User::with([
            'ormawa',
            'ormawaMemberships' => fn ($query) => $query
                ->when($activePeriodId, fn ($membershipQuery, $periodId) => $membershipQuery
                    ->where('id_period', $periodId))
                ->where('status', 'aktif')
                ->with(['ormawa', 'period']),
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

        $activePeriodId = $this->activePeriod()?->id_period;
        $members = User::with([
            'ormawa',
            'ormawaMemberships' => fn ($query) => $query
                ->where('id_ormawa', $ormawaId)
                ->when($activePeriodId, fn ($membershipQuery, $periodId) => $membershipQuery
                    ->where('id_period', $periodId))
                ->with(['ormawa', 'period']),
        ])
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

        $activePeriodId = $this->activePeriod()?->id_period;
        $members = User::with([
            'ormawa',
            'ormawaMemberships' => fn ($query) => $query
                ->where('id_ormawa', $bem->id_ormawa)
                ->when($activePeriodId, fn ($membershipQuery, $periodId) => $membershipQuery
                    ->where('id_period', $periodId))
                ->with(['ormawa', 'period']),
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

        $data = $request->validate($this->appointmentRules(includeUser: true));
        $user = User::where('role', 'anggota')->findOrFail($data['id_user']);

        return $this->appointOfficial($request, $user, $bem, $data);
    }

    public function removeBemMember(Request $request, User $user): JsonResponse
    {
        $bem = $this->resolveBemOrmawa($request);
        if ($bem instanceof JsonResponse) {
            return $bem;
        }

        $this->deactivateCurrentAppointment($user, $bem);

        return $this->successResponse('Anggota berhasil dikeluarkan dari BEM.');
    }

    public function appointDpmMember(Request $request): JsonResponse
    {
        $dpm = $this->resolveDpmOrmawa();
        if ($dpm instanceof JsonResponse) {
            return $dpm;
        }

        $data = $request->validate($this->appointmentRules(includeUser: true));
        $user = User::where('role', 'anggota')->findOrFail($data['id_user']);

        return $this->appointOfficial($request, $user, $dpm, $data);
    }

    public function removeDpmMember(Request $request, User $user): JsonResponse
    {
        $dpm = $this->resolveDpmOrmawa();
        if ($dpm instanceof JsonResponse) {
            return $dpm;
        }

        $this->deactivateCurrentAppointment($user, $dpm);

        return $this->successResponse('Jabatan pengurus DPM berhasil dinonaktifkan.');
    }

    public function appointOrmawaOfficial(Request $request, User $user): JsonResponse
    {
        $ormawa = $request->user()->ormawa;
        if ($ormawa === null) {
            return $this->errorResponse('Akun Ormawa belum terhubung ke data Ormawa.', status: 422);
        }

        if (! $this->isBemOrmawa($ormawa) && (int) $user->id_ormawa !== (int) $ormawa->id_ormawa) {
            return $this->errorResponse(
                'Himpunan hanya dapat menunjuk mahasiswa dari program studinya sendiri.',
                status: 403
            );
        }

        $data = $request->validate($this->appointmentRules());

        return $this->appointOfficial($request, $user, $ormawa, $data);
    }

    public function removeOrmawaOfficial(Request $request, User $user): JsonResponse
    {
        $ormawa = $request->user()->ormawa;
        if ($ormawa === null) {
            return $this->errorResponse('Akun Ormawa belum terhubung ke data Ormawa.', status: 422);
        }

        $this->deactivateCurrentAppointment($user, $ormawa);

        return $this->successResponse('Jabatan pengurus berhasil dinonaktifkan.');
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

        return $this->successResponse('User berhasil diperbarui', new UserResource($user->fresh('ormawa')));
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

    private function resolveDpmOrmawa(): Ormawa|JsonResponse
    {
        $dpm = Ormawa::query()
            ->where('nama_ormawa', 'like', '%DPM%')
            ->first();

        if ($dpm === null) {
            return $this->errorResponse('Data DPM belum tersedia.', status: 422);
        }

        return $dpm;
    }

    private function isBemOrmawa(Ormawa $ormawa): bool
    {
        return str_contains(strtolower($ormawa->nama_ormawa.' '.$ormawa->deskripsi), 'bem');
    }

    private function activePeriod(): ?Period
    {
        return Period::where('status', 'active')->latest('starts_on')->first();
    }

    private function appointmentRules(bool $includeUser = false): array
    {
        return [
            ...($includeUser ? ['id_user' => ['required', 'exists:users,id_user']] : []),
            'position' => [$includeUser ? 'sometimes' : 'required', Rule::in(self::POSITIONS)],
            'division' => ['nullable', 'string', 'max:100'],
        ];
    }

    private function appointOfficial(
        Request $request,
        User $user,
        Ormawa $ormawa,
        array $data
    ): JsonResponse {
        if ($user->role !== 'anggota' || $user->status_akun !== 'aktif') {
            return $this->errorResponse(
                'Hanya mahasiswa dengan akun aktif yang dapat ditunjuk sebagai pengurus.',
                status: 422
            );
        }

        $period = $this->activePeriod();
        if ($period === null) {
            return $this->errorResponse(
                'Belum ada periode aktif untuk penunjukan pengurus.',
                status: 422
            );
        }

        $conflictingAppointment = UserOrmawaMembership::query()
            ->where('id_user', $user->id_user)
            ->where('id_period', $period->id_period)
            ->where('status', 'aktif')
            ->where('id_ormawa', '!=', $ormawa->id_ormawa)
            ->with('ormawa')
            ->first();

        if ($conflictingAppointment !== null) {
            return $this->errorResponse(
                "Mahasiswa masih menjabat sebagai pengurus {$conflictingAppointment->ormawa?->nama_ormawa} pada periode yang sama.",
                status: 422
            );
        }

        $position = $data['position'] ?? 'anggota_pengurus';

        if (in_array($position, ['ketua', 'wakil_ketua'], true)) {
            $positionOccupied = UserOrmawaMembership::query()
                ->where('id_ormawa', $ormawa->id_ormawa)
                ->where('id_period', $period->id_period)
                ->where('position', $position)
                ->where('status', 'aktif')
                ->where('id_user', '!=', $user->id_user)
                ->exists();

            if ($positionOccupied) {
                return $this->errorResponse(
                    'Jabatan tersebut sudah diisi oleh pengurus aktif pada periode ini.',
                    status: 422
                );
            }
        }

        UserOrmawaMembership::updateOrCreate([
            'id_user' => $user->id_user,
            'id_ormawa' => $ormawa->id_ormawa,
            'id_period' => $period->id_period,
        ], [
            'status' => 'aktif',
            'position' => $position,
            'division' => $data['division'] ?? null,
            'starts_at' => $period->starts_on,
            'ends_at' => $period->ends_on,
            'appointed_by' => $request->user()->id_user,
        ]);

        return $this->successResponse(
            'Jabatan pengurus berhasil disimpan.',
            new UserResource($user->fresh([
                'ormawa',
                'ormawaMemberships' => fn ($query) => $query
                    ->where('id_ormawa', $ormawa->id_ormawa)
                    ->where('id_period', $period->id_period)
                    ->with(['ormawa', 'period']),
            ]))
        );
    }

    private function deactivateCurrentAppointment(User $user, Ormawa $ormawa): void
    {
        $period = $this->activePeriod();

        UserOrmawaMembership::query()
            ->where('id_user', $user->id_user)
            ->where('id_ormawa', $ormawa->id_ormawa)
            ->when($period, fn ($query, Period $activePeriod) => $query
                ->where('id_period', $activePeriod->id_period))
            ->where('status', 'aktif')
            ->update(['status' => 'nonaktif', 'ends_at' => now()->toDateString()]);
    }
}
