<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Diskusi extends Model
{
    protected $table = 'diskusis';

    protected $primaryKey = 'id_diskusi';

    protected $fillable = [
        'id_kegiatan',
        'id_user',
        'parent_id',
        'komentar',
        'tanggal',
    ];

    protected function casts(): array
    {
        return [
            'tanggal' => 'datetime',
        ];
    }

    public function kegiatan(): BelongsTo
    {
        return $this->belongsTo(Kegiatan::class, 'id_kegiatan', 'id_kegiatan');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'id_user', 'id_user');
    }

    public function parent(): BelongsTo
    {
        return $this->belongsTo(Diskusi::class, 'parent_id', 'id_diskusi');
    }

    public function balasan(): HasMany
    {
        return $this->hasMany(Diskusi::class, 'parent_id', 'id_diskusi');
    }
}
