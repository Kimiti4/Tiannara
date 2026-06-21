defmodule Tiannara.ASC.Crucible.RepairEcology.RepairSpecies do
  @moduledoc """
  Repair Species — a family of related repair patterns that compete and evolve.

  A species represents a coherent repair strategy (e.g., "Rollback", "Constraint Reinforcement",
  "Caching") that can have multiple pattern variants competing within the same ecological niche.

  ## Fields

  - `id` — Unique species identifier
  - `name` — Human-readable species name
  - `origin_pattern` — The first pattern that founded this species
  - `generation` — Generation when species was born
  - `population_size` — Number of active patterns in this species
  - `fitness` — Average fitness of all patterns in species
  - `survival_rate` — Historical survival rate across competitions
  - `transferability` — Cross-project transfer success rate
  - `domains_seen` — List of project domains where species has been applied
  - `created_at` — When species was discovered
  - `updated_at` — Last update timestamp

  ## Example

      iex> species = %Tiannara.ASC.Crucible.RepairEcology.RepairSpecies{
      ...>   id: "species_rollback",
      ...>   name: "Rollback Species",
      ...>   origin_pattern: "pattern_xxx",
      ...>   generation: 1,
      ...>   population_size: 3
      ...> }

  """

  @derive Jason.Encoder
  defstruct [
    # Identity
    id: nil,
    name: nil,
    origin_pattern: nil,

    # Temporal
    generation: 0,
    created_at: nil,
    updated_at: nil,

    # Population Metrics
    population_size: 0,
    fitness: 0.0,
    survival_rate: 0.0,
    transferability: 0.0,

    # Provenance
    domains_seen: [],

    # Lifecycle
    status: :active  # :active, :declining, :extinct
  ]

  @typedoc "Repair species structure"
  @type t :: %__MODULE__{
          id: String.t() | nil,
          name: String.t() | nil,
          origin_pattern: String.t() | nil,
          generation: non_neg_integer(),
          created_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil,
          population_size: non_neg_integer(),
          fitness: float(),
          survival_rate: float(),
          transferability: float(),
          domains_seen: [String.t()],
          status: atom()
        }

  @doc """
  Create a new repair species from an origin pattern.

  ## Parameters

  - `pattern` — The founding repair pattern
  - `generation` — Current generation number
  - `project_domain` — Project domain where pattern originated

  ## Returns

  - New RepairSpecies struct
  """
  def from_pattern(%Tiannara.ASC.Crucible.RepairPattern{} = pattern, generation, project_domain) do
    now = DateTime.utc_now()

    species_name = classify_species_name(pattern)

    %__MODULE__{
      id: generate_species_id(species_name),
      name: species_name,
      origin_pattern: pattern.id,
      generation: generation,
      population_size: 1,
      fitness: pattern.repair_fitness,
      survival_rate: 1.0,  # Starts at 100% after first success
      transferability: pattern.transferability,
      domains_seen: [project_domain],
      created_at: now,
      updated_at: now,
      status: :active
    }
  end

  @doc """
  Update species metrics after pattern addition or removal.

  ## Parameters

  - `species` — Existing species
  - `patterns` — List of all patterns in this species
  - `project_domain` — Optional new domain to add

  ## Returns

  - Updated species with recalculated metrics
  """
  def update_metrics(%__MODULE__{} = species, patterns, project_domain \\ nil) do
    now = DateTime.utc_now()

    # Calculate average fitness
    avg_fitness =
      if length(patterns) > 0 do
        Enum.sum_by(patterns, & &1.repair_fitness) / length(patterns)
      else
        0.0
      end

    # Calculate average survival rate
    avg_survival =
      if length(patterns) > 0 do
        Enum.sum_by(patterns, & &1.success_rate) / length(patterns)
      else
        0.0
      end

    # Calculate average transferability
    avg_transfer =
      if length(patterns) > 0 do
        Enum.sum_by(patterns, & &1.transferability) / length(patterns)
      else
        0.0
      end

    # Update domains
    new_domains =
      if project_domain && project_domain not in species.domains_seen do
        [project_domain | species.domains_seen]
      else
        species.domains_seen
      end

    %__MODULE__{
      species
      | population_size: length(patterns),
        fitness: Float.round(avg_fitness, 3),
        survival_rate: Float.round(avg_survival, 3),
        transferability: Float.round(avg_transfer, 3),
        domains_seen: Enum.uniq(new_domains),
        updated_at: now
    }
  end

  @doc """
  Mark species as extinct.

  ## Parameters

  - `species` — Species to retire

  ## Returns

  - Retired species
  """
  def mark_extinct(%__MODULE__{} = species) do
    %__MODULE__{
      species
      | status: :extinct,
        updated_at: DateTime.utc_now()
    }
  end

  # Private helpers

  defp generate_species_id(name) do
    normalized =
      name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9_]/, "_")

    "species_#{normalized}_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"
  end

  defp classify_species_name(%Tiannara.ASC.Crucible.RepairPattern{} = pattern) do
    # Classify pattern into species based on repair strategy keywords
    strategy = String.downcase(pattern.repair_strategy || "")

    cond do
      String.contains?(strategy, ["rollback", "revert", "undo"]) ->
        "Rollback Species"

      String.contains?(strategy, ["constraint", "validation", "invariant"]) ->
        "Constraint Reinforcement Species"

      String.contains?(strategy, ["cache", "memoize", "store"]) ->
        "Caching Species"

      String.contains?(strategy, ["retry", "repeat", "attempt"]) ->
        "Retry Logic Species"

      String.contains?(strategy, ["auth", "permission", "access", "token"]) ->
        "Auth Hardening Species"

      String.contains?(strategy, ["rate", "limit", "throttle"]) ->
        "Rate Limiting Species"

      String.contains?(strategy, ["timeout", "deadline", "expire"]) ->
        "Timeout Management Species"

      String.contains?(strategy, ["fallback", "default", "graceful"]) ->
        "Fallback Strategy Species"

      String.contains?(strategy, ["sanitize", "escape", "encode"]) ->
        "Input Sanitization Species"

      true ->
        "General Repair Species"
    end
  end
end
