<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PointHistory extends Model
{
    protected $primaryKey = 'id_point_history';

    protected $fillable = [
        'id_period',
        'id_activity_type',
        'recipient_type',
        'id_user',
        'id_ormawa',
        'source_model',
        'source_id',
        'points_awarded',
        'notes',
        'occurred_at',
    ];

    protected function casts(): array
    {
        return [
            'occurred_at' => 'datetime',
        ];
    }

    public function period(): BelongsTo
    {
        return $this->belongsTo(Period::class, 'id_period', 'id_period');
    }

    public function activityType(): BelongsTo
    {
        return $this->belongsTo(ActivityType::class, 'id_activity_type', 'id_activity_type');
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