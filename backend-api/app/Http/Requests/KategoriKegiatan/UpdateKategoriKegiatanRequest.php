<?php

namespace App\Http\Requests\KategoriKegiatan;

use App\Http\Requests\ApiFormRequest;

class UpdateKategoriKegiatanRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'nama_kategori' => ['sometimes', 'string', 'max:100'],
            'deskripsi' => ['nullable', 'string'],
            'poin_dasar' => ['sometimes', 'integer', 'min:0'],
        ];
    }
}
