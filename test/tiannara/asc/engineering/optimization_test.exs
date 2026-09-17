defmodule Tiannara.ASC.Engineering.OptimizationTest do
  use ExUnit.Case, async: false

  alias Tiannara.ASC.Engineering.OptimizationEngine

  setup do
    case OptimizationEngine.start_link([]) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end
    :ok
  end

  test "optimizes a design and returns scores" do
    design = %{
      id: "test_design",
      components: [%{id: "core", name: "Core"}],
      constraints: %{max_latency_ms: 500, availability_target: 0.99, safety_critical: true}
    }

    {:ok, optimized} = OptimizationEngine.optimize(design)

    assert Map.has_key?(optimized, :optimization_scores)
    assert Map.has_key?(optimized, :composite_score)
    assert optimized.composite_score >= 0.0
    assert optimized.composite_score <= 1.0
  end

  test "identifies bottlenecks" do
    design = %{id: "test", components: [], constraints: %{}}

    {:ok, optimized} = OptimizationEngine.optimize(design)
    assert is_list(optimized.bottlenecks)
  end

  test "pareto front returns non-dominated designs" do
    designs = [
      %{id: "a", components: [%{id: "x"}], constraints: %{max_latency_ms: 100}},
      %{id: "b", components: [%{id: "y"}], constraints: %{max_latency_ms: 200}},
      %{id: "c", components: [%{id: "z"}], constraints: %{max_latency_ms: 300}}
    ]

    {:ok, front} = OptimizationEngine.pareto_front(designs)
    assert is_list(front)
    assert length(front) >= 1
  end
end
