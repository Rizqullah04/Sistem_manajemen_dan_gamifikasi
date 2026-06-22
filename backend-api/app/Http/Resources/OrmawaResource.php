<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class OrmawaResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id_ormawa' => $this->id_ormawa,
            'nama_ormawa' => $this->nama_ormawa,
            'deskripsi' => $this->deskripsi,
            'total_poin' => $this->total_poin,
            'users' => $this->whenLoaded('users', fn () => UserResource::collection($this->users)),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
