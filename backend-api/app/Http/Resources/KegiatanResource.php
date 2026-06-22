<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class KegiatanResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id_kegiatan' => $this->id_kegiatan,
            'id_ormawa' => $this->id_ormawa,
            'nama_kegiatan' => $this->nama_kegiatan,
            'deskripsi' => $this->deskripsi,
            'tanggal' => $this->tanggal?->format('Y-m-d'),
            'poin_kegiatan' => $this->poin_kegiatan,
            'status' => $this->status,
            'ormawa' => $this->whenLoaded('ormawa', fn () => new OrmawaResource($this->ormawa)),
            'votings' => $this->whenLoaded('votings', fn () => VotingResource::collection($this->votings)),
            'verifikasis' => $this->whenLoaded('verifikasis', fn () => VerifikasiResource::collection($this->verifikasis)),
            'dokumentasi_kegiatans' => $this->whenLoaded('dokumentasiKegiatans', fn () => DokumentasiKegiatanResource::collection($this->dokumentasiKegiatans)),
            'diskusis' => $this->whenLoaded('diskusis', fn () => DiskusiResource::collection($this->diskusis)),
            'jumlah_like' => $this->whenCounted('likeKegiatans'),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
