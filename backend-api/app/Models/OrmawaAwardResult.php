<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OrmawaAwardResult extends Model
{
    protected $primaryKey = 'id_ormawa_award_result';

    protected $fillable = [
        'id_period',
        'id_ormawa',
        'periode',
        'starts_on',
        'ends_on',
        'criteria_weights',
        'metrics',
        'total_score',
        'ranking',
        'calculated_at',
    ];

    protected function casts(): array
    {
        return [
            'starts_on' => 'date',
            'ends_on' => 'date',
            'criteria_weights' => 'array',
            'metrics' => 'array',
            'total_score' => 'decimal:2',
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
