<?php

namespace App\Http\Requests\KategoriKegiatan;

use App\Http\Requests\ApiFormRequest;

class StoreKategoriKegiatanRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'nama_kategori' => ['required', 'string', 'max:100'],
            'deskripsi' => ['nullable', 'string'],
            'poin_dasar' => ['required', 'integer', 'min:0'],
        ];
    }
}
