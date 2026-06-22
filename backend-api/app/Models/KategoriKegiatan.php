<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class KategoriKegiatan extends Model
{
    protected $fillable = [
        'nama_kategori',
        'deskripsi',
        'poin_dasar',
    ];

    public function kegiatans(): HasMany
    {
        return $this->hasMany(Kegiatan::class, 'kategori_id');
    }
}
