<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class VotingResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $user = $request->user();
        return [
            'id_voting' => $this->id_voting,
            'id_kegiatan' => $this->id_kegiatan,
            'id_ormawa' => $this->id_ormawa,
            'creator_name' => $this->ormawa?->nama_ormawa ?? 'Ormawa Pembuat',
            'ormawa' => $this->whenLoaded('ormawa', fn () => new OrmawaResource($this->ormawa)),
            'judul_voting' => $this->judul_voting,
            'tanggal_mulai' => $this->tanggal_mulai?->format('Y-m-d'),
            'tanggal_selesai' => $this->tanggal_selesai?->format('Y-m-d'),
            'jenis_voting' => $this->jenis_voting,
            'calculation_method' => $this->calculation_method ?? 'raw',
            'weighted_results' => $this->when(
                ($this->calculation_method ?? 'raw') === 'study_program_weighted',
                fn () => $this->weightedResults()
            ),
            'voting_scope' => $this->voting_scope,
            'can_vote' => $user !== null && $this->canBeVotedBy($user),
            'eligibility_message' => $user !== null
                ? $this->votingEligibilityMessage($user)
                : 'Silakan masuk untuk menggunakan hak suara.',
            'status' => $this->status,
            'poll_options' => $this->poll_options,
            'vote_details' => $this->whenLoaded('voteDetails', fn () => VoteDetailResource::collection($this->voteDetails)),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }

    /**
     * Setiap prodi Teknik memiliki bobot yang sama, terlepas dari jumlah pemilihnya.
     *
     * @return array<string, float>
     */
    private function weightedResults(): array
    {
        $studyProgramCodes = ['3041', '3011', '3021'];
        $options = is_array($this->poll_options) ? $this->poll_options : [];
        $scores = array_fill_keys($options, 0.0);
        $votes = $this->relationLoaded('voteDetails') ? $this->voteDetails : collect();

        foreach ($studyProgramCodes as $studyProgramCode) {
            $programVotes = $votes->filter(function ($vote) use ($studyProgramCode): bool {
                $nim = (string) ($vote->user?->nim ?? '');

                return strlen($nim) === 11 && substr($nim, 4, 4) === $studyProgramCode;
            });
            $programTotal = $programVotes->count();
            if ($programTotal === 0) {
                continue;
            }

            foreach ($options as $option) {
                $scores[$option] += $programVotes->where('pilihan', $option)->count()
                    / $programTotal
                    / count($studyProgramCodes)
                    * 100;
            }
        }

        return collect($scores)
            ->map(fn (float $score): float => round($score, 2))
            ->all();
    }
}
