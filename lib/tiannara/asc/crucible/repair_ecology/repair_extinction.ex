defmodule Tiannara.ASC.Crucible.RepairEcology.RepairExtinction do
  @moduledoc """
  Repair Extinction — detects and retires failing repair patterns.

  Extinction criteria:
  - success_rate < 20%
  - OR reuse_count = 0 for 10 epochs
  - OR fitness below population median for 5 consecutive epochs

  Responsibilities:
  - Monitor pattern health metrics
  - Detect extinction conditions
  - Record extinction events with cause analysis
  - Track extinction rates and species lifespan

  ## Success Criteria

  - extinction_events ≥ 20
  - average_species_lifespan tracked
  - extinction_causes categorized

  ## Example

      iex> extinctions = RepairExtinction.check_patterns(patterns, population_median_fitness, epoch_id)
      iex> length(extinctions)
      3

  """

  alias Tiannara.ASC.Crucible.RepairPattern

  @derive Jason.Encoder
  defstruct [
    # Event Identity
    event_id: nil,
    pattern_id: nil,
    species_id: nil,

    # Extinction Details
    cause: nil,              # :low_success, :no_reuse, :below_median_fitness
    final_fitness: 0.0,
    final_success_rate: 0.0,
    age_epochs: 0,           # How many epochs pattern survived

    # Context
    epoch_id: nil,
    generation: 0,

    # Temporal
    timestamp: nil
  ]

  @typedoc "Extinction event structure"
  @type t :: %__MODULE__{
          event_id: String.t() | nil,
          pattern_id: String.t() | nil,
          species_id: String.t() | nil,
          cause: atom() | nil,
          final_fitness: float(),
          final_success_rate: float(),
          age_epochs: non_neg_integer(),
          epoch_id: String.t() | nil,
          generation: non_neg_integer(),
          timestamp: DateTime.t() | nil
        }

  @doc """
  Check all patterns for extinction conditions.

  ## Parameters

  - `patterns` — List of all active patterns
  - `population_median_fitness` — Median fitness across all patterns
  - `epoch_id` — Current epoch identifier
  - `generation` — Current generation number

  ## Returns

  - List of extinction events (may be empty)
  """
  def check_patterns(patterns, population_median_fitness, epoch_id, generation) do
    _now = DateTime.utc_now()

    Enum.flat_map(patterns, fn pattern ->
      case check_extinction_condition(pattern, population_median_fitness, epoch_id, generation) do
        nil -> []
        event -> [event]
      end
    end)
  end

  @doc """
  Check if a single pattern should go extinct.

  ## Parameters

  - `pattern` — Pattern to evaluate
  - `population_median_fitness` — Median fitness threshold
  - `epoch_id` — Current epoch
  - `generation` — Current generation

  ## Returns

  - Extinction event if pattern should be retired, nil otherwise
  """
  def check_extinction_condition(%RepairPattern{} = pattern, population_median_fitness, epoch_id, generation) do
    now = DateTime.utc_now()

    cond do
      # Criterion 1: Very low success rate
      pattern.success_rate < 0.20 ->
        create_extinction_event(pattern, :low_success, epoch_id, generation, now)

      # Criterion 2: No reuse for extended period (approximate using consecutive failures)
      pattern.consecutive_failures >= 10 ->
        create_extinction_event(pattern, :no_reuse, epoch_id, generation, now)

      # Criterion 3: Below median fitness for sustained period
      pattern.repair_fitness < population_median_fitness and pattern.consecutive_failures >= 5 ->
        create_extinction_event(pattern, :below_median_fitness, epoch_id, generation, now)

      # Pattern survives
      true ->
        nil
    end
  end

  @doc """
  Calculate extinction statistics.

  ## Parameters

  - `extinction_events` — List of extinction events

  ## Returns

  - Map of extinction metrics
  """
  def get_metrics(extinction_events) do
    total_extinctions = length(extinction_events)

    if total_extinctions == 0 do
      %{
        extinction_events: 0,
        extinction_rate: 0.0,
        average_lifespan_epochs: 0.0,
        causes: %{}
      }
    else
      # Calculate average lifespan
      avg_lifespan =
        Enum.sum_by(extinction_events, & &1.age_epochs) / total_extinctions

      # Count by cause
      causes =
        extinction_events
        |> Enum.group_by(& &1.cause)
        |> Enum.map(fn {cause, events} -> {cause, length(events)} end)
        |> Enum.into(%{})

      %{
        extinction_events: total_extinctions,
        extinction_rate: Float.round(total_extinctions / max(1, total_extinctions), 3),
        average_lifespan_epochs: Float.round(avg_lifespan, 2),
        causes: causes
      }
    end
  end

  @doc """
  Calculate population median fitness.

  ## Parameters

  - `patterns` — List of all patterns

  ## Returns

  - Median fitness value
  """
  def calculate_median_fitness(patterns) do
    if length(patterns) == 0 do
      0.0
    else
      fitnesses =
        patterns
        |> Enum.map(& &1.repair_fitness)
        |> Enum.sort()

      mid = div(length(fitnesses), 2)

      if rem(length(fitnesses), 2) == 0 do
        # Even number: average of two middle values
        (Enum.at(fitnesses, mid - 1) + Enum.at(fitnesses, mid)) / 2
      else
        # Odd number: middle value
        Enum.at(fitnesses, mid)
      end
    end
  end

  # Private helpers

  defp create_extinction_event(pattern, cause, epoch_id, generation, timestamp) do
    # Calculate approximate age in epochs (using creation time vs now)
    age_seconds = DateTime.diff(timestamp, pattern.created_at || timestamp, :second)
    age_epochs = max(1, div(age_seconds, 60))  # Approximate: 1 epoch per minute

    %__MODULE__{
      event_id: generate_extinction_id(pattern.id),
      pattern_id: pattern.id,
      species_id: determine_species_from_pattern(pattern),
      cause: cause,
      final_fitness: pattern.repair_fitness,
      final_success_rate: pattern.success_rate,
      age_epochs: age_epochs,
      epoch_id: epoch_id,
      generation: generation,
      timestamp: timestamp
    }
  end

  defp generate_extinction_id(pattern_id) do
    "extinct_#{pattern_id}_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"
  end

  defp determine_species_from_pattern(%RepairPattern{} = pattern) do
    # Extract species name from repair strategy
    strategy = String.downcase(pattern.repair_strategy || "")

    cond do
      String.contains?(strategy, ["rollback", "revert"]) -> "species_rollback"
      String.contains?(strategy, ["constraint", "validation"]) -> "species_constraint"
      String.contains?(strategy, ["cache"]) -> "species_caching"
      String.contains?(strategy, ["retry"]) -> "species_retry"
      String.contains?(strategy, ["auth"]) -> "species_auth"
      String.contains?(strategy, ["rate", "limit"]) -> "species_rate_limiting"
      true -> "species_general"
    end
  end
end
