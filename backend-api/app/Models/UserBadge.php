<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserBadge extends Model
{
    protected $primaryKey = 'id_user_badge';

    protected $fillable = [
        'id_user',
        'id_badge',
        'id_period',
        'awarded_at',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'awarded_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'id_user', 'id_user');
    }

    public function badge(): BelongsTo
    {
        return $this->belongsTo(Badge::class, 'id_badge');
    }

    public function period(): BelongsTo
    {
        return $this->belongsTo(Period::class, 'id_period', 'id_period');
    }
}