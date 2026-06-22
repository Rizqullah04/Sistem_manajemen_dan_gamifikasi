<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Chat extends Model
{
    protected $primaryKey = 'id_chat';

    protected $fillable = [
        'id_pengirim',
        'id_penerima',
        'pesan',
        'status_baca',
        'tanggal',
    ];

    protected function casts(): array
    {
        return [
            'tanggal' => 'datetime',
        ];
    }

    public function pengirim(): BelongsTo
    {
        return $this->belongsTo(User::class, 'id_pengirim', 'id_user');
    }

    public function penerima(): BelongsTo
    {
        return $this->belongsTo(User::class, 'id_penerima', 'id_user');
    }
}
