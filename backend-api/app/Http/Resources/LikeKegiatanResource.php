<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class LikeKegiatanResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id_like' => $this->id_like,
            'id_kegiatan' => $this->id_kegiatan,
            'id_user' => $this->id_user,
            'tanggal' => $this->tanggal?->toISOString(),
            'user' => $this->whenLoaded('user', fn () => new UserResource($this->user)),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
