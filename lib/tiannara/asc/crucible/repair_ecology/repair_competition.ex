defmodule Tiannara.ASC.Crucible.RepairEcology.RepairCompetition do
  @moduledoc """
  Repair Competition — when multiple repair patterns address the same failure class,
  they compete and only the fittest survive.

  Responsibilities:
  - Detect competing repairs for same failure signature
  - Calculate fitness scores based on success rate, stability, reuse, regression
  - Determine winners and losers
  - Track competition events for law discovery

  ## Fitness Formula

  ```
  fitness =
    success_rate * 0.4 +
    stability * 0.3 +
    reuse_rate * 0.2 +
    (1 - regression_rate) * 0.1
  ```

  ## Success Criteria

  - competition_events ≥ 100
  - winner_stability > 80%
  - fitness_improvement_rate > 10%

  ## Example

      iex> competition = RepairCompetition.run([pattern_a, pattern_b, pattern_c])
      iex> competition.winner_id
      "pattern_xxx"

  """

  alias Tiannara.ASC.Crucible.RepairPattern

  @derive Jason.Encoder
  defstruct [
    # Competition Identity
    competition_id: nil,
    failure_signature: nil,
    generation: 0,

    # Participants
    participants: [],          # List of competing pattern IDs
    participant_count: 0,

    # Results
    winner_id: nil,
    winner_fitness: 0.0,
    rankings: [],              # [{pattern_id, fitness}] sorted descending

    # Metrics
    avg_fitness_before: 0.0,
    avg_fitness_after: 0.0,
    fitness_improvement: 0.0,

    # Temporal
    created_at: nil
  ]

  @typedoc "Repair competition structure"
  @type t :: %__MODULE__{
          competition_id: String.t() | nil,
          failure_signature: String.t() | nil,
          generation: non_neg_integer(),
          participants: [String.t()],
          participant_count: non_neg_integer(),
          winner_id: String.t() | nil,
          winner_fitness: float(),
          rankings: [{String.t(), float()}],
          avg_fitness_before: float(),
          avg_fitness_after: float(),
          fitness_improvement: float(),
          created_at: DateTime.t() | nil
        }

  @doc """
  Run a competition between multiple repair patterns addressing the same failure.

  ## Parameters

  - `patterns` — List of RepairPattern structs competing
  - `failure_signature` — The failure signature they all address
  - `generation` — Current generation number

  ## Returns

  - Competition result with winner and rankings
  """
  def run(patterns, failure_signature, generation) when length(patterns) >= 2 do
    now = DateTime.utc_now()

    # Calculate fitness for each pattern
    scored_patterns =
      Enum.map(patterns, fn pattern ->
        fitness = calculate_fitness(pattern)
        {pattern.id, fitness}
      end)

    # Sort by fitness descending
    ranked = Enum.sort_by(scored_patterns, fn {_id, fitness} -> -fitness end)

    # Get winner
    {winner_id, winner_fitness} = hd(ranked)

    # Calculate average fitness before competition (baseline)
    avg_before = Enum.sum_by(patterns, & &1.repair_fitness) / length(patterns)

    # Calculate average fitness after (winner's fitness represents post-competition state)
    avg_after = winner_fitness

    # Calculate improvement
    improvement = if avg_before > 0 do
      (avg_after - avg_before) / avg_before
    else
      0.0
    end

    %__MODULE__{
      competition_id: generate_competition_id(failure_signature),
      failure_signature: failure_signature,
      generation: generation,
      participants: Enum.map(patterns, & &1.id),
      participant_count: length(patterns),
      winner_id: winner_id,
      winner_fitness: Float.round(winner_fitness, 3),
      rankings: ranked,
      avg_fitness_before: Float.round(avg_before, 3),
      avg_fitness_after: Float.round(avg_after, 3),
      fitness_improvement: Float.round(improvement, 3),
      created_at: now
    }
  end

  def run(_patterns, _failure_signature, _generation) do
    # Not enough participants for competition
    nil
  end

  @doc """
  Calculate fitness score for a repair pattern.

  Formula:
  ```
  fitness =
    success_rate * 0.4 +
    stability * 0.3 +
    reuse_rate_normalized * 0.2 +
    (1 - regression_rate) * 0.1
  ```

  ## Parameters

  - `pattern` — RepairPattern to evaluate

  ## Returns

  - Fitness score (0.0-1.0)
  """
  def calculate_fitness(%RepairPattern{} = pattern) do
    success_weight = 0.4
    stability_weight = 0.3
    reuse_weight = 0.2
    low_regression_weight = 0.1

    # Normalize reuse count to 0-1 range (cap at 50 uses)
    reuse_normalized = min(pattern.reuse_count / 50.0, 1.0)

    fitness = (
      success_weight * pattern.success_rate +
      stability_weight * pattern.stability_score +
      reuse_weight * reuse_normalized +
      low_regression_weight * (1.0 - pattern.regression_rate)
    )

    # Clamp to 0.0-1.0 range (Float.clamp not available in Elixir 1.18.4)
    max(0.0, min(1.0, fitness))
  end

  @doc """
  Group patterns by failure signature to detect competitions.

  ## Parameters

  - `patterns` — List of all active patterns
  - `generation` — Current generation

  ## Returns

  - List of competition results (may be empty if no competitions detected)
  """
  def detect_and_run_competitions(patterns, generation) do
    # Group patterns by failure signature
    grouped = Enum.group_by(patterns, & &1.failure_signature)

    # Run competitions for signatures with 2+ patterns
    Enum.flat_map(grouped, fn {signature, signature_patterns} ->
      if length(signature_patterns) >= 2 do
        case run(signature_patterns, signature, generation) do
          nil -> []
          competition -> [competition]
        end
      else
        []
      end
    end)
  end

  @doc """
  Get competition summary metrics.

  ## Parameters

  - `competitions` — List of competition results

  ## Returns

  - Map of competition metrics
  """
  def get_metrics(competitions) do
    total_competitions = length(competitions)

    if total_competitions == 0 do
      %{
        competition_events: 0,
        avg_participants: 0.0,
        avg_fitness_improvement: 0.0,
        winner_stability_rate: 0.0
      }
    else
      avg_participants =
        Enum.sum_by(competitions, & &1.participant_count) / total_competitions

      avg_improvement =
        Enum.sum_by(competitions, & &1.fitness_improvement) / total_competitions

      # Winner stability: percentage of competitions where winner had fitness > 0.7
      stable_winners =
        Enum.count(competitions, & &1.winner_fitness >= 0.7)

      winner_stability_rate = stable_winners / total_competitions

      %{
        competition_events: total_competitions,
        avg_participants: Float.round(avg_participants, 2),
        avg_fitness_improvement: Float.round(avg_improvement, 3),
        winner_stability_rate: Float.round(winner_stability_rate, 3)
      }
    end
  end

  # Private helpers

  defp generate_competition_id(failure_signature) do
    normalized =
      failure_signature
      |> String.replace(~r/[^a-z0-9_]/, "_")
      |> String.slice(0..40)

    "competition_#{normalized}_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"
  end
end
