<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LeaderboardDetail extends Model
{
    protected $primaryKey = 'id_detail';

    protected $fillable = [
        'id_leaderboard',
        'id_user',
        'id_ormawa',
        'poin',
        'ranking',
    ];

    public function leaderboard(): BelongsTo
    {
        return $this->belongsTo(Leaderboard::class, 'id_leaderboard', 'id_leaderboard');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'id_user', 'id_user');
    }

    public function ormawa(): BelongsTo
    {
        return $this->belongsTo(Ormawa::class, 'id_ormawa', 'id_ormawa');
    }
}
