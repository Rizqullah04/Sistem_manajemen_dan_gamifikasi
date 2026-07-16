<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DislikeKegiatan extends Model
{
    protected $table = 'dislike_kegiatans';
    protected $primaryKey = 'id_dislike';

    protected $fillable = ['id_kegiatan', 'id_user', 'alasan', 'solusi'];

    public function kegiatan(): BelongsTo
    {
        return $this->belongsTo(Kegiatan::class, 'id_kegiatan', 'id_kegiatan');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'id_user', 'id_user');
    }
}
