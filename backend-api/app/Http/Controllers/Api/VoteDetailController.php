<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\VoteDetailResource;
use App\Models\VoteDetail;
use App\Models\Voting;
use App\Services\PoinService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class VoteDetailController extends Controller
{
    use ApiResponse;

    public function store(Request $request, PoinService $poinService): JsonResponse
    {
        $data = $request->validate([
            'id_voting' => ['required', 'exists:votings,id_voting'],
            'pilihan' => ['required', 'string', 'max:150'],
        ]);

        $voting = Voting::findOrFail($data['id_voting']);
        if ($voting->status !== 'aktif' || now()->lt($voting->tanggal_mulai) || now()->gt($voting->tanggal_selesai)) {
            return $this->errorResponse('Voting tidak sedang aktif.', status: 422);
        }

        $pollOptions = is_array($voting->poll_options) ? $voting->poll_options : [];
        if ($pollOptions !== [] && ! in_array($data['pilihan'], $pollOptions, true)) {
            return $this->errorResponse('Pilihan tidak tersedia pada polling ini.', status: 422);
        }

        $data['id_user'] = $request->user()->id_user;
        $data['tanggal_vote'] = now();

        $vote = VoteDetail::firstOrCreate(
            ['id_voting' => $data['id_voting'], 'id_user' => $data['id_user']],
            ['pilihan' => $data['pilihan'], 'tanggal_vote' => $data['tanggal_vote']]
        )->load('user');

        if (! $vote->wasRecentlyCreated) {
            return $this->errorResponse('Anda sudah melakukan vote pada voting ini.', status: 422);
        }

        $poinService->tambahPoinUser($request->user(), 'voting', $vote->id_vote, 1, 'Melakukan voting');

        return $this->successResponse('Vote berhasil disimpan', new VoteDetailResource($vote), 201);
    }
}
