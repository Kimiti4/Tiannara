defmodule Tiannara.Meta.CausalTensegrityEngine do
  @moduledoc """
  Phase 5E/5F Engine: Manages non-linear temporal reinforcement loops and 
  lightweight mathematical projections for the Epistemic Shadow-Graph (ESG).
  
  This module provides accelerated, zero-cost forward simulation of causal 
  states without invoking the full, heavy physics rendering pipeline.
  """
  use GenServer
  require Logger

  @default_decay_rate 0.05
  @max_ticks 10_000
  @stability_threshold 0.001

  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end

  @doc """
  Projects a mutated latent state forward in time by a specified number of ticks.
  """
  @spec project_forward(map(), map(), integer()) :: map()
  def project_forward(latent_state, causal_snapshot, ticks) 
    when is_integer(ticks) and ticks > 0 and ticks <= @max_ticks do
    do_project_forward(latent_state, causal_snapshot, ticks, 0)
  end

  # Fallback for invalid tick counts
  def project_forward(latent_state, _causal_snapshot, _ticks), do: latent_state

  # ---------------------------------------------------------------------------
  # TAIL-RECURSIVE SIMULATION LOOP
  # ---------------------------------------------------------------------------
  defp do_project_forward(state, snapshot, max_ticks, current_tick) when current_tick < max_ticks do
    # 1. Calculate causal tension and influence from the sparse snapshot
    tension_force = calculate_tension_force(state, snapshot)
    
    # 2. Apply entropy decay and causal forces to the state
    next_state = apply_physics_step(state, tension_force)
    
    # 3. Check for early exit conditions to save compute
    cond do
      stabilized?(next_state, state) -> 
        Logger.debug("🔬 [ESG] Shadow state stabilized at tick #{current_tick}. Early exit.")
        next_state
        
      collapsed?(next_state) -> 
        Logger.debug("🔬 [ESG] Shadow state catastrophically collapsed at tick #{current_tick}. Early exit.")
        next_state
        
      true -> 
        # Continue the forward projection
        do_project_forward(next_state, snapshot, max_ticks, current_tick + 1)
    end
  end

  defp do_project_forward(state, _snapshot, _max_ticks, _current_tick), do: state

  # ---------------------------------------------------------------------------
  # PHYSICS & MATH KERNELS
  # ---------------------------------------------------------------------------

  @doc """
  Calculates the net causal force acting on the latent state based on the snapshot.
  """
  def calculate_tension_force(%{kappa: kappa, tau: tau} = _state, %{tension_coefficient: tc}) do
    # Calculate baseline stability pressure
    stability_pressure = :math.exp(-kappa / (tau + 0.001))
    
    # Determine the direction of the force based on paradox intensity vs stability
    destabilizing_force = kappa * tc * (1.0 - stability_pressure)
    
    %{
      integrity_shift: destabilizing_force * -0.01,
      kappa_shift: destabilizing_force * 0.005,
      tau_shift: (1.0 - stability_pressure) * 0.002
    }
  end

  def calculate_tension_force(_state, _snapshot) do
    %{integrity_shift: 0.0, kappa_shift: 0.0, tau_shift: 0.0}
  end

  @doc """
  Applies a single step of thermodynamic and causal physics to the state.
  """
  def apply_physics_step(state, force) do
    decayed_tau = (state[:tau] || 1.0) * (1.0 - @default_decay_rate)
    decayed_kappa = (state[:kappa] || 0.0) * (1.0 - (@default_decay_rate * 0.5))
    
    new_integrity = (state[:integrity] || 0.8) + force.integrity_shift
    new_kappa = decayed_kappa + force.kappa_shift
    new_tau = decayed_tau + force.tau_shift
    
    %{
      integrity: clamp(new_integrity, 0.0, 1.0),
      kappa: clamp(new_kappa, 0.0, 1.0),
      tau: clamp(new_tau, 0.01, 1.0),
      vector_embedding: state[:vector_embedding]
    }
  end

  # ---------------------------------------------------------------------------
  # EARLY EXIT OPTIMIZATIONS
  # ---------------------------------------------------------------------------

  def stabilized?(new_state, old_state) do
    delta_integrity = abs((new_state[:integrity] || 0.0) - (old_state[:integrity] || 0.0))
    delta_kappa = abs((new_state[:kappa] || 0.0) - (old_state[:kappa] || 0.0))
    delta_tau = abs((new_state[:tau] || 0.0) - (old_state[:tau] || 0.0))
    
    delta_integrity < @stability_threshold and 
    delta_kappa < @stability_threshold and 
    delta_tau < @stability_threshold
  end

  def collapsed?(state) do
    (state[:integrity] || 1.0) <= 0.05 or (state[:kappa] || 0.0) >= 0.95
  end

  defp clamp(value, min, max) do
    value
    |> max(min)
    |> min(max)
  end
end
