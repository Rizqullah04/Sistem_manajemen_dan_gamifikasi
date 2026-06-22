<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class VoteDetailResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id_vote' => $this->id_vote,
            'id_voting' => $this->id_voting,
            'id_user' => $this->id_user,
            'pilihan' => $this->pilihan,
            'tanggal_vote' => $this->tanggal_vote?->toISOString(),
            'user' => $this->whenLoaded('user', fn () => new UserResource($this->user)),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
