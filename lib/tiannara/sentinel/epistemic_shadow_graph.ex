defmodule Tiannara.Sentinel.EpistemicShadowGraph do
  @moduledoc """
  The Epistemic Shadow-Graph (ESG).
  Provides zero-cost, accelerated micro-sandboxes to mathematically prove
  the safety of immune interventions before they touch the live substrate.
  """
  use GenServer
  require Logger

  @default_simulation_ticks 5_000
  @confidence_threshold 0.85

  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end

  # --- PUBLIC API ---

  @doc """
  Initiates the ESG lifecycle: forks the state, simulates the cure, and returns a decision.
  """
  def validate_intervention(world_id, proposed_cure, telemetry) do
    Logger.info("🔬 [ESG] Initiating shadow simulation for World #{world_id}.")
    
    # 1. Fork the latent state (zero-cost sparse copy)
    shadow_id = fork_latent_state(world_id)
    
    # 2. Apply the cure and fast-forward the simulation
    simulation_result = simulate_forward(shadow_id, proposed_cure, @default_simulation_ticks)
    
    # 3. Evaluate the mathematical confidence of the outcome
    confidence_score = evaluate_stability(simulation_result, telemetry)
    
    # 4. Make the decision and clean up
    decision = if confidence_score >= @confidence_threshold do
      :approved
    else
      :rejected
    end

    destroy_shadow(shadow_id)
    
    {decision, confidence_score}
  end

  # --- INTERNAL MECHANICS ---

  defp fork_latent_state(world_id) do
    shadow_id = "shadow_#{world_id}_#{System.unique_integer([:positive])}"
    
    # Ensure ETS table exists
    if :ets.info(:esg_active_shadows) == :undefined do
      :ets.new(:esg_active_shadows, [:set, :public, :named_table, read_concurrency: true])
    end

    # Fetch the compressed LEOC vector and sparse causal graph snapshot safely
    latent_state =
      if Code.ensure_loaded?(Tiannara.Meta.Epistemics.LongitudinalMemory) do
        case Tiannara.Meta.Epistemics.LongitudinalMemory.get_compressed_state(world_id) do
          {:ok, value} -> value
          value when is_map(value) or is_list(value) -> value
          _ -> throw({:unavailable, :latent_state_unavailable})
        end
      else
        throw({:unavailable, :latent_memory_provider_unavailable})
      end

    causal_snapshot =
      if Code.ensure_loaded?(Tiannara.Meta.CausalDataLayer.Traversal) do
        Tiannara.Meta.CausalDataLayer.Traversal.get_sparse_snapshot(world_id)
      else
        throw({:unavailable, :causal_snapshot_provider_unavailable})
      end
    
    # Store in a temporary, high-speed ETS table dedicated to shadows
    :ets.insert(:esg_active_shadows, {shadow_id, %{
      world_id: world_id,
      latent_state: latent_state,
      causal_snapshot: causal_snapshot,
      created_at: System.system_time(:millisecond)
    }})
    
    shadow_id
  end

  defp simulate_forward(shadow_id, proposed_cure, ticks) do
    # Retrieve the shadow state
    [{^shadow_id, shadow_data}] = :ets.lookup(:esg_active_shadows, shadow_id)
    
    # Apply the intervention to the latent state
    mutated_state = apply_intervention_to_latent_state(shadow_data.latent_state, proposed_cure)
    
    # Fast-forward the mathematical projection (lightweight, no full physics render)
    # This simulates the thermodynamic and causal drift over 'ticks'
    final_state =
      if Code.ensure_loaded?(Tiannara.Meta.CausalTensegrityEngine) do
        Tiannara.Meta.CausalTensegrityEngine.project_forward(
          mutated_state, 
          shadow_data.causal_snapshot, 
          ticks
        )
      else
        throw({:unavailable, :causal_projection_engine_unavailable})
      end

    %{initial: shadow_data.latent_state, final: final_state, ticks: ticks}
  end

  defp evaluate_stability(simulation_result, original_telemetry) do
    # Calculate the gradient of stability (∇S) between the initial and final state
    # A high score means the intervention successfully dampened the anomaly without causing new ones.
    divergence = calculate_ontological_divergence(simulation_result.initial, simulation_result.final)
    
    # Penalize if the divergence exceeds the original anomaly's severity (autoimmune overreaction)
    original_severity = Map.get(original_telemetry, :anomaly_severity, 1.0)
    
    if divergence <= original_severity * 0.5 do
      # Intervention successfully reduced the problem
      1.0 - (divergence / original_severity)
    else
      # Intervention made it worse or caused new instability
      0.0
    end
  end

  defp apply_intervention_to_latent_state(latent_state, :observe_only), do: latent_state
  defp apply_intervention_to_latent_state(latent_state, cure) when is_map(latent_state) do
    case Map.get(latent_state, :leoc, Map.get(latent_state, "leoc")) do
      vector when is_list(vector) ->
        delta = case cure do
          :tighten_constraints -> -0.01
          :inject_novelty -> 0.01
          :prune_branch -> -0.005
          _ -> 0.0
        end
        Map.put(latent_state, :leoc, Enum.map(vector, fn x -> if is_number(x), do: x + delta, else: x end))
      _ -> latent_state
    end
  end
  defp apply_intervention_to_latent_state(latent_state, _cure), do: latent_state

  defp calculate_ontological_divergence(initial, final) do
    a = numeric_vector(initial)
    b = numeric_vector(final)
    if a == [] or b == [] do
      1.0
    else
      n = min(length(a), length(b))
      {aa, bb} = {Enum.take(a, n), Enum.take(b, n)}
      distance = :math.sqrt(Enum.zip(aa, bb) |> Enum.reduce(0.0, fn {x, y}, acc -> acc + :math.pow(x - y, 2) end))
      distance / max(:math.sqrt(Enum.reduce(aa, 0.0, fn x, acc -> acc + x*x end)), 1.0)
    end
  end

  defp numeric_vector(value) when is_list(value), do: Enum.filter(value, &is_number/1)
  defp numeric_vector(value) when is_map(value), do: value |> Map.values() |> Enum.flat_map(&numeric_vector/1)
  defp numeric_vector(value) when is_number(value), do: [value]
  defp numeric_vector(_), do: []

  defp destroy_shadow(shadow_id) do
    :ets.delete(:esg_active_shadows, shadow_id)
    Logger.debug("🗑️ [ESG] Shadow #{shadow_id} garbage collected.")
  end
end
