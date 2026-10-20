defmodule Tiannara.Simulation.OmegaPhiConvergenceTest do
  @moduledoc """
  Property-based test harness for Ω/Φ equilibrium dynamics.
  [Original Concept: Thermodynamic Oscillator Stabilization]
  
  Validates that the OMCE↔OLEF bridge maintains:
  - |Ω - Φ| ≤ 0.40 under normal load
  - Ψ ≥ 0.30 during stress scenarios
  - Self-compilation does not destabilize equilibrium
  """
  use ExUnit.Case, async: true
  use PropCheck, default_opts: [numtests: 100]

  alias Tiannara.Bridge.OmegaPhiKernel
  alias Tiannara.Kernel.SelfCompilation
  alias Tiannara.Audit.MetricsCollector

  @omega_phi_max_divergence 0.40
  @psi_critical_threshold 0.30
  @self_compilation_max_depth 3

  property "Ω and Φ remain coupled under stochastic load" do
    forall(
      load_sequence <- load_sequence_generator(),
      do: assert_coupled_equilibrium(load_sequence)
    )
  end

  property "Ψ remains above critical threshold during self-compilation" do
    forall(
      {initial_state, mutation_sequence} <- compilation_scenario_generator(),
      do: assert_stability_during_compilation(initial_state, mutation_sequence)
    )
  end

  property "Bridge recovers from transient divergence" do
    forall(
      {baseline, perturbation} <- perturbation_generator(),
      do: assert_recovery_after_perturbation(baseline, perturbation)
    )
  end

  # --- Property Definitions ---

  defp assert_coupled_equilibrium(load_sequence) do
    initial_state = %{omega: 0.5, phi: 0.5, stability: 1.0}
    
    final_state =
      Enum.reduce(load_sequence, initial_state, fn load, state ->
        OmegaPhiKernel.step(state, %{pressure: load}, %{compression_rate: load * 0.8})
      end)
    
    divergence = abs(final_state.omega - final_state.phi)
    
    assert divergence <= @omega_phi_max_divergence,
           "Ω/Φ divergence exceeded: #{divergence} (threshold: #{@omega_phi_max_divergence})"
    
    assert final_state.stability >= 0.6,
           "Stability degraded below acceptable: #{final_state.stability}"
  end

  defp assert_stability_during_compilation(initial_state, mutation_sequence) do
    # Simulate self-compilation cycles with bounded mutations
    {final_state, _history} =
      Enum.reduce(mutation_sequence, {initial_state, []}, fn mutation, {state, hist} ->
        mutated_rules = apply_mutation(state.active_rules, mutation)
        validated = Tiannara.Kernel.ValidationGate.verify(mutated_rules, @psi_critical_threshold)
        
        case validated do
          {:ok, rules} ->
            new_state = %{state | active_rules: rules}
            next_state = OmegaPhiKernel.step(new_state, %{pressure: 0.6}, %{compression_rate: 0.5})
            next_state = Map.put(next_state, :active_rules, rules)
            {next_state, [state | hist]}
          {:error, _} ->
            {state, hist} # Reject invalid mutations
        end
      end)
    
    psi = compute_psi(final_state)
    
    assert psi >= @psi_critical_threshold,
           "Ψ dropped below critical during compilation: #{psi}"
  end

  defp assert_recovery_after_perturbation(baseline, perturbation) do
    # Apply perturbation, then observe recovery over N ticks
    perturbed = apply_perturbation(baseline, perturbation)
    
    recovery_sequence =
      Stream.iterate(perturbed, &OmegaPhiKernel.step(&1, %{pressure: 0.5}, %{compression_rate: 0.5}))
      |> Enum.take(20)
    
    final = List.last(recovery_sequence)
    
    assert final.stability >= baseline.stability * 0.85,
           "Failed to recover stability: #{final.stability} vs baseline #{baseline.stability}"
  end

  # --- Generators ---
  
  defp active_rules_generator() do
    let(_ <- integer(), do: %{
      omce: %{
        type: :compression_policy,
        body: {:if, {:>, :ontology_density, 0.7}, {:apply, :adaptive, [:aggressive]}, {:apply, :adaptive, [:conservative]}},
        invariants: [:causal_conservation, :observer_safety, :entropy_non_decrease, :psi_stability_bound]
      }
    })
  end

  defp load_sequence_generator() do
    let(size <- choose(10, 50), do: vector(size, float(0.1, 1.0)))
  end

  defp compilation_scenario_generator() do
    let(
      {state, depth} <- {initial_state_generator(), choose(1, @self_compilation_max_depth)},
      do: {state, vector(depth, mutation_generator())}
    )
  end

  defp initial_state_generator() do
    let(
      {o, p, s, r} <- {float(0.0, 1.0), float(0.0, 1.0), float(0.5, 1.0), active_rules_generator()},
      do: %{omega: o, phi: p, stability: s, active_rules: r}
    )
  end

  defp mutation_generator() do
    oneof([
      let(delta <- float(-0.1, 0.1), do: {:adjust_threshold, delta}),
      {:swap_strategy, oneof([:adaptive, :conservative, :aggressive])},
      {:add_constraint, oneof([:causal_conservation, :observer_safety])}
    ])
  end

  defp perturbation_generator() do
    let(
      {state, type, mag, ticks} <- {initial_state_generator(), oneof([:spike, :drop, :oscillation]), float(0.0, 0.3), integer(1, 5)},
      do: {state, %{type: type, magnitude: mag, duration_ticks: ticks}}
    )
  end

  # --- Helper Functions ---

  defp apply_mutation(rules, {:adjust_threshold, delta}) do
    Map.new(rules, fn {k, v} ->
      {k, Map.update(v, :threshold, 0.7, &(&1 + delta))}
    end)
  end

  defp apply_mutation(rules, {:swap_strategy, new_strategy}) do
    Map.new(rules, fn {k, v} ->
      {k, Map.put(v, :strategy, new_strategy)}
    end)
  end

  defp apply_mutation(rules, {:add_constraint, constraint}) do
    Map.new(rules, fn {k, v} ->
      {k, Map.update(v, :constraints, [constraint], &[constraint | &1])}
    end)
  end

  defp apply_perturbation(state, %{type: :spike, magnitude: m}) do
    %{state | omega: min(1.0, state.omega + m)}
  end

  defp apply_perturbation(state, %{type: :drop, magnitude: m}) do
    %{state | phi: max(0.0, state.phi - m)}
  end

  defp apply_perturbation(state, %{type: :oscillation, magnitude: m}) do
    %{
      state |
      omega: state.omega + m * :math.sin(:rand.uniform() * 10),
      phi: state.phi - m * :math.sin(:rand.uniform() * 10)
    }
  end

  defp compute_psi(%{omega: o, phi: p, stability: s}) do
    # Simplified Ψ computation for testing
    diversity_factor = 1.0 - abs(o - p)
    diversity_factor * s
  end

  defp compute_recovery_rate(sequence) do
    [first | rest] = sequence
    initial_stability = first.stability
    final_stability = List.last(rest).stability
    
    (final_stability - initial_stability) / max(length(rest), 1)
  end
end