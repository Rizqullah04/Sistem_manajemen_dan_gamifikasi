<?php

namespace App\Http\Requests\Penilaian;

use App\Http\Requests\ApiFormRequest;

class StorePenilaianRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'kegiatan_id' => ['required', 'exists:kegiatans,id_kegiatan'],
            'nilai_kreativitas' => ['required', 'integer', 'min:0', 'max:100'],
            'nilai_dampak' => ['required', 'integer', 'min:0', 'max:100'],
            'nilai_partisipasi' => ['required', 'integer', 'min:0', 'max:100'],
            'nilai_publikasi' => ['required', 'integer', 'min:0', 'max:100'],
            'komentar' => ['nullable', 'string'],
        ];
    }
}
