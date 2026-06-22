<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ChatResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id_chat' => $this->id_chat,
            'id_pengirim' => $this->id_pengirim,
            'id_penerima' => $this->id_penerima,
            'pesan' => $this->pesan,
            'status_baca' => $this->status_baca,
            'tanggal' => $this->tanggal?->toISOString(),
            'pengirim' => $this->whenLoaded('pengirim', fn () => new UserResource($this->pengirim)),
            'penerima' => $this->whenLoaded('penerima', fn () => new UserResource($this->penerima)),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
