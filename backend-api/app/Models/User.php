<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    protected $primaryKey = 'id_user';

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'nama',
        'email',
        'password',
        'poin',
        'role',
        'status_akun',
        'id_ormawa',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    public function ormawa(): BelongsTo
    {
        return $this->belongsTo(Ormawa::class, 'id_ormawa', 'id_ormawa');
    }

    public function adminProfile(): HasOne
    {
        return $this->hasOne(AdminProfile::class, 'id_user', 'id_user');
    }

    public function voteDetails(): HasMany
    {
        return $this->hasMany(VoteDetail::class, 'id_user', 'id_user');
    }

    public function verifikasis(): HasMany
    {
        return $this->hasMany(Verifikasi::class, 'id_admin', 'id_user');
    }

    public function diskusis(): HasMany
    {
        return $this->hasMany(Diskusi::class, 'id_user', 'id_user');
    }

    public function likeKegiatans(): HasMany
    {
        return $this->hasMany(LikeKegiatan::class, 'id_user', 'id_user');
    }

    public function chatTerkirim(): HasMany
    {
        return $this->hasMany(Chat::class, 'id_pengirim', 'id_user');
    }

    public function chatDiterima(): HasMany
    {
        return $this->hasMany(Chat::class, 'id_penerima', 'id_user');
    }

    public function poinLogs(): HasMany
    {
        return $this->hasMany(PoinLog::class, 'id_user', 'id_user');
    }

    public function userPoints(): HasMany
    {
        return $this->hasMany(UserPoint::class, 'id_user', 'id_user');
    }

    public function pointHistories(): HasMany
    {
        return $this->hasMany(PointHistory::class, 'id_user', 'id_user');
    }

    public function userBadges(): HasMany
    {
        return $this->hasMany(UserBadge::class, 'id_user', 'id_user');
    }
}
