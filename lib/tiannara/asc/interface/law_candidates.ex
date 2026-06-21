defmodule Tiannara.ASC.Interface.LawCandidates do
  @moduledoc """
  Interface Law Candidates — emits preliminary law observations from evolution data.

  Analyzes mutation history, transfer success, and species competition to identify
  patterns that may become formal software engineering laws.

  ## Example

      iex> candidates = Tiannara.ASC.Interface.LawCandidates.generate(population_stats)
      iex> Enum.count(candidates)
      3  # Contract splitting, schema versioning, hybrid protocols

  Each candidate has status `:observation` until validated across multiple runs.

  """

  alias Tiannara.ASC.Interface.{Mutation, Transfer}

  @derive Jason.Encoder
  defstruct [
    # Identity
    id: nil,                    # Unique candidate identifier
    title: nil,                 # Descriptive title

    # Observation
    pattern_type: nil,          # Type of pattern (:mutation, :transfer, :competition)
    observation: nil,           # What was observed
    evidence_count: 0,          # Number of supporting instances

    # Metrics
    avg_fitness_delta: 0.0,     # Average fitness impact
    confidence: 0.0,            # Confidence level (0.0-1.0)

    # Status
    status: :observation,       # :observation, :hypothesis, :validated, :law

    # Metadata
    generated_at: nil,          # When candidate was generated
    generation_range: nil       # Generations where pattern was observed
  ]

  @typedoc "Law candidate observation"
  @type t :: %__MODULE__{
          id: String.t() | nil,
          title: String.t() | nil,
          pattern_type: atom() | nil,
          observation: String.t() | nil,
          evidence_count: non_neg_integer(),
          avg_fitness_delta: float(),
          confidence: float(),
          status: atom(),
          generated_at: DateTime.t() | nil,
          generation_range: {non_neg_integer(), non_neg_integer()} | nil
        }

  @doc """
  Generate law candidates from mutation history.

  Identifies mutations that consistently improve fitness across lineages.

  ## Thresholds

  - Minimum evidence count: 5 occurrences
  - Minimum average fitness delta: 0.05
  - Minimum confidence: 0.6

  ## Returns

  - List of law candidate observations

  """
  def generate_from_mutations(mutations) when length(mutations) == 0 do
    []
  end

  def generate_from_mutations(mutations) do
    mutations
    |> Enum.group_by(& &1.type)
    |> Enum.flat_map(fn {mutation_type, type_mutations} ->
      generate_mutation_candidates(mutation_type, type_mutations)
    end)
  end

  @doc """
  Generate law candidates from knowledge transfers.

  Identifies transfer patterns that successfully cross species boundaries.
  """
  def generate_from_transfers(transfers) when length(transfers) == 0 do
    []
  end

  def generate_from_transfers(transfers) do
    transfers
    |> Enum.group_by(& &1.type)
    |> Enum.flat_map(fn {transfer_type, type_transfers} ->
      generate_transfer_candidates(transfer_type, type_transfers)
    end)
  end

  @doc """
  Generate law candidates from species competition.

  Identifies which species dominate over time and why.
  """
  def generate_from_species_competition(species_history) when length(species_history) == 0 do
    []
  end

  def generate_from_species_competition(species_history) do
    # Analyze species survival rates
    species_survival = analyze_species_survival(species_history)

    Enum.flat_map(species_survival, fn {species_id, stats} ->
      if stats.avg_longevity > 10 and stats.dominance_rate > 0.5 do
        [
          %__MODULE__{
            id: generate_id(),
            title: "#{species_id} dominance pattern",
            pattern_type: :species_competition,
            observation: "#{species_id} shows high longevity (#{stats.avg_longevity} gens) and dominance (#{Float.round(stats.dominance_rate * 100, 1)}%)",
            evidence_count: stats.generation_count,
            avg_fitness_delta: stats.avg_fitness,
            confidence: calculate_confidence(stats.generation_count, stats.avg_fitness),
            status: :observation,
            generated_at: DateTime.utc_now(),
            generation_range: stats.generation_range
          }
        ]
      else
        []
      end
    end)
  end

  @doc """
  Register law candidate in ASC law registry.

  Stores candidate with status `:observation` for future validation.
  """
  def register_candidate(%__MODULE__{} = candidate) do
    require Logger

    Logger.info(
      "[Interface.LawCandidates] Registered candidate: #{candidate.title} " <>
      "(confidence: #{candidate.confidence}, evidence: #{candidate.evidence_count})"
    )

    # TODO: Integrate with ASC.Laws.Registry when available
    :ok
  end

  @doc """
  Filter candidates by minimum confidence threshold.

  Returns only candidates above the specified confidence level.
  """
  def filter_by_confidence(candidates, min_confidence \\ 0.6) do
    Enum.filter(candidates, fn c -> c.confidence >= min_confidence end)
  end

  @doc """
  Group candidates by pattern type.

  Organizes candidates into mutation/transfer/competition categories.
  """
  def group_by_type(candidates) do
    Enum.group_by(candidates, & &1.pattern_type)
  end

  # Private helpers

  defp generate_id do
    "law_candidate_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
  end

  defp generate_mutation_candidates(mutation_type, mutations) do
    # Calculate statistics
    successful = Enum.filter(mutations, &Mutation.improved?/1)
    evidence_count = length(successful)

    if evidence_count < 5 do
      []
    else
      avg_delta = Enum.sum_by(successful, & &1.fitness_delta) / evidence_count

      if avg_delta < 0.05 do
        []
      else
        confidence = calculate_confidence(evidence_count, avg_delta)

        if confidence < 0.6 do
          []
        else
          [
            %__MODULE__{
              id: generate_id(),
              title: "#{mutation_type} improves fitness",
              pattern_type: :mutation,
              observation: "#{mutation_type} mutations improve fitness by #{Float.round(avg_delta * 100, 1)}% on average",
              evidence_count: evidence_count,
              avg_fitness_delta: Float.round(avg_delta, 3),
              confidence: Float.round(confidence, 3),
              status: :observation,
              generated_at: DateTime.utc_now(),
              generation_range: extract_generation_range(mutations)
            }
          ]
        end
      end
    end
  end

  defp generate_transfer_candidates(transfer_type, transfers) do
    # Calculate statistics
    successful = Enum.filter(transfers, & &1.success?)
    evidence_count = length(successful)

    if evidence_count < 3 do
      []
    else
      avg_delta = Enum.sum_by(successful, & &1.fitness_delta) / evidence_count
      success_rate = evidence_count / length(transfers)

      confidence = calculate_confidence(evidence_count, avg_delta) * success_rate

      if confidence < 0.5 do
        []
      else
        [
          %__MODULE__{
            id: generate_id(),
            title: "#{transfer_type} transfers successfully",
            pattern_type: :transfer,
            observation: "#{transfer_type} patterns transfer between species with #{Float.round(success_rate * 100, 1)}% success rate",
            evidence_count: evidence_count,
            avg_fitness_delta: Float.round(avg_delta, 3),
            confidence: Float.round(confidence, 3),
            status: :observation,
            generated_at: DateTime.utc_now(),
            generation_range: extract_generation_range(transfers)
          }
        ]
      end
    end
  end

  defp analyze_species_survival(species_history) do
    # Group by species ID
    species_data = Enum.group_by(species_history, & &1.species_id)

    Enum.map(species_data, fn {species_id, records} ->
      longevities = Enum.map(records, & &1.longevity)
      fitnesses = Enum.map(records, & &1.avg_fitness)
      generations = Enum.map(records, & &1.generation)

      %{
        species_id: species_id,
        avg_longevity: Enum.sum(longevities) / length(longevities),
        avg_fitness: Enum.sum(fitnesses) / length(fitnesses),
        dominance_rate: calculate_dominance_rate(records),
        generation_count: length(records),
        generation_range: {Enum.min(generations), Enum.max(generations)}
      }
    end)
  end

  defp calculate_dominance_rate(records) do
    # Fraction of generations where this species was most populous
    dominant_count = Enum.count(records, & &1.is_dominant)
    dominant_count / length(records)
  end

  defp calculate_confidence(evidence_count, effect_size) do
    # Simple confidence model: more evidence + larger effect = higher confidence
    # Normalize to 0.0-1.0 range
    evidence_factor = min(evidence_count / 20.0, 1.0)  # Cap at 20 samples
    effect_factor = min(effect_size / 0.2, 1.0)  # Cap at 0.2 delta

    (evidence_factor + effect_factor) / 2
  end

  defp extract_generation_range(records) do
    generations = Enum.map(records, & &1.generation)
    {Enum.min(generations), Enum.max(generations)}
  end
end
