<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ActivityType extends Model
{
    protected $primaryKey = 'id_activity_type';

    protected $fillable = [
        'code',
        'name',
        'frequency_level',
        'difficulty_level',
        'organizational_impact',
        'point_value',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
        ];
    }

    public function pointHistories(): HasMany
    {
        return $this->hasMany(PointHistory::class, 'id_activity_type', 'id_activity_type');
    }
}