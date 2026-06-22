<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AdminProfile extends Model
{
    protected $primaryKey = 'id_admin_profile';

    protected $fillable = [
        'id_user',
        'tipe_admin',
        'nip_nidn',
        'jabatan',
        'unit_kerja',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'id_user', 'id_user');
    }
}
