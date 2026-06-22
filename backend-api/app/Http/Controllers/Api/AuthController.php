<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\RegisterRequest;
use App\Http\Resources\UserResource;
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
            'user' => new UserResource($user),
            'token' => $token,
            'token_type' => 'Bearer',
        ]);
    }

    public function profile(Request $request): JsonResponse
    {
        return $this->successResponse('Profile user berhasil diambil', new UserResource($request->user()));
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
