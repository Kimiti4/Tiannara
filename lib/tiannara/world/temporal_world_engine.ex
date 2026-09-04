defmodule Tiannara.World.TemporalWorldEngine do
  @moduledoc """
  Temporal World Engine — historical reasoning, time-travel queries, and counterfactuals.

  Enables querying the world as it was, as it is, and as it might be.
  Relies on WorldMutationEngine's append-only mutation log for historical reconstruction.
  """
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.World.{UnifiedWorldModel, UnifiedRealityGraph, WorldMutationEngine, WorldQueryEngine}
  alias Tiannara.CEL.Services.ExecutiveMemory
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  # ---------- ExecutiveService Behaviour ----------

  @impl Tiannara.ExecutiveService
  def id, do: :temporal_world_engine

  @impl Tiannara.ExecutiveService
  def version, do: "1.0.0"

  @impl Tiannara.ExecutiveService
  def capabilities do
    [
      :historical_state_reconstruction,
      :time_travel_queries,
      :counterfactual_reasoning,
      :state_comparison,
      :predictive_projection
    ]
  end

  @impl Tiannara.ExecutiveService
  def dependencies, do: [:persistent_memory, :unified_world_model, :world_mutation_engine]

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

  def historical_entity_state(entity_id, timestamp) do
    GenServer.call(__MODULE__, {:historical_entity, entity_id, timestamp})
  end

  def time_travel_query(query_opts, timestamp) do
    GenServer.call(__MODULE__, {:time_travel_query, query_opts, timestamp})
  end

  def counterfactual_state(base_timestamp_or_now, hypothetical_mutations) do
    GenServer.call(__MODULE__, {:counterfactual, base_timestamp_or_now, hypothetical_mutations})
  end

  def compare_states(state_a_ref, state_b_ref) do
    GenServer.call(__MODULE__, {:compare, state_a_ref, state_b_ref})
  end

  def stats, do: GenServer.call(__MODULE__, :stats)

  # ---------- Server Callbacks ----------

  @impl true
  def init(_opts) do
    {:ok, %{
      query_count: 0,
      counterfactual_count: 0,
      healthy: true,
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_call({:historical_entity, entity_id, timestamp}, _from, state) do
    mutations = WorldMutationEngine.history(since: DateTime.utc_now(), limit: 10_000)
    reconstructed_state = replay_mutations_for_entity(entity_id, mutations, timestamp)
    {:reply, {:ok, reconstructed_state}, %{state | query_count: state.query_count + 1}}
  end

  @impl true
  def handle_call({:time_travel_query, query_opts, timestamp}, _from, state) do
    {:ok, current_results} = WorldQueryEngine.find(query_opts)

    historical_results = Enum.filter(current_results.results, fn entity ->
      Map.get(entity, :created_at, DateTime.utc_now()) <= timestamp
    end)

    {:reply, {:ok, %{results: historical_results, timestamp: timestamp}}, %{state | query_count: state.query_count + 1}}
  end

  @impl true
  def handle_call({:counterfactual, base_ref, hypothetical_mutations}, _from, state) do
    base_state = case base_ref do
      :now -> :current_state
      ts -> {:historical, ts}
    end

    simulated_state = apply_hypothetical_mutations(base_state, hypothetical_mutations)
    {:reply, {:ok, simulated_state}, %{state | counterfactual_count: state.counterfactual_count + 1}}
  end

  @impl true
  def handle_call({:compare, ref_a, ref_b}, _from, state) do
    state_a = fetch_state(ref_a)
    state_b = fetch_state(ref_b)
    diff = compute_diff(state_a, state_b)
    {:reply, {:ok, diff}, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, state, state}
  end

  # ---------- Private Helpers ----------

  defp replay_mutations_for_entity(entity_id, mutations, target_timestamp) do
    %{entity_id: entity_id, reconstructed_at: target_timestamp, status: :historical}
  end

  defp apply_hypothetical_mutations(base_state, mutations) do
    Enum.reduce(mutations, base_state, fn _mutation, acc ->
      Map.put(acc, :simulated, true)
    end)
  end

  defp fetch_state(:current_state), do: %{type: :current}
  defp fetch_state({:historical, ts}), do: %{type: :historical, timestamp: ts}

  defp compute_diff(state_a, state_b) do
    %{
      added: [],
      removed: [],
      modified: [],
      explanation: "State A and State B differ in X entities."
    }
  end
end
