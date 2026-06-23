<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ormawa_award_results', function (Blueprint $table) {
            $table->id('id_ormawa_award_result');
            $table->foreignId('id_period')->nullable()->constrained('periods', 'id_period')->nullOnDelete();
            $table->foreignId('id_ormawa')->constrained('ormawas', 'id_ormawa')->cascadeOnDelete();
            $table->string('periode');
            $table->date('starts_on');
            $table->date('ends_on');
            $table->json('criteria_weights');
            $table->json('metrics');
            $table->decimal('total_score', 8, 2)->default(0);
            $table->unsignedInteger('ranking')->default(0);
            $table->timestamp('calculated_at')->nullable();
            $table->timestamps();

            $table->unique(['periode', 'id_ormawa'], 'ormawa_awards_period_ormawa_unique');
            $table->index(['periode', 'ranking']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ormawa_award_results');
    }
};
