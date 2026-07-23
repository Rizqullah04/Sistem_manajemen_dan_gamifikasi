<?php

namespace Tests\Unit;

use App\Http\Resources\VotingResource;
use App\Models\User;
use App\Models\VoteDetail;
use App\Models\Voting;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Tests\TestCase;

class VotingResourceTest extends TestCase
{
    public function test_it_gives_each_engineering_study_program_equal_weight(): void
    {
        $voting = new Voting([
            'calculation_method' => 'study_program_weighted',
            'poll_options' => ['HMJTI', 'HMTM'],
        ]);
        $voting->setRelation('voteDetails', new Collection([
            $this->vote('HMJTI', '22103041001'),
            $this->vote('HMJTI', '22103041002'),
            $this->vote('HMTM', '22103041003'),
            $this->vote('HMTM', '22103011001'),
            $this->vote('HMJTI', '22103021001'),
            $this->vote('HMTM', '22103021002'),
        ]));

        $data = (new VotingResource($voting))->resolve(new Request());

        $this->assertSame(38.89, $data['weighted_results']['HMJTI']);
        $this->assertSame(61.11, $data['weighted_results']['HMTM']);
    }

    private function vote(string $choice, string $nim): VoteDetail
    {
        $vote = new VoteDetail(['pilihan' => $choice]);
        $vote->setRelation('user', new User(['nim' => $nim]));

        return $vote;
    }
}
