<?php

namespace App\Http\Requests\Badge;

use App\Http\Requests\ApiFormRequest;

class UpdateBadgeRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'nama_badge' => ['sometimes', 'string', 'max:255'],
            'deskripsi' => ['nullable', 'string'],
            'minimal_poin' => ['sometimes', 'integer', 'min:0'],
            'icon' => ['sometimes', 'image', 'mimes:png', 'max:2048', 'dimensions:ratio=1/1'],
        ];
    }
}
