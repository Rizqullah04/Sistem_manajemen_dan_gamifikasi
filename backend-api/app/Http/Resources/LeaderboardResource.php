<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class LeaderboardResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id_user' => $this->when(isset($this->id_user), $this->id_user),
            'id_ormawa' => $this->when(isset($this->id_ormawa), $this->id_ormawa),
            'nama' => $this->nama ?? $this->nama_ormawa,
            'nama_ormawa' => $this->when(
                isset($this->id_user),
                $this->ormawa?->nama_ormawa,
            ),
            'poin' => $this->poin ?? $this->total_poin,
            'total_kegiatan' => $this->when(isset($this->total_kegiatan), $this->total_kegiatan),
            'ranking' => $this->ranking ?? $this->peringkat,
        ];
    }
}
