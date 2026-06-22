<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PoinLogResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id_poin_log' => $this->id_poin_log,
            'id_user' => $this->id_user,
            'id_ormawa' => $this->id_ormawa,
            'sumber' => $this->sumber,
            'referensi_id' => $this->referensi_id,
            'poin' => $this->poin,
            'keterangan' => $this->keterangan,
            'tanggal' => $this->tanggal?->toISOString(),
            'user' => $this->whenLoaded('user', fn () => new UserResource($this->user)),
            'ormawa' => $this->whenLoaded('ormawa', fn () => new OrmawaResource($this->ormawa)),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
