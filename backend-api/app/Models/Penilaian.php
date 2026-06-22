<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Penilaian extends Model
{
    protected $fillable = [
        'kegiatan_id',
        'juri_id',
        'nilai_kreativitas',
        'nilai_dampak',
        'nilai_partisipasi',
        'nilai_publikasi',
        'total_nilai',
        'komentar',
    ];

    public function kegiatan(): BelongsTo
    {
        return $this->belongsTo(Kegiatan::class);
    }

    public function juri(): BelongsTo
    {
        return $this->belongsTo(User::class, 'juri_id');
    }
}
