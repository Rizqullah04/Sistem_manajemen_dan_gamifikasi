<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DokumentasiKegiatanResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id_dokumentasi' => $this->id_dokumentasi,
            'id_kegiatan' => $this->id_kegiatan,
            'id_ormawa' => $this->id_ormawa,
            'caption' => $this->caption,
            'file_url' => $this->file_url,
            'tanggal_upload' => $this->tanggal_upload?->toISOString(),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
