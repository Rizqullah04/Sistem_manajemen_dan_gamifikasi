<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserOrmawaMembership extends Model
{
    protected $fillable = [
        'id_user',
        'id_ormawa',
        'status',
        'position',
        'division',
        'id_period',
        'starts_at',
        'ends_at',
        'appointed_by',
    ];

    protected function casts(): array
    {
        return [
            'starts_at' => 'date',
            'ends_at' => 'date',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'id_user', 'id_user');
    }

    public function ormawa(): BelongsTo
    {
        return $this->belongsTo(Ormawa::class, 'id_ormawa', 'id_ormawa');
    }

    public function appointer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'appointed_by', 'id_user');
    }

    public function period(): BelongsTo
    {
        return $this->belongsTo(Period::class, 'id_period', 'id_period');
    }
}
