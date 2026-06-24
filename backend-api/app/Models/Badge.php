<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Badge extends Model
{
    protected $fillable = [
        'nama_badge',
        'deskripsi',
        'activity_type',
        'minimal_poin',
        'icon',
    ];

    public function ormawas(): BelongsToMany
    {
        return $this->belongsToMany(Ormawa::class, 'ormawa_badges')
            ->withPivot('tanggal_diperoleh');
    }

    public function userBadges(): HasMany
    {
        return $this->hasMany(UserBadge::class, 'id_badge');
    }
}
