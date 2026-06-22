<?php

namespace App\Http\Requests\Kegiatan;

use App\Http\Requests\ApiFormRequest;

class UpdateKegiatanRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'id_ormawa' => ['sometimes', 'exists:ormawas,id_ormawa'],
            'nama_kegiatan' => ['sometimes', 'string', 'max:255'],
            'deskripsi' => ['sometimes', 'string'],
            'tanggal' => ['sometimes', 'date'],
            'poin_kegiatan' => ['sometimes', 'integer', 'min:0'],
        ];
    }
}
