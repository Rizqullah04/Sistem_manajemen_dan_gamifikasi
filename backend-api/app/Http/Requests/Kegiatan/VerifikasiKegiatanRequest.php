<?php

namespace App\Http\Requests\Kegiatan;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class VerifikasiKegiatanRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'status' => ['required', Rule::in(['valid', 'ditolak'])],
            'catatan' => ['nullable', 'string'],
        ];
    }
}
