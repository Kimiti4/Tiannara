defmodule TiannaraRuntime.CCRTest do
  use ExUnit.Case, async: false

  alias TiannaraRuntime.CCR.{Reflection, Tracker}

  setup do
    if !Process.whereis(Tracker), do: start_supervised!(Tracker)
    :ok
  end

  test "reflection analyzer computes correct pattern classifications" do
    trace_graph = %{
      nodes: [
        %{id: "rule_stable", complexity: 0.2, throughput: 0.95, reversibility: 0.99},
        %{id: "rule_unstable", complexity: 0.9, throughput: 0.1, reversibility: 0.88}
      ],
      edges: [
        %{type: :causal_link, weight: 0.85}
      ],
      observers: [
        %{id: "obs_active", coherence: 0.9, entropy_pressure: 0.1}
      ]
    }

    ref = Reflection.reflect(trace_graph)
    
    assert Enum.any?(ref.stable_patterns, &(&1.rule_id == "rule_stable"))
    assert Enum.any?(ref.unstable_patterns, &(&1.rule_id == "rule_unstable"))
    assert ref.topology_insights.manifold_density == 0.25
    assert Enum.any?(ref.observer_dynamics, &(&1.observer_id == "obs_active" and &1.behavior_profile == :syntropic_stabilizer))
  end

  test "tracker stores traces and updates guidance rules" do
    unstable_trace = %{
      nodes: [
        %{id: "rule_a", complexity: 0.9, throughput: 0.1, reversibility: 0.85}
      ],
      edges: [],
      observers: []
    }

    assert {:ok, _reflection} = Tracker.record_trace(unstable_trace)

    assert {:ok, reflections} = Tracker.get_reflections()
    assert length(reflections) > 0

    assert {:ok, guidance} = Tracker.get_guidance()
    assert length(guidance) > 0
    assert Enum.any?(guidance, &(&1.rule_type in [:enforce_kolmogorov_ceiling, :mandate_conservation_shield]))
  end
end
