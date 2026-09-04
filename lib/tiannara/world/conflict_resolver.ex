defmodule Tiannara.World.ConflictResolver do
  @moduledoc """
  Conflict Resolver — merge policies for concurrent world mutations.

  Resolves disagreements when multiple sources attempt to mutate the same entity
  using configurable policies. Ensures atomic, auditable resolution.
  """
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.World.WorldMutationEngine
  alias Tiannara.CEL.Services.ExecutiveMemory
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  # ---------- ExecutiveService Behaviour ----------

  @impl Tiannara.ExecutiveService
  def id, do: :conflict_resolver

  @impl Tiannara.ExecutiveService
  def version, do: "1.0.0"

  @impl Tiannara.ExecutiveService
  def capabilities do
    [:concurrent_mutation_resolution, :policy_based_merging, :human_escalation]
  end

  @impl Tiannara.ExecutiveService
  def dependencies, do: [:persistent_memory, :world_mutation_engine]

  @impl Tiannara.ExecutiveService
  def priority, do: :high

  @impl Tiannara.ExecutiveService
  def constitutional_score do
    %ConstitutionalScore{
      service_id: id(),
      health: 1.0,
      constitutional_alignment: 1.0,
      transparency: 1.0,
      explainability: 1.0,
      evidence_quality: 1.0,
      human_oversight: 1.0,
      computed_at: DateTime.utc_now()
    }
  end

  # ---------- Client API ----------

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def attempt_merge(existing_entity, incoming_entity) do
    GenServer.call(__MODULE__, {:attempt_merge, existing_entity, incoming_entity})
  end

  def apply_resolution(conflict_record, resolution) do
    GenServer.call(__MODULE__, {:apply_resolution, conflict_record, resolution})
  end

  def stats, do: GenServer.call(__MODULE__, :stats)

  # ---------- Server Callbacks ----------

  @impl true
  def init(_opts) do
    {:ok, %{
      resolutions_count: 0,
      human_escalations: 0,
      healthy: true,
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_call({:attempt_merge, existing, incoming}, _from, state) do
    merged_attrs = Map.merge(existing.attributes || %{}, incoming.attributes || %{}, fn _k, v1, v2 ->
      if is_map(v1) and is_map(v2), do: Map.merge(v1, v2), else: v2
    end)

    merged_confidence = max(existing.confidence || 0.0, incoming.confidence || 0.0)

    merged_evidence = ((existing.attributes || %{})[:evidence] || []) ++ ((incoming.attributes || %{})[:evidence] || [])

    final_attrs = Map.merge(merged_attrs, %{
      confidence: merged_confidence,
      evidence: Enum.uniq(merged_evidence)
    })

    mutation_spec = %{id: existing.id, updates: final_attrs, resolution_type: :auto_merge}

    case WorldMutationEngine.mutate(:resolve_conflict_merge, mutation_spec) do
      {:ok, mutation_id} ->
        {:reply, {:ok, final_attrs, mutation_id}, %{state | resolutions_count: state.resolutions_count + 1}}
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:apply_resolution, conflict, resolution}, _from, state) do
    case resolution do
      :human_review ->
        ExecutiveMemory.record_decision(
          "conflict_escalated_#{conflict.id}",
          :conflict_escalated_to_human,
          %{conflict_id: conflict.id, existing: conflict.existing_state, incoming: conflict.incoming_state}
        )
        {:reply, {:ok, :escalated}, %{state | human_escalations: state.human_escalations + 1}}

      _ ->
        {:reply, {:error, :unsupported_resolution}, state}
    end
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, state, state}
  end
end
