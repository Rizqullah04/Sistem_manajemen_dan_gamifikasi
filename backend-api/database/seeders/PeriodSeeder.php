<?php

namespace Database\Seeders;

use App\Models\Period;
use Illuminate\Database\Seeder;

class PeriodSeeder extends Seeder
{
    public function run(): void
    {
        $periods = [
            [
                'year' => 2026,
                'name' => '2026',
                'starts_on' => '2026-01-01',
                'ends_on' => '2026-12-31',
                'status' => 'active',
            ],
            [
                'year' => 2027,
                'name' => '2027',
                'starts_on' => '2027-01-01',
                'ends_on' => '2027-12-31',
                'status' => 'archived',
            ],
            [
                'year' => 2028,
                'name' => '2028',
                'starts_on' => '2028-01-01',
                'ends_on' => '2028-12-31',
                'status' => 'archived',
            ],
        ];

        foreach ($periods as $period) {
            Period::updateOrCreate(
                ['year' => $period['year']],
                $period
            );
        }
    }
}