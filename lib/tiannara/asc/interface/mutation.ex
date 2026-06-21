defmodule Tiannara.ASC.Interface.Mutation do
  @moduledoc """
  Interface Mutation — represents an explicit evolutionary change to interface structures.

  Every mutation is recorded as a first-class artifact with:
  - Type (what changed)
  - Target (what was mutated)
  - Before/after state (provenance)
  - Rationale (why the mutation occurred)
  - Timestamp (when it happened)

  This enables future law discovery by answering:
  "Which mutations most frequently increase interface fitness?"

  ## Example

      iex> mutation = %Tiannara.ASC.Interface.Mutation{
      ...>   id: "mut_123",
      ...>   type: :split_contract,
      ...>   target_id: "user.create",
      ...>   before_state: %Contract{...},
      ...>   after_state: [%Contract{...}, %Contract{...}],
      ...>   rationale: "Split by field to reduce complexity",
      ...>   timestamp: DateTime.utc_now(),
      ...>   fitness_delta: 0.15
      ...> }

  """

  @derive Jason.Encoder
  defstruct [
    # Identity
    id: nil,                    # Unique mutation identifier
    type: nil,                  # Mutation type atom (:add_contract, :merge_events, etc.)

    # Target
    target_id: nil,             # ID of the structure being mutated
    target_type: nil,           # Type of target (:contract, :event, :protocol)

    # Provenance
    before_state: nil,          # State before mutation
    after_state: nil,           # State after mutation

    # Metadata
    rationale: nil,             # Why this mutation was applied
    timestamp: nil,             # When mutation occurred
    generation: 0,              # Evolution generation number

    # Fitness Impact
    fitness_before: 0.0,        # Genome fitness before mutation
    fitness_after: 0.0,         # Genome fitness after mutation
    fitness_delta: 0.0,         # Change in fitness (positive = improvement)

    # Outcome
    success: true,              # Did mutation succeed?
    reverted: false             # Was mutation later reverted?
  ]

  @typedoc "Interface mutation record"
  @type t :: %__MODULE__{
          id: String.t() | nil,
          type: atom() | nil,
          target_id: String.t() | nil,
          target_type: atom() | nil,
          before_state: any(),
          after_state: any(),
          rationale: String.t() | nil,
          timestamp: DateTime.t() | nil,
          generation: non_neg_integer(),
          fitness_before: float(),
          fitness_after: float(),
          fitness_delta: float(),
          success: boolean(),
          reverted: boolean()
        }

  @doc """
  Create a new mutation record.

  Automatically generates a unique ID and timestamp.
  """
  def new(type, target_id, target_type, before_state, after_state, opts \\ []) do
    fitness_before = Keyword.get(opts, :fitness_before, 0.0)
    fitness_after = Keyword.get(opts, :fitness_after, 0.0)
    fitness_delta = fitness_after - fitness_before

    %__MODULE__{
      id: generate_id(),
      type: type,
      target_id: target_id,
      target_type: target_type,
      before_state: before_state,
      after_state: after_state,
      rationale: Keyword.get(opts, :rationale),
      timestamp: DateTime.utc_now(),
      generation: Keyword.get(opts, :generation, 0),
      fitness_before: fitness_before,
      fitness_after: fitness_after,
      fitness_delta: fitness_delta,
      success: Keyword.get(opts, :success, true),
      reverted: Keyword.get(opts, :reverted, false)
    }
  end

  @doc """
  Register mutation in Knowledge Archive for future law discovery.

  Every mutation becomes part of the civilizational memory, enabling queries like:
  "Which contract mutations most frequently improve maintainability?"
  """
  def register(%__MODULE__{} = mutation) do
    # Register in Knowledge Archive (which also logs and records telemetry)
    Tiannara.ASC.Interface.KnowledgeArchive.register_mutation(mutation)
  end

  @doc """
  Record mutation in Observatory telemetry.

  Updates metrics:
  - interface_mutation_count
  - contract_mutation_count / event_mutation_count / protocol_mutation_count
  - successful_mutations / reverted_mutations
  - mutation_diversity
  """
  def record_telemetry(%__MODULE__{} = mutation) do
    # TODO: Integrate with Observatory when available
    # For now, return telemetry data structure
    %{
      mutation_type: mutation.type,
      target_type: mutation.target_type,
      fitness_impact: mutation.fitness_delta,
      success: mutation.success,
      reverted: mutation.reverted,
      timestamp: mutation.timestamp
    }
  end

  @doc """
  Check if mutation improved fitness.
  """
  def improved?(%__MODULE__{fitness_delta: delta}), do: delta > 0

  @doc """
  Check if mutation degraded fitness.
  """
  def degraded?(%__MODULE__{fitness_delta: delta}), do: delta < 0

  @doc """
  Check if mutation had neutral effect.
  """
  def neutral?(%__MODULE__{fitness_delta: delta}), do: abs(delta) < 0.01

  # Private helpers

  defp generate_id do
    "mut_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
  end
end
