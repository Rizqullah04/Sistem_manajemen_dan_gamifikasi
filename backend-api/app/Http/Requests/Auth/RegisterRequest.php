<?php

namespace App\Http\Requests\Auth;

use App\Http\Requests\ApiFormRequest;
use App\Models\Ormawa;
use Illuminate\Validation\Validator;

class RegisterRequest extends ApiFormRequest
{
    private const UNWAHAS_CODE = '10';

    private const ENGINEERING_STUDY_PROGRAMS = [
        '3041' => 'Teknik Informatika',
        '3011' => 'Teknik Mesin',
        '3021' => 'Teknik Kimia',
    ];

    public function rules(): array
    {
        return [
            'nama' => ['required', 'string', 'max:100'],
            'nim' => ['required', 'digits:11', 'unique:users,nim'],
            'email' => ['required', 'email', 'max:100', 'unique:users,email'],
            'id_ormawa' => ['required', 'exists:ormawas,id_ormawa'],
            'password' => [
                'required',
                'string',
                'min:8',
                'confirmed',
                'regex:/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$/',
            ],
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $nim = (string) $this->input('nim', '');
            if (! preg_match('/^\d{11}$/', $nim)) {
                return;
            }

            $studyProgramCode = substr($nim, 4, 4);
            if ((int) substr($nim, 0, 2) > (int) now()->format('y')) {
                $validator->errors()->add('nim', 'Tahun angkatan NIM tidak valid');
                return;
            }

            if (substr($nim, 2, 2) !== self::UNWAHAS_CODE) {
                $validator->errors()->add('nim', 'Kode universitas NIM bukan Universitas Wahid Hasyim');
                return;
            }

            if (! array_key_exists($studyProgramCode, self::ENGINEERING_STUDY_PROGRAMS)) {
                $validator->errors()->add('nim', 'Kode prodi NIM bukan prodi Fakultas Teknik');
                return;
            }

            if (substr($nim, 8, 3) === '000') {
                $validator->errors()->add('nim', 'Nomor urut NIM tidak valid');
                return;
            }

            $ormawa = Ormawa::find($this->input('id_ormawa'));
            if ($ormawa === null) {
                return;
            }

            if ($this->isBemOrmawa($ormawa)) {
                $validator->errors()->add('id_ormawa', 'BEM tidak tersedia pada registrasi. Pendaftaran awal harus melalui himpunan prodi.');
                return;
            }

            $allowedStudyProgramCodes = $this->allowedStudyProgramCodesForOrmawa($ormawa);
            if (
                $allowedStudyProgramCodes !== [] &&
                ! in_array($studyProgramCode, $allowedStudyProgramCodes, true)
            ) {
                $validator->errors()->add('id_ormawa', 'Ormawa tidak sesuai dengan prodi pada NIM');
            }
        });
    }

    public function messages(): array
    {
        return [
            'nama.required' => 'Nama lengkap wajib diisi',
            'nama.max' => 'Nama maksimal 100 karakter',
            'nim.required' => 'NIM wajib diisi',
            'nim.digits' => 'NIM harus terdiri dari 11 digit angka',
            'nim.unique' => 'NIM sudah digunakan',
            'email.required' => 'Email wajib diisi',
            'email.email' => 'Format email tidak valid',
            'email.unique' => 'Email sudah digunakan',
            'id_ormawa.required' => 'Ormawa wajib dipilih',
            'id_ormawa.exists' => 'Ormawa tidak valid',
            'password.required' => 'Password wajib diisi',
            'password.min' => 'Password minimal 8 karakter',
            'password.confirmed' => 'Konfirmasi password harus sama',
            'password.regex' => 'Password harus mengandung huruf besar, huruf kecil, dan angka',
        ];
    }

    /**
     * Empty list means the Ormawa has no explicit prodi restriction.
     *
     * @return list<string>
     */
    private function allowedStudyProgramCodesForOrmawa(Ormawa $ormawa): array
    {
        $text = strtolower($ormawa->nama_ormawa.' '.$ormawa->deskripsi);

        if (str_contains($text, 'informatika') || str_contains($text, 'hmjti')) {
            return ['3041'];
        }

        if (str_contains($text, 'mesin') || str_contains($text, 'hmtm')) {
            return ['3011'];
        }

        if (str_contains($text, 'kimia') || str_contains($text, 'hmjtk')) {
            return ['3021'];
        }

        return [];
    }

    private function isBemOrmawa(Ormawa $ormawa): bool
    {
        return str_contains(strtolower($ormawa->nama_ormawa.' '.$ormawa->deskripsi), 'bem');
    }
}
