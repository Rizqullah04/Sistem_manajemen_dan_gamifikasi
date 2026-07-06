<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\RegisterRequest;
use App\Http\Resources\BadgeResource;
use App\Http\Resources\PoinLogResource;
use App\Http\Resources\UserResource;
use App\Models\Badge;
use App\Models\Period;
use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use RuntimeException;

class AuthController extends Controller
{
    use ApiResponse;

    public function register(RegisterRequest $request): JsonResponse
    {
        $data = $request->validated();

        $user = User::create([
            'nama' => $data['nama'],
            'nim' => $data['nim'],
            'email' => $data['email'],
            'password' => $data['password'],
            'role' => 'anggota',
            'id_ormawa' => $data['id_ormawa'] ?? null,
            'status_akun' => 'pending',
        ]);

        return $this->successResponse('Registrasi berhasil', new UserResource($user), 201);
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $user = User::where('email', $request->email)->first();

        if (! $user || ! $this->passwordCocok($request->password, $user)) {
            return $this->errorResponse('Email atau password salah.', [
                'errors' => [
                    'email' => ['Email atau password salah.'],
                ],
            ], 422);
        }

        if ($user->status_akun !== 'aktif') {
            $message = match ($user->status_akun) {
                'pending' => 'Akun Anda menunggu verifikasi Ormawa.',
                'ditolak' => 'Akun Anda tidak disetujui sebagai anggota Ormawa.',
                default => 'Akun Anda sedang nonaktif.',
            };

            return $this->errorResponse($message, status: 403);
        }

        $token = $user->createToken('mobile-token')->plainTextToken;

        return $this->successResponse('Login berhasil', [
            'user' => new UserResource($user->load(['ormawa', 'userBadges.badge'])),
            'token' => $token,
            'token_type' => 'Bearer',
        ]);
    }

    public function forgotPassword(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email', 'exists:users,email'],
        ]);

        return $this->successResponse('Email terdaftar. Gunakan OTP demo untuk reset password.', [
            'email' => $data['email'],
            'otp' => '1234',
        ]);
    }

    public function resetPassword(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email', 'exists:users,email'],
            'otp' => ['required', 'string'],
            'password_baru' => ['required', 'string', 'min:8'],
        ]);

        if ($data['otp'] !== '1234') {
            return $this->errorResponse('OTP tidak valid.', [
                'errors' => [
                    'otp' => ['OTP tidak valid.'],
                ],
            ], 422);
        }

        $user = User::where('email', $data['email'])->firstOrFail();
        $user->forceFill([
            'password' => Hash::make($data['password_baru']),
        ])->save();

        $user->tokens()->delete();

        return $this->successResponse('Password berhasil diperbarui.');
    }

    public function profile(Request $request): JsonResponse
    {
        return $this->successResponse('Profile user berhasil diambil', new UserResource($request->user()->load(['ormawa', 'userBadges.badge'])));
    }

    public function gamificationProfile(Request $request): JsonResponse
    {
        $user = $request->user()->load(['userBadges.badge']);
        $activePeriodId = Period::where('status', 'active')->latest('starts_on')->value('id_period');
        $poinLogs = $user->poinLogs()
            ->when($activePeriodId, fn ($query, int $periodId) => $query->where('id_period', $periodId))
            ->latest('tanggal')
            ->get();
        $earnedBadges = $user->userBadges->keyBy('id_badge');
        $availableBadges = Badge::orderBy('minimal_poin')
            ->get()
            ->map(function (Badge $badge) use ($request, $earnedBadges): array {
                $userBadge = $earnedBadges->get($badge->id);

                return [
                    ...((new BadgeResource($badge))->toArray($request)),
                    'status' => $userBadge === null ? 'locked' : 'unlocked',
                    'awarded_at' => $userBadge?->awarded_at?->toISOString(),
                ];
            })
            ->values();

        return $this->successResponse('Data gamifikasi mahasiswa berhasil diambil', [
            'id_user' => $user->id_user,
            'nama' => $user->nama,
            'total_poin' => (int) $user->poin,
            'poin' => (int) $user->poin,
            'status_akun' => $user->status_akun,
            'badges' => (new UserResource($user))->toArray($request)['badges'] ?? [],
            'available_badges' => $availableBadges,
            'poin_logs' => PoinLogResource::collection($poinLogs),
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()?->delete();

        return $this->successResponse('Logout berhasil');
    }

    private function passwordCocok(string $password, User $user): bool
    {
        try {
            return Hash::check($password, $user->password);
        } catch (RuntimeException) {
            if (! hash_equals($user->password, $password)) {
                return false;
            }

            $user->forceFill([
                'password' => $password,
            ])->save();

            return true;
        }
    }
}
