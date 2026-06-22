<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AdminProfileResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id_admin_profile' => $this->id_admin_profile,
            'id_user' => $this->id_user,
            'tipe_admin' => $this->tipe_admin,
            'nip_nidn' => $this->nip_nidn,
            'jabatan' => $this->jabatan,
            'unit_kerja' => $this->unit_kerja,
            'user' => $this->whenLoaded('user', fn () => new UserResource($this->user)),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
