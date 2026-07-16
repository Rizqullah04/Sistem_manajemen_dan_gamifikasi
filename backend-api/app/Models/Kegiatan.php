<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Kegiatan extends Model
{
    public const STATUS_PENDING = 'pending';

    public const STATUS_VALID = 'valid';

    public const STATUS_DITOLAK = 'ditolak';

    protected $primaryKey = 'id_kegiatan';

    protected $fillable = [
        'id_ormawa',
        'kategori_id',
        'nama_kegiatan',
        'deskripsi',
        'tanggal',
        'poin_kegiatan',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'tanggal' => 'date',
        ];
    }

    public function ormawa(): BelongsTo
    {
        return $this->belongsTo(Ormawa::class, 'id_ormawa', 'id_ormawa');
    }

    public function kategori(): BelongsTo
    {
        return $this->belongsTo(KategoriKegiatan::class, 'kategori_id');
    }

    public function votings(): HasMany
    {
        return $this->hasMany(Voting::class, 'id_kegiatan', 'id_kegiatan');
    }

    public function dokumentasiKegiatans(): HasMany
    {
        return $this->hasMany(DokumentasiKegiatan::class, 'id_kegiatan', 'id_kegiatan');
    }

    public function verifikasis(): HasMany
    {
        return $this->hasMany(Verifikasi::class, 'id_kegiatan', 'id_kegiatan');
    }

    public function diskusis(): HasMany
    {
        return $this->hasMany(Diskusi::class, 'id_kegiatan', 'id_kegiatan');
    }

    public function likeKegiatans(): HasMany
    {
        return $this->hasMany(LikeKegiatan::class, 'id_kegiatan', 'id_kegiatan');
    }

    public function dislikeKegiatans(): HasMany
    {
        return $this->hasMany(DislikeKegiatan::class, 'id_kegiatan', 'id_kegiatan');
    }
}
