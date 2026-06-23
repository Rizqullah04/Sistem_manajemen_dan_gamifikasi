<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Ormawa\StoreOrmawaRequest;
use App\Http\Requests\Ormawa\UpdateOrmawaRequest;
use App\Http\Resources\OrmawaResource;
use App\Models\Ormawa;
use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class OrmawaController extends Controller
{
    use ApiResponse;

    public function index(): JsonResponse
    {
        $ormawas = Ormawa::latest()->get();

        return $this->successResponse('Data ormawa berhasil diambil', OrmawaResource::collection($ormawas));
    }

    public function adminIndex(): JsonResponse
    {
        $ormawas = Ormawa::with('users')->latest()->get();

        return $this->successResponse('Data ormawa berhasil diambil', OrmawaResource::collection($ormawas));
    }

    public function store(StoreOrmawaRequest $request): JsonResponse
    {
        $data = $request->validated();

        $ormawa = DB::transaction(function () use ($data) {
            $ormawa = Ormawa::create([
                'nama_ormawa' => $data['nama_ormawa'],
                'deskripsi' => $data['deskripsi'] ?? null,
                'total_poin' => $data['total_poin'] ?? 0,
            ]);

            if (! empty($data['account_email']) && ! empty($data['account_password'])) {
                User::create([
                    'nama' => $data['account_name'] ?? $data['nama_ormawa'],
                    'email' => $data['account_email'],
                    'password' => $data['account_password'],
                    'role' => 'ormawa',
                    'status_akun' => 'aktif',
                    'id_ormawa' => $ormawa->id_ormawa,
                ]);
            }

            return $ormawa->load('users');
        });

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

        DB::transaction(function () use ($data, $ormawa) {
            $ormawa->update([
                'nama_ormawa' => $data['nama_ormawa'] ?? $ormawa->nama_ormawa,
                'deskripsi' => array_key_exists('deskripsi', $data)
                    ? $data['deskripsi']
                    : $ormawa->deskripsi,
                'total_poin' => $data['total_poin'] ?? $ormawa->total_poin,
            ]);

            if (array_key_exists('account_name', $data)) {
                $ormawa->users()
                    ->where('role', 'ormawa')
                    ->oldest('id_user')
                    ->first()
                    ?->update([
                        'nama' => $data['account_name'] ?: $ormawa->nama_ormawa,
                    ]);
            }
        });

        return $this->successResponse(
            'Data ormawa berhasil diperbarui',
            new OrmawaResource($ormawa->fresh('users'))
        );
    }

    public function destroy(Ormawa $ormawa): JsonResponse
    {
        DB::transaction(function () use ($ormawa) {
            $ormawa->users()->where('role', 'ormawa')->delete();
            $ormawa->delete();
        });

        return $this->successResponse('Data ormawa berhasil dihapus');
    }
}
