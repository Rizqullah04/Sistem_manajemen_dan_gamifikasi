<?php

namespace App\Http\Requests\Ormawa;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class UpdateOrmawaRequest extends ApiFormRequest
{
    public function rules(): array
    {
        $ormawaId = $this->route('ormawa')?->getKey();

        return [
            'nama_ormawa' => [
                'sometimes',
                'string',
                'max:150',
                Rule::unique('ormawas', 'nama_ormawa')->ignore($ormawaId, 'id_ormawa'),
            ],
            'deskripsi' => ['nullable', 'string'],
            'total_poin' => ['sometimes', 'integer', 'min:0'],
            'account_name' => ['nullable', 'string', 'max:100'],
        ];
    }
}
