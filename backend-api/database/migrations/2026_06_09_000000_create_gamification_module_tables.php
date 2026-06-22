<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('periods')) {
            Schema::create('periods', function (Blueprint $table) {
                $table->id('id_period');
                $table->unsignedSmallInteger('year')->unique();
                $table->string('name')->unique();
                $table->date('starts_on')->nullable();
                $table->date('ends_on')->nullable();
                $table->enum('status', ['active', 'archived'])->default('active');
                $table->timestamps();

                $table->index(['status', 'year']);
            });
        }

        if (! Schema::hasTable('activity_types')) {
            Schema::create('activity_types', function (Blueprint $table) {
                $table->id('id_activity_type');
                $table->string('code')->unique();
                $table->string('name')->unique();
                $table->enum('frequency_level', ['low', 'medium', 'high']);
                $table->enum('difficulty_level', ['easy', 'medium', 'hard']);
                $table->enum('organizational_impact', ['low', 'medium', 'high']);
                $table->unsignedInteger('point_value');
                $table->boolean('is_active')->default(true);
                $table->timestamps();

                $table->index(['is_active', 'point_value']);
            });
        }

        if (! Schema::hasTable('user_points')) {
            Schema::create('user_points', function (Blueprint $table) {
                $table->id('id_user_point');
                $table->foreignId('id_period')->constrained('periods', 'id_period')->cascadeOnDelete();
                $table->foreignId('id_user')->constrained('users', 'id_user')->cascadeOnDelete();
                $table->unsignedInteger('total_points')->default(0);
                $table->unsignedInteger('rank_position')->nullable();
                $table->timestamp('calculated_at')->nullable();
                $table->timestamps();

                $table->unique(['id_period', 'id_user']);
                $table->index(['id_period', 'total_points']);
            });
        }

        if (! Schema::hasTable('organization_points')) {
            Schema::create('organization_points', function (Blueprint $table) {
                $table->id('id_organization_point');
                $table->foreignId('id_period')->constrained('periods', 'id_period')->cascadeOnDelete();
                $table->foreignId('id_ormawa')->constrained('ormawas', 'id_ormawa')->cascadeOnDelete();
                $table->unsignedInteger('total_event_points')->default(0);
                $table->unsignedInteger('member_points')->default(0);
                $table->unsignedInteger('total_points')->storedAs('total_event_points + member_points');
                $table->unsignedInteger('rank_position')->nullable();
                $table->timestamp('calculated_at')->nullable();
                $table->timestamps();

                $table->unique(['id_period', 'id_ormawa']);
                $table->index(['id_period', 'total_points']);
            });
        }

        if (! Schema::hasTable('point_histories')) {
            Schema::create('point_histories', function (Blueprint $table) {
                $table->id('id_point_history');
                $table->foreignId('id_period')->constrained('periods', 'id_period')->cascadeOnDelete();
                $table->foreignId('id_activity_type')->constrained('activity_types', 'id_activity_type')->restrictOnDelete();
                $table->enum('recipient_type', ['user', 'organization']);
                $table->foreignId('id_user')->nullable()->constrained('users', 'id_user')->cascadeOnDelete();
                $table->foreignId('id_ormawa')->nullable()->constrained('ormawas', 'id_ormawa')->cascadeOnDelete();
                $table->string('source_model')->nullable();
                $table->unsignedBigInteger('source_id')->nullable();
                $table->unsignedInteger('points_awarded');
                $table->text('notes')->nullable();
                $table->dateTime('occurred_at');
                $table->timestamps();

                $table->index(['id_period', 'recipient_type']);
                $table->index(['id_activity_type', 'occurred_at']);
                $table->index(['id_user', 'id_ormawa']);
            });

            if (DB::getDriverName() !== 'sqlite') {
                DB::statement(
                    'ALTER TABLE point_histories ADD CONSTRAINT point_histories_target_check '
                    .'CHECK ((recipient_type = "user" AND id_user IS NOT NULL AND id_ormawa IS NULL) '
                    .'OR (recipient_type = "organization" AND id_ormawa IS NOT NULL AND id_user IS NULL))'
                );
            }
        }

        if (! Schema::hasTable('user_badges')) {
            Schema::create('user_badges', function (Blueprint $table) {
                $table->id('id_user_badge');
                $table->foreignId('id_user')->constrained('users', 'id_user')->cascadeOnDelete();
                $table->foreignId('id_badge')->constrained('badges')->cascadeOnDelete();
                $table->foreignId('id_period')->nullable()->constrained('periods', 'id_period')->nullOnDelete();
                $table->dateTime('awarded_at');
                $table->text('notes')->nullable();
                $table->timestamps();

                $table->unique(['id_user', 'id_badge']);
                $table->index(['id_period', 'awarded_at']);
            });
        }

        Schema::table('leaderboards', function (Blueprint $table) {
            if (! Schema::hasColumn('leaderboards', 'id_period')) {
                $table->foreignId('id_period')
                    ->nullable()
                    ->after('tipe')
                    ->constrained('periods', 'id_period')
                    ->nullOnDelete();
            }

            if (! Schema::hasColumn('leaderboards', 'tanggal_generate')) {
                $table->dateTime('tanggal_generate')->nullable()->after('periode');
            }

            $table->unique(['id_period', 'tipe'], 'leaderboards_period_type_unique');
            $table->index(['id_period', 'tipe', 'tanggal_generate'], 'leaderboards_period_type_index');
        });
    }

    public function down(): void
    {
        Schema::table('leaderboards', function (Blueprint $table) {
            $table->dropUnique('leaderboards_period_type_unique');
            $table->dropIndex('leaderboards_period_type_index');

            if (Schema::hasColumn('leaderboards', 'id_period')) {
                $table->dropConstrainedForeignId('id_period');
            }
        });

        Schema::dropIfExists('user_badges');
        Schema::dropIfExists('point_histories');
        Schema::dropIfExists('organization_points');
        Schema::dropIfExists('user_points');
        Schema::dropIfExists('activity_types');
        Schema::dropIfExists('periods');
    }
};