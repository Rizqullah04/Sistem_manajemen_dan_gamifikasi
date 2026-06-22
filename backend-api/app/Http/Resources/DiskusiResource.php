<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DiskusiResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id_diskusi' => $this->id_diskusi,
            'id_kegiatan' => $this->id_kegiatan,
            'id_user' => $this->id_user,
            'parent_id' => $this->parent_id,
            'komentar' => $this->komentar,
            'tanggal' => $this->tanggal?->toISOString(),
            'user' => $this->whenLoaded('user', fn () => new UserResource($this->user)),
            'balasan' => $this->whenLoaded('balasan', fn () => DiskusiResource::collection($this->balasan)),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
