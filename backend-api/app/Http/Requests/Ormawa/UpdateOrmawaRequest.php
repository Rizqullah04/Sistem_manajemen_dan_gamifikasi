<?php

namespace App\Http\Requests\Ormawa;

use App\Http\Requests\ApiFormRequest;
class UpdateOrmawaRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'nama_ormawa' => ['sometimes', 'string', 'max:255'],
            'deskripsi' => ['nullable', 'string'],
            'total_poin' => ['sometimes', 'integer', 'min:0'],
        ];
    }
}
