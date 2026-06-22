<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Period extends Model
{
    protected $primaryKey = 'id_period';

    protected $fillable = [
        'year',
        'name',
        'starts_on',
        'ends_on',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'starts_on' => 'date',
            'ends_on' => 'date',
        ];
    }

    public function leaderboards(): HasMany
    {
        return $this->hasMany(Leaderboard::class, 'id_period', 'id_period');
    }

    public function userPoints(): HasMany
    {
        return $this->hasMany(UserPoint::class, 'id_period', 'id_period');
    }

    public function organizationPoints(): HasMany
    {
        return $this->hasMany(OrganizationPoint::class, 'id_period', 'id_period');
    }

    public function pointHistories(): HasMany
    {
        return $this->hasMany(PointHistory::class, 'id_period', 'id_period');
    }

    public function userBadges(): HasMany
    {
        return $this->hasMany(UserBadge::class, 'id_period', 'id_period');
    }
}