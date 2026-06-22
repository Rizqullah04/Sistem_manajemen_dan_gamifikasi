<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OrmawaBadge extends Model
{
    protected $table = 'ormawa_badges';

    protected $fillable = [
        'ormawa_id',
        'badge_id',
        'tanggal_diperoleh',
    ];

    protected function casts(): array
    {
        return [
            'tanggal_diperoleh' => 'date',
        ];
    }

    public function ormawa(): BelongsTo
    {
        return $this->belongsTo(Ormawa::class);
    }

    public function badge(): BelongsTo
    {
        return $this->belongsTo(Badge::class);
    }
}
