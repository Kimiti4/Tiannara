defmodule Tiannara.Meta.CausalTensegrityEngine do
  @moduledoc """
  Resolves causal paradoxes by binding conflicting timelines into stable loop structures.
  
  Implements the "Tensegrity Reality Fork" model from 5E.md:
  - Detects causal invalidation cycles when resurrected laws destroy their origin paths
  - Converts paradox into structural tension instead of collapse/bifurcation
  - Creates Causal Tensegrity Nodes (CTNs) as self-stabilizing contradiction knots
  
  ## Formal Model
  
  Paradox intensity: κ = |H_f - H_b|
  Stability pressure: P_stable = exp(-κ / τ)
  
  Where:
    H_f = forward-history consistency score
    H_b = backward-origin consistency score
    τ = local selection temperature
  
  ## Resolution Strategy
  
  - P_stable > 0.6 → Bind tensegrity loop (stable contradiction)
  - 0.2 < P_stable ≤ 0.6 → Compress into meta-region (partial reconciliation)
  - P_stable ≤ 0.2 → Isolate as chaos cell (quarantine unstable paradox)
  """

  use GenServer
  require Logger

  alias Tiannara.Causality.Graph

  @type ct_node :: %{
    id: String.t(),
    type: :causal_tensegrity_node,
    anchors: %{forward: String.t(), backward: String.t()},
    tension: float(),
    loop_frequency: float(),
    entropy_damping: float(),
    created_at: DateTime.t()
  }

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Initialize ETS table for CTN storage
    :ets.new(:causal_tensegrity_nodes, [:named_table, :set, :public])
    
    Logger.info("🕸️  CausalTensegrityEngine initialized (paradox resolution engine)")
    {:ok, %{total_ctns: 0, paradoxes_resolved: 0}}
  end

  # ==================== Public API ====================

  @doc """
  Detect and resolve a causal paradox.
  
  Called when a resurrected law mutates a region so violently it destroys
  its own thermodynamic origin pathway.
  """
  def resolve_paradox(region_id, forward_state, backward_state, options \\ []) do
    GenServer.cast(__MODULE__, {:paradox_detected, region_id, forward_state, backward_state, options})
  end

  @doc """
  Get all active Causal Tensegrity Nodes.
  """
  def get_active_ctns do
    GenServer.call(__MODULE__, :get_ctns)
  end

  @doc """
  Query CTNs in a specific region.
  """
  def query_region_ctns(region_id) do
    GenServer.call(__MODULE__, {:query_region, region_id})
  end

  @doc """
  Get tensegrity engine statistics.
  """
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def handle_cast({:paradox_detected, region_id, forward, backward, _options}, state) do
    Logger.warning("⚡ Paradox detected in region #{region_id}")
    
    # Compute consistency scores
    h_forward = compute_forward_consistency(forward)
    h_backward = compute_backward_consistency(backward)
    
    # Calculate paradox intensity
    kappa = abs(h_forward - h_backward)
    tau = Map.get(forward, :temperature, 0.5)
    
    # Compute stability pressure
    stability_pressure = :math.exp(-kappa / (tau + 0.001))
    
    Logger.debug("📊 Paradox metrics: κ=#{kappa |> Float.round(3)}, τ=#{tau}, P_stable=#{stability_pressure |> Float.round(3)}")
    
    # Resolution strategy based on stability pressure
    cond do
      stability_pressure > 0.6 ->
        bind_tensegrity_loop(region_id, forward, backward, kappa, stability_pressure)
      
      stability_pressure > 0.2 ->
        compress_into_meta_region(region_id, forward, backward, kappa)
      
      true ->
        isolate_as_chaos_cell(region_id, forward, backward, kappa)
    end
    
    {:noreply, %{state | paradoxes_resolved: state.paradoxes_resolved + 1}}
  end

  @impl true
  def handle_call(:get_ctns, _from, state) do
    ctns = :ets.foldl(fn {_id, ctn}, acc -> [ctn | acc] end, [], :causal_tensegrity_nodes)
    {:reply, {:ok, ctns}, state}
  end

  @impl true
  def handle_call({:query_region, region_id}, _from, state) do
    ctns = :ets.foldl(fn {_id, ctn}, acc ->
      if ctn.id =~ region_id, do: [ctn | acc], else: acc
    end, [], :causal_tensegrity_nodes)
    
    {:reply, {:ok, ctns}, state}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = %{
      total_ctns: state.total_ctns,
      paradoxes_resolved: state.paradoxes_resolved,
      active_loops: count_active_loops(),
      avg_tension: calculate_avg_tension()
    }
    
    {:reply, {:ok, stats}, state}
  end

  # ==================== Private Helpers ====================

  defp compute_forward_consistency(forward_state) do
    # Measure how well forward state aligns with expected evolution
    # In production, this would compare against predicted trajectory
    Map.get(forward_state, :fitness, 0.5) * Map.get(forward_state, :coherence, 0.5)
  end

  defp compute_backward_consistency(backward_state) do
    # Measure how well backward state matches ancestral conditions
    # In production, this would trace causal lineage
    Map.get(backward_state, :fitness, 0.5) * Map.get(backward_state, :stability, 0.5)
  end

  defp bind_tensegrity_loop(region_id, forward, backward, kappa, stability_pressure) do
    # Create Causal Tensegrity Node
    ctn_id = "CTN-#{region_id}-#{System.system_time(:second)}"
    
    ctn = %{
      id: ctn_id,
      type: :causal_tensegrity_node,
      anchors: %{
        forward: Map.get(forward, :id, "unknown"),
        backward: Map.get(backward, :id, "unknown")
      },
      tension: kappa,
      loop_frequency: calculate_loop_frequency(kappa),
      entropy_damping: stability_pressure,
      created_at: DateTime.utc_now()
    }
    
    # Store in ETS
    :ets.insert(:causal_tensegrity_nodes, {ctn_id, ctn})
    
    # Publish to NATS
    publish_tensegrity_event(ctn, :bound)
    
    Logger.info("✅ Bound tensegrity loop #{ctn_id} (tension: #{kappa |> Float.round(3)})")
    
    update_stats()
  end

  defp compress_into_meta_region(region_id, forward, backward, kappa) do
    # Partial reconciliation - merge into higher-order abstraction
    Logger.info("🗜️  Compressing paradox in #{region_id} into meta-region")
    
    # TODO: Implement meta-region compression logic
    publish_tensegrity_event(%{id: "META-#{region_id}"}, :compressed)
  end

  defp isolate_as_chaos_cell(region_id, forward, backward, kappa) do
    # Quarantine unstable paradox to prevent cascade
    Logger.warning("⚠️  Isolating chaos cell in #{region_id} (κ=#{kappa |> Float.round(3)})")
    
    # TODO: Implement chaos cell isolation
    publish_tensegrity_event(%{id: "CHAOS-#{region_id}"}, :isolated)
  end

  defp calculate_loop_frequency(kappa) do
    # Higher paradox intensity → faster oscillation
    # Frequency range: 1.0 to 10.0 Hz
    1.0 + kappa * 9.0
  end

  defp publish_tensegrity_event(ctn, mode) do
    payload = %{
      event_type: "causal_tensegrity_#{mode}",
      ctn_id: ctn.id,
      mode: mode,
      forward_anchor: Map.get(ctn, :anchors, %{})[:forward],
      backward_anchor: Map.get(ctn, :anchors, %{})[:backward],
      tension: Map.get(ctn, :tension, 0.0),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }
    
    try do
      Tiannara.NATS.MetaEvolutionStreamManager.publish("tiannara.meta.causal.tensegrity.bound", payload)
    rescue
      e -> Logger.warning("⚠️  Failed to publish tensegrity event: #{inspect(e)}")
    end
  end

  defp update_stats do
    new_count = :ets.info(:causal_tensegrity_nodes, :size)
    # Update internal counter (simplified)
  end

  defp count_active_loops do
    :ets.foldl(fn {_id, ctn}, count ->
      if ctn.entropy_damping > 0.3, do: count + 1, else: count
    end, 0, :causal_tensegrity_nodes)
  end

  defp calculate_avg_tension do
    tensions = :ets.foldl(fn {_id, ctn}, acc -> [ctn.tension | acc] end, [], :causal_tensegrity_nodes)
    
    if length(tensions) > 0 do
      Enum.sum(tensions) / length(tensions)
    else
      0.0
    end
  end
end
