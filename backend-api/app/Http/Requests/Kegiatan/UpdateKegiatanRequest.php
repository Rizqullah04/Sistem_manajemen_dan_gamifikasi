<?php

namespace App\Http\Requests\Kegiatan;

use App\Http\Requests\ApiFormRequest;

class UpdateKegiatanRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'id_ormawa' => ['sometimes', 'exists:ormawas,id_ormawa'],
            'kategori_id' => ['sometimes', 'nullable', 'exists:kategori_kegiatans,id'],
            'nama_kegiatan' => ['sometimes', 'string', 'max:150'],
            'deskripsi' => ['sometimes', 'string'],
            'tanggal' => ['sometimes', 'date'],
            'poin_kegiatan' => ['sometimes', 'integer', 'min:0'],
        ];
    }
}
