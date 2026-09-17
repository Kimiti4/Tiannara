defmodule Tiannara.Discovery.ContradictionAnalyzerTest do
  use ExUnit.Case, async: true
  alias Tiannara.Discovery.ContradictionAnalyzer

  describe "analyze/1" do
    test "classifies genuine contradictions" do
      conflicts = [%{id: "c1", description: "X is true vs X is false", severity: :high, domain: :knowledge, entity_ids: ["a", "b"]}]
      gaps = ContradictionAnalyzer.analyze(conflicts)
      assert length(gaps) == 1
      gap = hd(gaps)
      assert gap.severity == :high
      assert gap.classification == :direct
      assert gap.impact == 0.9
    end

    test "classifies ontology inconsistencies" do
      conflicts = [%{id: "c2", description: "Ontology definition mismatch for energy", severity: :medium, domain: :ontology, entity_ids: ["x"]}]
      gaps = ContradictionAnalyzer.analyze(conflicts)
      gap = hd(gaps)
      assert gap.classification == :contextual
      assert gap.impact == 0.4
    end

    test "classifies measurement errors" do
      conflicts = [%{id: "c3", description: "Sensor measurement discrepancy", severity: :low, domain: :observations, entity_ids: ["s1"]}]
      gaps = ContradictionAnalyzer.analyze(conflicts)
      gap = hd(gaps)
      assert gap.classification == :unknown
    end

    test "returns empty list for no conflicts" do
      assert ContradictionAnalyzer.analyze([]) == []
    end

    test "ranks by severity x impact" do
      conflicts = [%{id: "c1", description: "low", severity: :low, domain: :k, entity_ids: ["a"]},
        %{id: "c2", description: "critical", severity: :critical, domain: :k, entity_ids: ["a", "b", "c", "d", "e"]}]
      gaps = ContradictionAnalyzer.analyze(conflicts)
      assert hd(gaps).severity == :critical
    end
  end
end
