<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ActivityTypeController;
use App\Http\Controllers\Api\BadgeController;
use App\Http\Controllers\Api\ChatController;
use App\Http\Controllers\Api\DiskusiController;
use App\Http\Controllers\Api\DislikeKegiatanController;
use App\Http\Controllers\Api\DokumentasiKegiatanController;
use App\Http\Controllers\Api\KegiatanController;
use App\Http\Controllers\Api\KategoriKegiatanController;
use App\Http\Controllers\Api\LeaderboardController;
use App\Http\Controllers\Api\LikeKegiatanController;
use App\Http\Controllers\Api\OrmawaController;
use App\Http\Controllers\Api\OrmawaAwardController;
use App\Http\Controllers\Api\PeriodController;
use App\Http\Controllers\Api\PoinLogController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\VoteDetailController;
use App\Http\Controllers\Api\VotingController;
use Illuminate\Support\Facades\Route;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
Route::post('/verify-reset-otp', [AuthController::class, 'verifyResetOtp']);
Route::post('/reset-password', [AuthController::class, 'resetPassword']);
Route::apiResource('ormawas', OrmawaController::class)->only(['index', 'show']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/profile', [AuthController::class, 'profile']);
    Route::patch('/profile', [AuthController::class, 'updateProfile']);
    Route::get('/profile/gamification', [AuthController::class, 'gamificationProfile']);

    Route::get('/leaderboard', [LeaderboardController::class, 'index']);

    Route::apiResource('kegiatans', KegiatanController::class)->only(['index', 'show']);
    Route::apiResource('kategori-kegiatans', KategoriKegiatanController::class)->only(['index', 'show']);
    Route::apiResource('votings', VotingController::class)->only(['index', 'show']);
    Route::apiResource('diskusis', DiskusiController::class)->only(['index', 'store', 'destroy']);
    Route::apiResource('dokumentasi-kegiatans', DokumentasiKegiatanController::class)->only(['index', 'store']);
    Route::apiResource('chats', ChatController::class)->only(['index', 'store', 'update']);
    Route::post('/like-kegiatans', [LikeKegiatanController::class, 'store']);
    Route::delete('/kegiatans/{kegiatan}/like', [LikeKegiatanController::class, 'destroyForActivity']);
    Route::post('/dislike-kegiatans', [DislikeKegiatanController::class, 'store']);
    Route::delete('/kegiatans/{kegiatan}/dislike', [DislikeKegiatanController::class, 'destroy']);
    Route::get('/kegiatans/{kegiatan}/feedback', [DislikeKegiatanController::class, 'index']);
    Route::delete('/like-kegiatans/{likeKegiatan}', [LikeKegiatanController::class, 'destroy']);
    Route::post('/vote-details', [VoteDetailController::class, 'store'])->middleware('role:anggota');

    Route::middleware('role:admin')->group(function () {
        Route::apiResource('users', UserController::class)->only(['index', 'update']);
        Route::patch('/users/{user}/recalculate-poin', [UserController::class, 'recalculatePoin']);
        Route::get('/admin/ormawas', [OrmawaController::class, 'adminIndex']);
        Route::apiResource('ormawas', OrmawaController::class)->except(['index', 'show']);
        Route::get('/periods/current', [PeriodController::class, 'current']);
        Route::post('/periods/end-current', [PeriodController::class, 'endCurrent']);
        Route::post('/ormawa-awards/preview', [OrmawaAwardController::class, 'preview']);
        Route::post('/ormawa-awards/generate', [OrmawaAwardController::class, 'generate']);
        Route::get('/ormawa-awards/history', [OrmawaAwardController::class, 'history']);
        Route::delete('/ormawa-awards/history/{result}', [OrmawaAwardController::class, 'destroyHistory']);
        Route::apiResource('badges', BadgeController::class);
        Route::apiResource('activity-types', ActivityTypeController::class);
        Route::apiResource('kategori-kegiatans', KategoriKegiatanController::class)->except(['index', 'show']);
        Route::get('/poin-logs', [PoinLogController::class, 'index']);
        Route::patch('/ormawas/{ormawa}/recalculate-poin', [PoinLogController::class, 'recalculateOrmawa']);
        Route::patch('/kegiatans/{kegiatan}/verifikasi', [KegiatanController::class, 'verifikasi']);
        Route::delete('/votings/completed-logs', [VotingController::class, 'clearCompletedLogs']);
    });

    Route::middleware('role:admin,ormawa')->group(function () {
        Route::apiResource('kegiatans', KegiatanController::class)->except(['index', 'show']);
        Route::apiResource('votings', VotingController::class)->except(['index', 'show']);
        Route::get('/bem/members', [UserController::class, 'bemMembers']);
        Route::post('/bem/members', [UserController::class, 'appointBemMember']);
        Route::delete('/bem/members/{user}', [UserController::class, 'removeBemMember']);
    });

    Route::middleware('role:ormawa')->group(function () {
        Route::get('/ormawa/members', [UserController::class, 'ormawaMembers']);
        Route::patch('/ormawa/members/{user}', [UserController::class, 'updateOrmawaMember']);
    });
});
