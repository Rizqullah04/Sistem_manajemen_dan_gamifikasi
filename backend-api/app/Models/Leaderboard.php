<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Leaderboard extends Model
{
    protected $primaryKey = 'id_leaderboard';

    protected $fillable = [
        'tipe',
        'id_period',
        'periode',
        'tanggal_generate',
    ];

    protected function casts(): array
    {
        return [
            'tanggal_generate' => 'datetime',
        ];
    }

    public function period(): BelongsTo
    {
        return $this->belongsTo(Period::class, 'id_period', 'id_period');
    }

    public function details(): HasMany
    {
        return $this->hasMany(LeaderboardDetail::class, 'id_leaderboard', 'id_leaderboard');
    }
}
