<?php

namespace App\Http\Requests\Ormawa;

use App\Http\Requests\ApiFormRequest;

class StoreOrmawaRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'nama_ormawa' => ['required', 'string', 'max:150', 'unique:ormawas,nama_ormawa'],
            'deskripsi' => ['nullable', 'string'],
            'total_poin' => ['sometimes', 'integer', 'min:0'],
            'account_name' => ['nullable', 'string', 'max:100'],
            'account_email' => ['nullable', 'required_with:account_password', 'email', 'max:100', 'unique:users,email'],
            'account_password' => [
                'nullable',
                'required_with:account_email',
                'string',
                'min:8',
                'confirmed',
                'regex:/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$/',
            ],
        ];
    }
}
