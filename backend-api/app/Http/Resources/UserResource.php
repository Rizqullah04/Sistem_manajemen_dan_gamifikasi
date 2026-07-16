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
            'nim' => $this->nim,
            'email' => $this->email,
            'poin' => $this->poin,
            'role' => $this->role,
            'status_akun' => $this->status_akun,
            'id_ormawa' => $this->id_ormawa,
            'bem_membership' => $this->whenLoaded('ormawaMemberships', function () {
                $membership = $this->ormawaMemberships->first();
                if ($membership === null) {
                    return null;
                }

                return [
                    'id' => $membership->id,
                    'id_ormawa' => $membership->id_ormawa,
                    'nama_ormawa' => $membership->ormawa?->nama_ormawa,
                    'status' => $membership->status,
                    'appointed_by' => $membership->appointed_by,
                ];
            }),
            'ormawa_total_poin' => $this->whenLoaded('ormawa', fn () => (int) $this->ormawa?->total_poin),
            'ormawa' => $this->whenLoaded('ormawa', fn () => new OrmawaResource($this->ormawa)),
            'badges' => $this->whenLoaded('userBadges', fn () => $this->userBadges
                ->filter(fn ($userBadge) => $userBadge->badge !== null)
                ->map(fn ($userBadge) => [
                    ...((new BadgeResource($userBadge->badge))->toArray($request)),
                    'awarded_at' => $userBadge->awarded_at?->toISOString(),
                    'notes' => $userBadge->notes,
                ])
                ->values()),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
