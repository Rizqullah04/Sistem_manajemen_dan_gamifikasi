<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\VotingResource;
use App\Models\Voting;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class VotingController extends Controller
{
    use ApiResponse;

    public function index(): JsonResponse
    {
        return $this->successResponse(
            'Data voting berhasil diambil',
            VotingResource::collection(Voting::with('voteDetails.user')->latest()->get())
        );
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'id_kegiatan' => ['nullable', 'exists:kegiatans,id_kegiatan'],
            'judul_voting' => ['required', 'string', 'max:255'],
            'tanggal_mulai' => ['required', 'date'],
            'tanggal_selesai' => ['required', 'date', 'after:tanggal_mulai'],
            'jenis_voting' => ['required', Rule::in(['kegiatan', 'ketua'])],
            'poll_options' => ['required', 'array', 'min:2'],
            'poll_options.*' => ['required', 'string', 'max:255'],
            'status' => ['sometimes', Rule::in(['aktif', 'selesai'])],
        ]);

        $kegiatan = null;
        if (! empty($data['id_kegiatan'])) {
            $kegiatan = \App\Models\Kegiatan::findOrFail($data['id_kegiatan']);
            if ($request->user()->role === 'ormawa' && (int) $request->user()->id_ormawa !== (int) $kegiatan->id_ormawa) {
                return $this->errorResponse('Anda tidak memiliki akses membuat voting untuk kegiatan ini.', status: 403);
            }
        }

        if ($request->user()->role === 'ormawa' && $data['jenis_voting'] === 'ketua') {
            $minimumPoint = 100;
            if ((int) ($request->user()->poin ?? 0) < $minimumPoint) {
                return $this->errorResponse(
                    'Akumulasi poin ormawa belum mencukupi untuk membuat voting ketua.',
                    status: 403
                );
            }
        }

        $data['id_ormawa'] = $kegiatan?->id_ormawa ?? $request->user()->id_ormawa;
        $data['poll_options'] = array_values(array_unique(array_map('trim', $data['poll_options'])));
        $data['status'] ??= 'aktif';

        $voting = Voting::create($data)->load('voteDetails.user');

        return $this->successResponse('Voting berhasil dibuat', new VotingResource($voting), 201);
    }

    public function show(Voting $voting): JsonResponse
    {
        return $this->successResponse('Detail voting berhasil diambil', new VotingResource($voting->load('voteDetails.user')));
    }

    public function update(Request $request, Voting $voting): JsonResponse
    {
        $data = $request->validate([
            'id_kegiatan' => ['sometimes', 'nullable', 'exists:kegiatans,id_kegiatan'],
            'judul_voting' => ['sometimes', 'string', 'max:255'],
            'tanggal_mulai' => ['sometimes', 'date'],
            'tanggal_selesai' => ['sometimes', 'date', 'after:tanggal_mulai'],
            'jenis_voting' => ['sometimes', Rule::in(['kegiatan', 'ketua'])],
            'poll_options' => ['sometimes', 'array', 'min:2'],
            'poll_options.*' => ['required_with:poll_options', 'string', 'max:255'],
            'status' => ['sometimes', Rule::in(['aktif', 'selesai'])],
        ]);

        if (array_key_exists('poll_options', $data)) {
            $data['poll_options'] = array_values(array_unique(array_map('trim', $data['poll_options'])));
        }

        $voting->update($data);

        return $this->successResponse('Voting berhasil diperbarui', new VotingResource($voting->fresh('voteDetails.user')));
    }

    public function destroy(Voting $voting): JsonResponse
    {
        $voting->delete();

        return $this->successResponse('Voting berhasil dihapus');
    }
}
