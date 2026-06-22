<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\ChatResource;
use App\Models\Chat;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ChatController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $userId = $request->user()->id_user;
        $chats = Chat::with(['pengirim', 'penerima'])
            ->where(fn ($query) => $query->where('id_pengirim', $userId)->orWhere('id_penerima', $userId))
            ->oldest('tanggal')
            ->get();

        return $this->successResponse('Data chat berhasil diambil', ChatResource::collection($chats));
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'id_penerima' => ['required', 'exists:users,id_user'],
            'pesan' => ['required', 'string'],
        ]);

        if ((int) $data['id_penerima'] === (int) $request->user()->id_user) {
            return $this->errorResponse('Penerima chat tidak boleh sama dengan pengirim.', status: 422);
        }

        $chat = Chat::create([
            'id_pengirim' => $request->user()->id_user,
            'id_penerima' => $data['id_penerima'],
            'pesan' => $data['pesan'],
            'status_baca' => 'terkirim',
            'tanggal' => now(),
        ])->load(['pengirim', 'penerima']);

        return $this->successResponse('Chat berhasil dikirim', new ChatResource($chat), 201);
    }

    public function update(Request $request, Chat $chat): JsonResponse
    {
        if ($chat->id_penerima !== $request->user()->id_user && $request->user()->role !== 'admin') {
            return $this->errorResponse('Anda tidak memiliki akses ke chat ini.', status: 403);
        }

        $data = $request->validate([
            'status_baca' => ['required', Rule::in(['terkirim', 'dibaca'])],
        ]);

        $chat->update($data);

        return $this->successResponse('Status chat berhasil diperbarui', new ChatResource($chat->fresh(['pengirim', 'penerima'])));
    }
}
