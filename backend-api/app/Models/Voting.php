<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Voting extends Model
{
    protected $primaryKey = 'id_voting';

    protected $fillable = [
        'id_kegiatan',
        'id_ormawa',
        'judul_voting',
        'tanggal_mulai',
        'tanggal_selesai',
        'jenis_voting',
        'calculation_method',
        'voting_scope',
        'status',
        'poll_options',
    ];

    protected function casts(): array
    {
        return [
            'tanggal_mulai' => 'datetime',
            'tanggal_selesai' => 'datetime',
            'poll_options' => 'array',
        ];
    }

    public function kegiatan(): BelongsTo
    {
        return $this->belongsTo(Kegiatan::class, 'id_kegiatan', 'id_kegiatan');
    }

    public function ormawa(): BelongsTo
    {
        return $this->belongsTo(Ormawa::class, 'id_ormawa', 'id_ormawa');
    }

    public function voteDetails(): HasMany
    {
        return $this->hasMany(VoteDetail::class, 'id_voting', 'id_voting');
    }

    public function canBeVotedBy(User $user): bool
    {
        if ($user->role !== 'anggota' || $user->status_akun !== 'aktif') {
            return false;
        }

        if ($this->voting_scope === 'faculty') {
            return true;
        }

        if ($this->id_ormawa === null) {
            return false;
        }

        return (int) $user->id_ormawa === (int) $this->id_ormawa
            || $user->ormawaMemberships()
                ->where('id_ormawa', $this->id_ormawa)
                ->where('status', 'aktif')
                ->exists();
    }

    public function votingEligibilityMessage(User $user): string
    {
        if ($user->role !== 'anggota') {
            return 'Akun admin dan Ormawa bertindak sebagai pengelola voting.';
        }
        if ($user->status_akun !== 'aktif') {
            return 'Hak suara hanya tersedia untuk akun mahasiswa aktif.';
        }
        if ($this->voting_scope === 'organization' && ! $this->canBeVotedBy($user)) {
            return 'Voting internal ini hanya tersedia untuk anggota aktif Ormawa pembuat.';
        }

        return 'Anda memenuhi syarat untuk mengikuti voting ini.';
    }
}
