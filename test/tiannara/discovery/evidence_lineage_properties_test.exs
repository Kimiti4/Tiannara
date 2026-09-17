defmodule Tiannara.Discovery.EvidenceLineagePropertiesTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Tiannara.Discovery.{EvidenceIntegrator, DiscoveryLineage, Discovery}
  alias Tiannara.Discovery.Domain.{DiscoveryResult, KnowledgeGap}

  describe "EvidenceIntegrator invariants" do
    property "integrate always returns valid outcome" do
      check all outcome <- member_of([:supported, :falsified, :inconclusive]),
                delta <- float(min: -0.5, max: 0.5) do
        result = DiscoveryResult.new(%{experiment_id: "exp_prop", hypothesis_id: "hyp_prop",
          outcome: outcome, evidence: [%{type: :observation, value: delta}],
          confidence_delta: delta, posterior: 0.5 + delta})
        [eval] = EvidenceIntegrator.integrate([result])
        assert eval.outcome in [:supported, :falsified, :inconclusive]
        assert eval.experiment_id == "exp_prop"
        assert eval.hypothesis_id == "hyp_prop"
      end
    end

    property "compute_outcome is deterministic" do
      check all results <- list_of(
                member_of([:supported, :falsified, :inconclusive])
                |> map(fn o -> DiscoveryResult.new(%{experiment_id: "e1", hypothesis_id: "h1",
                     outcome: o, evidence: [], confidence_delta: 0.0, posterior: 0.5}) end),
                min_length: 0, max_length: 10) do
        outcome1 = EvidenceIntegrator.compute_outcome(results)
        outcome2 = EvidenceIntegrator.compute_outcome(results)
        assert outcome1 == outcome2
        assert outcome1 in [:supported, :falsified, :inconclusive]
      end
    end

    property "prepare_promotion never contains :knowledge_coordinator call" do
      check all delta <- float(min: -0.5, max: 0.5) do
        result = DiscoveryResult.new(%{experiment_id: "e1", hypothesis_id: "h1",
          outcome: :supported, evidence: [%{value: delta}],
          confidence_delta: delta, posterior: 0.5 + delta})
        payload = EvidenceIntegrator.prepare_promotion(result, %{confidence: 0.5})
        refute Map.has_key?(payload, :__kc_call__)
        assert payload.type == :evidence_promotion
        assert payload.source == :discovery_engine
      end
    end

    property "validate_result is consistent" do
      check all has_exp_id <- boolean(),
                has_hyp_id <- boolean(),
                outcome <- member_of([:supported, :falsified, :inconclusive, :unknown]) do
        attrs = %{evidence: []}
        attrs = if has_exp_id, do: Map.put(attrs, :experiment_id, "e1"), else: attrs
        attrs = if has_hyp_id, do: Map.put(attrs, :hypothesis_id, "h1"), else: attrs
        attrs = Map.put(attrs, :outcome, outcome)
        result = struct(DiscoveryResult, DiscoveryResult.new(attrs) |> Map.from_struct())
        validation = EvidenceIntegrator.validate_result(result)
        if has_exp_id and has_hyp_id and outcome in [:supported, :falsified, :inconclusive] do
          assert validation == :ok
        else
          assert match?({:error, _}, validation)
        end
      end
    end
  end

  describe "DiscoveryLineage invariants" do
    property "trace never returns nil" do
      check all domain <- member_of([:epistemic_consistency, :evidence_quality, :knowledge_freshness, :provenance]) do
        gap = KnowledgeGap.new(%{domain: domain, description: "prop test",
          severity: :medium, estimated_impact: 0.5, source: :epistemic_integrity})
        disc = Discovery.from_gap(gap)
        lineage = DiscoveryLineage.trace(disc)
        assert is_list(lineage)
      end
    end

    property "provenance_tree is self-consistent" do
      check all _ <- integer(1..5) do
        gap = KnowledgeGap.new(%{domain: :test, description: "tree prop",
          severity: :low, estimated_impact: 0.3, source: :epistemic_integrity})
        disc = Discovery.from_gap(gap)
        tree = DiscoveryLineage.provenance_tree(disc)
        assert tree.discovery_id == disc.id
        assert tree.root.event == :discovery_created
        assert tree.root.from_gap == disc.gap.id
        assert is_binary(tree.integrity_hash)
        assert byte_size(tree.integrity_hash) == 64
      end
    end

    property "verify_integrity is idempotent" do
      check all _ <- integer(1..5) do
        gap = KnowledgeGap.new(%{domain: :test, description: "integrity prop",
          severity: :low, estimated_impact: 0.3, source: :epistemic_integrity})
        disc = Discovery.from_gap(gap)
        assert DiscoveryLineage.verify_integrity(disc) == DiscoveryLineage.verify_integrity(disc)
      end
    end
  end
end
