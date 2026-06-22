<?php

namespace App\Http\Requests\Badge;

use App\Http\Requests\ApiFormRequest;

class StoreBadgeRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'nama_badge' => ['required', 'string', 'max:255'],
            'deskripsi' => ['nullable', 'string'],
            'minimal_poin' => ['required', 'integer', 'min:0'],
            'icon' => ['nullable', 'string', 'max:255'],
        ];
    }
}
