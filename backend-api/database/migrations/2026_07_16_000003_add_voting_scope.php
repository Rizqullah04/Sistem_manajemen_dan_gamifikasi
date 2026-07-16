<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('votings', function (Blueprint $table) {
            $table->enum('voting_scope', ['faculty', 'organization'])
                ->default('organization')
                ->after('jenis_voting');
            $table->index(['voting_scope', 'id_ormawa']);
        });

        DB::table('votings')->whereNull('id_ormawa')->update([
            'voting_scope' => 'faculty',
        ]);

        $facultyOrmawaIds = DB::table('ormawas')
            ->where('nama_ormawa', 'like', 'BEM%')
            ->orWhere('nama_ormawa', 'like', 'DPM%')
            ->pluck('id_ormawa');
        DB::table('votings')->whereIn('id_ormawa', $facultyOrmawaIds)->update([
            'voting_scope' => 'faculty',
        ]);
    }

    public function down(): void
    {
        Schema::table('votings', function (Blueprint $table) {
            $table->dropIndex(['voting_scope', 'id_ormawa']);
            $table->dropColumn('voting_scope');
        });
    }
};
