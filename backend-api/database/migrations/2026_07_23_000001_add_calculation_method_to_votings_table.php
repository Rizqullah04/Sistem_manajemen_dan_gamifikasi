<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('votings', function (Blueprint $table) {
            $table->string('calculation_method', 30)
                ->default('raw')
                ->after('jenis_voting');
        });
    }

    public function down(): void
    {
        Schema::table('votings', function (Blueprint $table) {
            $table->dropColumn('calculation_method');
        });
    }
};
