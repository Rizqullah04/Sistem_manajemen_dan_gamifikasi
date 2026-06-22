<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id_user' => $this->id_user,
            'nama' => $this->nama,
            'email' => $this->email,
            'poin' => $this->poin,
            'role' => $this->role,
            'status_akun' => $this->status_akun,
            'id_ormawa' => $this->id_ormawa,
            'ormawa' => $this->whenLoaded('ormawa', fn () => new OrmawaResource($this->ormawa)),
            'admin_profile' => $this->whenLoaded('adminProfile', fn () => new AdminProfileResource($this->adminProfile)),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
