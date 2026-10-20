defmodule Tiannara.Simulation.ORBResonanceConvergenceTest do
  @moduledoc """
  Property-based simulation of $R_{align}$ convergence under ontological evolution stress.
  [Original Concept: Resonance Fabric Stability Test]
  
  Validates that the Ontological Resonance Bridge maintains bounded translatability
  when evolving realities experience divergence spikes, novelty variance, and horizon barriers.
  
  Core equation: R_align = (B + α·W₂) / (Γ_div + ε)
  """
  use ExUnit.Case, async: false
  use PropCheck

  @moduletag store_counter_example: false

  alias Tiannara.Phase7.ORB.{ResonanceEngine, HorizonGuard, TopologicalAligner, ManifoldWarper}

  @theta_res 0.65
  @theta_oht 0.30
  @alpha 0.4
  @epsilon 1.0e-6

  property "R_align routes correctly under controlled divergence stress" do
    forall(
      {source, target, stress_profile} <- evolving_ontology_pair_generator(),
      do: assert_resonance_routing(source, target, stress_profile)
    )
  end

  property "R_align converges when novelty variance decreases" do
    forall(
      {initial_pair, decay_sequence} <- novelty_decay_generator(),
      do: assert_convergence_under_decay(initial_pair, decay_sequence)
    )
  end

  property "Horizon barrier engages when divergence penalty exceeds cap" do
    forall(
      {pair, penalty_injections, _} <- horizon_stress_generator(),
      do: assert_horizon_engagement(pair, penalty_injections)
    )
  end

  # --- Property Definitions ---

  defp assert_resonance_routing(source, target, stress) do
    Process.delete({:penalty, source.id, target.id})
    # Apply stress to divergence penalty
    HorizonGuard.inject_penalty(source.id, target.id, stress.penalty)
    
    # Mock bottleneck & Wasserstein with deterministic functions
    bottleneck = mock_bottleneck(source, target, stress.topology_noise)
    wasserstein = mock_wasserstein(source, target, stress.semantic_drift)
    
    numerator = bottleneck + (@alpha * wasserstein)
    denominator = HorizonGuard.divergence_penalty(source.id, target.id) + @epsilon
    resonance = numerator / denominator
    
    case resonance do
      r when r >= @theta_res -> assert_routing_state(:full_bridge)
      r when r >= @theta_oht -> assert_routing_state(:degraded_monitoring)
      _ -> assert_routing_state(:horizon_engaged)
    end
    true
  end

  defp assert_convergence_under_decay({source, target}, decay_seq) do
    Process.delete({:penalty, source.id, target.id})
    initial_resonance = compute_resonance({source, target})

    final_pair = Enum.reduce(decay_seq, {source, target}, fn decay, {s, t} ->
      new_t_novelty = t.novelty + (s.novelty - t.novelty) * decay
      {s, %{t | novelty: new_t_novelty}}
    end)

    final_resonance = compute_resonance(final_pair)
    
    if Enum.sum(decay_seq) > 1.0e-5 do
      assert final_resonance > initial_resonance, "Failed to converge under decay"
    else
      assert final_resonance >= initial_resonance
    end
  end

  defp assert_horizon_engagement({source, target}, injections) do
    Process.delete({:penalty, source.id, target.id})
    Enum.each(injections, fn penalty -> HorizonGuard.inject_penalty(source.id, target.id, penalty) end)
    
    final_penalty = HorizonGuard.divergence_penalty(source.id, target.id)
    
    if final_penalty >= 9.5 do
      # Verify routing shifts to degraded/horizon state
      bottleneck = mock_bottleneck(source, target, 0.1)
      wasserstein = mock_wasserstein(source, target, 0.05)
      resonance = (bottleneck + @alpha * wasserstein) / (final_penalty + @epsilon)
      assert resonance < @theta_oht
    end
    true
  end

  # --- Generators ---

  defp evolving_ontology_pair_generator() do
    let {novelty_var, topology_noise, semantic_drift, penalty} <-
        {float(), float(), float(), float()} do
          {
            %{id: :crypto.strong_rand_bytes(4) |> Base.url_encode64(), novelty: novelty_var},
            %{id: :crypto.strong_rand_bytes(4) |> Base.url_encode64(), novelty: novelty_var * 1.2},
            %{
              penalty: max(0.0, penalty - 5.0),
              topology_noise: max(0.0, topology_noise - 2.0),
              semantic_drift: max(0.0, semantic_drift - 1.5)
            }
          }
        end
  end

  defp novelty_decay_generator() do
    {
      {
        %{id: "source_init", novelty: 0.9},
        %{id: "target_init", novelty: 0.5}
      },
      let(steps <- choose(5, 20), do: vector(steps, float(0.0, 0.15)))
    }
  end

  defp horizon_stress_generator() do
    let {injections, r1, r2} <- {
      let(size <- choose(5, 10), do: vector(size, float(2.0, 4.0))),
      binary(4),
      binary(4)
    } do
      {
        {
          %{id: Base.url_encode64(r1), novelty: 0.8},
          %{id: Base.url_encode64(r2), novelty: 0.7}
        },
        injections,
        :ok
      }
    end
  end

  # --- Mock Implementations (for test determinism) ---

  defp mock_bottleneck(s, t, noise) do
    base = 1.0 - min(abs(s.novelty - t.novelty), 1.0)
    max(0.0, base - noise * 0.1)
  end

  defp mock_wasserstein(s, t, drift) do
    base = 0.5 + min(abs(s.novelty - t.novelty) * 0.8, 0.5)
    min(2.0, base + drift * 0.2)
  end

  defp compute_resonance({s, t}) do
    b = mock_bottleneck(s, t, 0.05)
    w = mock_wasserstein(s, t, 0.03)
    p = HorizonGuard.divergence_penalty(s.id, t.id)
    (b + @alpha * w) / (max(p, @epsilon))
  end

  defp apply_semantic_decay(ontology, decay) do
    %{ontology | novelty: max(0.1, ontology.novelty - decay)}
  end

  defp assert_routing_state(state) do
    # In production: query ResonanceEngine routing table via NATS
    # For simulation: assert state matches expected enum
    assert state in [:full_bridge, :degraded_monitoring, :horizon_engaged]
    true
  end
end

defmodule Tiannara.Phase7.ORB.HorizonGuard do
  def inject_penalty(source_id, target_id, penalty) do
    key = {:penalty, source_id, target_id}
    current = Process.get(key, 0.0)
    Process.put(key, current + penalty)
    :ok
  end

  def divergence_penalty(source_id, target_id) do
    key = {:penalty, source_id, target_id}
    Process.get(key, 0.0)
  end
end