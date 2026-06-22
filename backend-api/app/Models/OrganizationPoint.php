<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OrganizationPoint extends Model
{
    protected $primaryKey = 'id_organization_point';

    protected $fillable = [
        'id_period',
        'id_ormawa',
        'total_event_points',
        'member_points',
        'rank_position',
        'calculated_at',
    ];

    protected function casts(): array
    {
        return [
            'calculated_at' => 'datetime',
        ];
    }

    public function period(): BelongsTo
    {
        return $this->belongsTo(Period::class, 'id_period', 'id_period');
    }

    public function ormawa(): BelongsTo
    {
        return $this->belongsTo(Ormawa::class, 'id_ormawa', 'id_ormawa');
    }
}