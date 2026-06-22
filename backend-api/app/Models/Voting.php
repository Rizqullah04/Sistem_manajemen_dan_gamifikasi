<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Voting extends Model
{
    protected $primaryKey = 'id_voting';

    protected $fillable = [
        'id_kegiatan',
        'id_ormawa',
        'judul_voting',
        'tanggal_mulai',
        'tanggal_selesai',
        'jenis_voting',
        'status',
        'poll_options',
    ];

    protected function casts(): array
    {
        return [
            'tanggal_mulai' => 'datetime',
            'tanggal_selesai' => 'datetime',
            'poll_options' => 'array',
        ];
    }

    public function kegiatan(): BelongsTo
    {
        return $this->belongsTo(Kegiatan::class, 'id_kegiatan', 'id_kegiatan');
    }

    public function ormawa(): BelongsTo
    {
        return $this->belongsTo(Ormawa::class, 'id_ormawa', 'id_ormawa');
    }

    public function voteDetails(): HasMany
    {
        return $this->hasMany(VoteDetail::class, 'id_voting', 'id_voting');
    }
}
