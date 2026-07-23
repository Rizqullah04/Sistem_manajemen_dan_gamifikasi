<?php

namespace App\Http\Requests\Kegiatan;

use App\Http\Requests\ApiFormRequest;

class StoreKegiatanRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'id_ormawa' => $this->user()?->role === 'admin'
                ? ['nullable', 'exists:ormawas,id_ormawa']
                : ['required', 'exists:ormawas,id_ormawa'],
            'nama_kegiatan' => ['required', 'string', 'max:150'],
            'deskripsi' => ['required', 'string'],
            'tanggal' => ['required', 'date'],
            'poin_kegiatan' => ['required', 'integer', 'min:0'],
        ];
    }
}
