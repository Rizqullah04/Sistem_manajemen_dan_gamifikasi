<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class VoteDetail extends Model
{
    protected $primaryKey = 'id_vote';

    protected $fillable = [
        'id_voting',
        'id_user',
        'pilihan',
        'tanggal_vote',
    ];

    protected function casts(): array
    {
        return [
            'tanggal_vote' => 'datetime',
        ];
    }

    public function voting(): BelongsTo
    {
        return $this->belongsTo(Voting::class, 'id_voting', 'id_voting');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'id_user', 'id_user');
    }
}
