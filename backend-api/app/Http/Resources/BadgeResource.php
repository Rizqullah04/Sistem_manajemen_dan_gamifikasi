<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BadgeResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'nama_badge' => $this->nama_badge,
            'deskripsi' => $this->deskripsi,
            'activity_type' => $this->activity_type,
            'minimal_poin' => $this->minimal_poin,
            'icon' => $this->icon,
            'tanggal_diperoleh' => $this->pivot?->tanggal_diperoleh,
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
