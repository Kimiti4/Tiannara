defmodule IntegrationOPCTest do
  use ExUnit.Case, async: true
  doctest Tiannara.OPC.RealityCompiler

  test "OPC Reality Compiler can process events through the full pipeline" do
    # Create a sample event
    event = %{
      id: "test-event-1",
      type: "system_load",
      payload: %{value: 42, source: "test"},
      timestamp: System.system_time(:millisecond)
    }

    # Simulate the event processing pipeline manually
    # 1. Collect event
    # 2. Segment into causal chains
    events = [event]
    chains = Tiannara.OPC.RealityCompiler.CausalSegmenter.segment(events)
    
    # 3. Detect invariants
    invariants = Tiannara.OPC.RealityCompiler.InvariantDetector.detect(chains)
    
    # 4. Extract patterns
    patterns = Tiannara.OPC.RealityCompiler.PatternEngine.extract(chains)
    
    # 5. Compile rules
    rules = Tiannara.OPC.RealityCompiler.RuleCompiler.compile(patterns)

    # Verify that the pipeline produces results
    assert is_list(chains)
    assert is_list(invariants)
    assert is_list(patterns)
    assert is_list(rules)
    assert length(rules) > 0
  end

  test "OPC Reality Compiler can segment causal chains" do
    events = [
      %{id: "e1", type: "load_start", payload: %{}, timestamp: 1000},
      %{id: "e2", type: "load_end", payload: %{}, timestamp: 1001},
      %{id: "e3", type: "load_start", payload: %{}, timestamp: 2000}
    ]

    chains = Tiannara.OPC.RealityCompiler.CausalSegmenter.segment(events)
    assert is_list(chains)
    assert length(chains) > 0
  end

  test "OPC Reality Compiler can detect invariants" do
    events = [
      %{id: "e1", type: "load", payload: %{}, timestamp: 1000},
      %{id: "e2", type: "load", payload: %{}, timestamp: 1001},
      %{id: "e3", type: "load", payload: %{}, timestamp: 1002},
      %{id: "e4", type: "other", payload: %{}, timestamp: 1003}
    ]

    chains = [[Enum.at(events, 0), Enum.at(events, 1), Enum.at(events, 2)]]
    results = Tiannara.OPC.RealityCompiler.InvariantDetector.detect(chains)

    assert length(results) == 1
    assert results |> hd() |> Map.get(:invariants) |> Enum.member?("load")
  end

  test "OPC Reality Compiler can extract patterns" do
    events = [
      %{id: "e1", type: "load", payload: %{}, timestamp: 1000},
      %{id: "e2", type: "load", payload: %{}, timestamp: 1001},
      %{id: "e3", type: "load", payload: %{}, timestamp: 1002}
    ]

    chains = [[Enum.at(events, 0), Enum.at(events, 1), Enum.at(events, 2)]]
    patterns = Tiannara.OPC.RealityCompiler.PatternEngine.extract(chains)

    assert length(patterns) == 1
    pattern = hd(patterns)
    assert pattern.pattern_type in [:high_complexity, :low_complexity]
    assert is_number(pattern.strength)
  end

  test "OPC Reality Compiler can compile rules" do
    patterns = [
      %{
        pattern_type: :low_complexity,
        invariants: ["load"],
        strength: 0.5
      }
    ]

    rules = Tiannara.OPC.RealityCompiler.RuleCompiler.compile(patterns)
    assert length(rules) == 1

    rule = hd(rules)
    assert rule.id != nil
    assert rule.condition != nil
    assert rule.effect != nil
    assert is_number(rule.weight)
  end
end