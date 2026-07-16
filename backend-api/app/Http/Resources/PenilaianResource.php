<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PenilaianResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'kegiatan_id' => $this->kegiatan_id,
            'juri_id' => $this->juri_id,
            'nilai_kreativitas' => $this->nilai_kreativitas,
            'nilai_dampak' => $this->nilai_dampak,
            'nilai_partisipasi' => $this->nilai_partisipasi,
            'nilai_publikasi' => $this->nilai_publikasi,
            'total_nilai' => $this->total_nilai,
            'komentar' => $this->komentar,
            'kegiatan' => $this->whenLoaded('kegiatan', fn () => new KegiatanResource($this->kegiatan)),
            'juri' => $this->whenLoaded('juri', fn () => new UserResource($this->juri)),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
