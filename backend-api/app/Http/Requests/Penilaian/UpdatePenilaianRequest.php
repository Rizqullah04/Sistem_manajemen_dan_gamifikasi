<?php

namespace App\Http\Requests\Penilaian;

use App\Http\Requests\ApiFormRequest;

class UpdatePenilaianRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'nilai_kreativitas' => ['sometimes', 'integer', 'min:0', 'max:100'],
            'nilai_dampak' => ['sometimes', 'integer', 'min:0', 'max:100'],
            'nilai_partisipasi' => ['sometimes', 'integer', 'min:0', 'max:100'],
            'nilai_publikasi' => ['sometimes', 'integer', 'min:0', 'max:100'],
            'komentar' => ['nullable', 'string'],
        ];
    }
}
