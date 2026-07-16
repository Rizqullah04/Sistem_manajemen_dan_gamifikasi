<?php

namespace App\Http\Requests\Badge;

use App\Http\Requests\ApiFormRequest;

class StoreBadgeRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'nama_badge' => ['required', 'string', 'max:100'],
            'deskripsi' => ['nullable', 'string'],
            'activity_type' => ['required', 'string', 'in:Poin Kumulatif,Keaktifan Diskusi,Partisipasi Event,Voting Berhasil'],
            'minimal_poin' => ['required', 'integer', 'min:0'],
            'icon' => ['required', 'image', 'mimes:png', 'max:2048', 'dimensions:ratio=1/1'],
        ];
    }
}
