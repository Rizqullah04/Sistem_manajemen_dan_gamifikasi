<?php

namespace Database\Seeders;

use App\Models\ActivityType;
use Illuminate\Database\Seeder;

class ActivityTypeSeeder extends Seeder
{
    public function run(): void
    {
        $activityTypes = [
            [
                'code' => 'VOTING',
                'name' => 'Voting',
                'frequency_level' => 'high',
                'difficulty_level' => 'easy',
                'organizational_impact' => 'low',
                'point_value' => 2,
            ],
            [
                'code' => 'COMMENT',
                'name' => 'Comment',
                'frequency_level' => 'high',
                'difficulty_level' => 'easy',
                'organizational_impact' => 'low',
                'point_value' => 2,
            ],
            [
                'code' => 'JOIN_EVENT',
                'name' => 'Join Event',
                'frequency_level' => 'medium',
                'difficulty_level' => 'medium',
                'organizational_impact' => 'medium',
                'point_value' => 10,
            ],
            [
                'code' => 'COMMITTEE_MEMBER',
                'name' => 'Committee Member',
                'frequency_level' => 'low',
                'difficulty_level' => 'medium',
                'organizational_impact' => 'high',
                'point_value' => 15,
            ],
            [
                'code' => 'EVENT_LEADER',
                'name' => 'Event Leader',
                'frequency_level' => 'low',
                'difficulty_level' => 'hard',
                'organizational_impact' => 'high',
                'point_value' => 25,
            ],
        ];

        foreach ($activityTypes as $activityType) {
            ActivityType::updateOrCreate(
                ['code' => $activityType['code']],
                $activityType
            );
        }
    }
}