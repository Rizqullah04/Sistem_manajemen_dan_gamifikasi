<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class VerifikasiResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id_verifikasi' => $this->id_verifikasi,
            'id_kegiatan' => $this->id_kegiatan,
            'id_admin' => $this->id_admin,
            'catatan' => $this->catatan,
            'status' => $this->status,
            'tanggal_verifikasi' => $this->tanggal_verifikasi?->toISOString(),
            'admin' => $this->whenLoaded('admin', fn () => new UserResource($this->admin)),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
