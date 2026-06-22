<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Ormawa extends Model
{
    protected $primaryKey = 'id_ormawa';

    protected $fillable = [
        'nama_ormawa',
        'deskripsi',
        'total_poin',
    ];

    public function users(): HasMany
    {
        return $this->hasMany(User::class, 'id_ormawa', 'id_ormawa');
    }

    public function kegiatans(): HasMany
    {
        return $this->hasMany(Kegiatan::class, 'id_ormawa', 'id_ormawa');
    }

    public function dokumentasiKegiatans(): HasMany
    {
        return $this->hasMany(DokumentasiKegiatan::class, 'id_ormawa', 'id_ormawa');
    }

    public function votings(): HasMany
    {
        return $this->hasMany(Voting::class, 'id_ormawa', 'id_ormawa');
    }

    public function poinLogs(): HasMany
    {
        return $this->hasMany(PoinLog::class, 'id_ormawa', 'id_ormawa');
    }

    public function organizationPoints(): HasMany
    {
        return $this->hasMany(OrganizationPoint::class, 'id_ormawa', 'id_ormawa');
    }

    public function pointHistories(): HasMany
    {
        return $this->hasMany(PointHistory::class, 'id_ormawa', 'id_ormawa');
    }

    public function recalculateTotalPoin(): void
    {
        $this->forceFill(['total_poin' => $this->calculateTotalPoinFromLogs()])->save();
    }

    public function getTotalPoinAttribute(): int
    {
        if (array_key_exists('total_poin', $this->attributes)) {
            return (int) $this->attributes['total_poin'];
        }

        return $this->calculateTotalPoinFromLogs();
    }

    public function calculateTotalPoinFromLogs(): int
    {
        $activePeriodId = Period::where('status', 'active')->latest('starts_on')->value('id_period');

        $ormawaPoin = (int) $this->poinLogs()
            ->when($activePeriodId, fn ($query, int $periodId) => $query->where('id_period', $periodId))
            ->sum('poin');
        $anggotaPoin = (int) PoinLog::query()
            ->whereNotNull('id_user')
            ->when($activePeriodId, fn ($query, int $periodId) => $query->where('id_period', $periodId))
            ->whereHas('user', fn ($query) => $query->where('id_ormawa', $this->id_ormawa))
            ->sum('poin');

        return $ormawaPoin + $anggotaPoin;
    }
}
