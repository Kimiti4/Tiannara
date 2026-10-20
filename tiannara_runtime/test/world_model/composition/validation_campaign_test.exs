defmodule TiannaraRuntime.Composition.ValidationCampaignTest do
  use ExUnit.Case, async: false

  alias TiannaraRuntime.WorldModel.Composition.{
    ComposedWorldModel, DomainInterface, SharedVariable, SynchronizationRule,
    WorldGraph, WorldNode, WorldEdge, CompositionEvidence, CompositionCertificate,
    InterfaceConstraint
  }

  alias TiannaraRuntime.WorldModel.Composition.Engines.{
    InterfaceRegistry, SharedVariableResolver, SynchronizationEngine,
    WorldGraphBuilder, ConsistencyVerificationEngine, CompositionArchaeology,
    MathVerificationEngine, CompositionEngine
  }

  @moduletag :campaign

  defp sample_models do
    [
      %{world_model_id: "wm_domain_a", name: "Domain A", status: :operational},
      %{world_model_id: "wm_domain_b", name: "Domain B", status: :operational}
    ]
  end

  defp sample_domain_definitions do
    [
      {"wm_domain_a", "wm_domain_b", ["temperature", "pressure"], :bidirectional,
       priority: 1, constraints: [range: "temperature in [0, 100]"]}
    ]
  end

  describe "C17.6.95.1 — Struct Validation" do
    test "ComposedWorldModel has required fields" do
      cwm = %ComposedWorldModel{name: "test", parent_model_ids: ["wm1"]}
      assert cwm.name == "test"
      assert cwm.parent_model_ids == ["wm1"]
    end

    test "DomainInterface validates fields" do
      di = %DomainInterface{source_domain: "a", target_domain: "b",
        shared_variables: ["x"], direction: :bidirectional}
      assert di.direction == :bidirectional
      assert di.shared_variables == ["x"]
    end

    test "SharedVariable has domain mappings" do
      sv = %SharedVariable{name: "temperature",
        domain_mappings: %{"a" => "temp_a", "b" => "temp_b"}}
      assert sv.name == "temperature"
      assert sv.domain_mappings["a"] == "temp_a"
    end

    test "SynchronizationRule validates mode" do
      sr = %SynchronizationRule{source_model: "a", target_model: "b",
        variable: "x", mode: :discrete}
      assert sr.mode == :discrete
    end

    test "WorldGraph has nodes and edges" do
      wg = %WorldGraph{nodes: [], edges: []}
      assert wg.nodes == []
      assert wg.edges == []
    end

    test "WorldNode validates type" do
      wn = %WorldNode{node_id: "wn_test", type: :world_model, label: "test"}
      assert wn.type == :world_model
    end

    test "WorldEdge validates type" do
      we = %WorldEdge{source_id: "a", target_id: "b", type: :dependency}
      assert we.type == :dependency
    end

    test "CompositionEvidence has evidence_id" do
      ce = %CompositionEvidence{composition_id: "cw_test"}
      assert ce.composition_id == "cw_test"
    end

    test "CompositionCertificate validates overall" do
      cc = %CompositionCertificate{composition_id: "cw_test", overall: :pass}
      assert cc.overall == :pass
    end

    test "InterfaceConstraint validates type" do
      ic = %InterfaceConstraint{interface_id: "di_test", type: :range, expression: "x in [0,1]"}
      assert ic.type == :range
    end
  end

  describe "C17.6.95.2 — ID Generation" do
    test "ComposedWorldModel generates cw_ prefix" do
      id = ComposedWorldModel.generate_id(%{name: "test"})
      assert String.starts_with?(id, "cw_")
      assert String.length(id) == 67
    end

    test "DomainInterface generates di_ prefix" do
      id = DomainInterface.generate_id(%{source_domain: "a", target_domain: "b"})
      assert String.starts_with?(id, "di_")
    end

    test "SharedVariable generates sv_ prefix" do
      id = SharedVariable.generate_id(%{name: "temp"})
      assert String.starts_with?(id, "sv_")
    end

    test "SynchronizationRule generates sr_ prefix" do
      id = SynchronizationRule.generate_id(%{source_model: "a"})
      assert String.starts_with?(id, "sr_")
    end

    test "WorldGraph generates wg_ prefix" do
      id = WorldGraph.generate_id(%{nodes: []})
      assert String.starts_with?(id, "wg_")
    end

    test "WorldEdge generates we_ prefix" do
      id = WorldEdge.generate_id(%{source_id: "a", target_id: "b", type: :dependency})
      assert String.starts_with?(id, "we_")
    end

    test "CompositionCertificate generates cc_ prefix" do
      id = CompositionCertificate.generate_id(%{composition_id: "cw_test"})
      assert String.starts_with?(id, "cc_")
    end

    test "InterfaceConstraint generates ic_ prefix" do
      id = InterfaceConstraint.generate_id(%{interface_id: "di_test", type: :range})
      assert String.starts_with?(id, "ic_")
    end

    test "IDs are deterministic" do
      id1 = ComposedWorldModel.generate_id(%{name: "test"})
      id2 = ComposedWorldModel.generate_id(%{name: "test"})
      assert id1 == id2
    end
  end

  describe "C17.6.95.3 — Interface Registry" do
    test "register creates domain interfaces" do
      models = sample_models()
      {:ok, interfaces} = InterfaceRegistry.register(models, sample_domain_definitions())
      assert length(interfaces) == 1
      assert hd(interfaces).source_domain == "wm_domain_a"
      assert hd(interfaces).direction == :bidirectional
    end

    test "validate checks model existence" do
      models = sample_models()
      {:ok, interfaces} = InterfaceRegistry.register(models, sample_domain_definitions())
      model_ids = Enum.map(models, & &1.world_model_id)
      assert {:ok, _} = InterfaceRegistry.validate(interfaces, model_ids)
    end

    test "validate returns error for unknown model" do
      {:ok, interfaces} = InterfaceRegistry.register(sample_models(), [
        {"unknown", "wm_domain_b", ["x"], :source_to_target, []}
      ])
      assert {:error, errors} = InterfaceRegistry.validate(interfaces, ["wm_domain_b"])
      assert length(errors) == 1
    end

    test "find_by_domain returns matching interfaces" do
      {:ok, interfaces} = InterfaceRegistry.register(sample_models(), sample_domain_definitions())
      found = InterfaceRegistry.find_by_domain(interfaces, "wm_domain_a")
      assert length(found) == 1
    end
  end

  describe "C17.6.95.4 — Shared Variable Resolution" do
    test "resolve creates shared variables from interfaces" do
      {:ok, interfaces} = InterfaceRegistry.register(sample_models(), sample_domain_definitions())
      {:ok, variables} = SharedVariableResolver.resolve(interfaces)
      assert length(variables) == 2
      names = Enum.map(variables, & &1.name)
      assert "temperature" in names
      assert "pressure" in names
    end

    test "detect_conflict identifies mismatched values" do
      sv = %SharedVariable{name: "temp", resolution_strategy: :priority}
      resolved = SharedVariableResolver.detect_conflict(sv, %{"a" => 10, "b" => 20})
      assert resolved.conflict == true
    end

    test "detect_conflict resolves matching values" do
      sv = %SharedVariable{name: "temp", resolution_strategy: :priority}
      resolved = SharedVariableResolver.detect_conflict(sv, %{"a" => 10, "b" => 10})
      assert resolved.conflict == false
      assert resolved.resolved_value == 10
    end
  end

  describe "C17.6.95.5 — Synchronization Engine" do
    test "derive creates sync rules from interfaces" do
      {:ok, interfaces} = InterfaceRegistry.register(sample_models(), sample_domain_definitions())
      {:ok, variables} = SharedVariableResolver.resolve(interfaces)
      {:ok, rules} = SynchronizationEngine.derive(interfaces, variables)
      assert length(rules) == 2
    end

    test "validate_temporal checks compatibility" do
      {:ok, interfaces} = InterfaceRegistry.register(sample_models(), sample_domain_definitions())
      {:ok, variables} = SharedVariableResolver.resolve(interfaces)
      {:ok, rules} = SynchronizationEngine.derive(interfaces, variables)
      modes = %{"wm_domain_a" => :discrete, "wm_domain_b" => :discrete}
      assert {:ok, _} = SynchronizationEngine.validate_temporal(rules, modes)
    end

    test "sync transfers state between models" do
      rule = %SynchronizationRule{source_model: "a", target_model: "b",
        variable: "x", mode: :discrete}
      assert {:ok, _, _} = SynchronizationEngine.sync(rule, %{x: 42}, %{x: 0})
    end
  end

  describe "C17.6.95.6 — World Graph Builder" do
    test "build creates graph with nodes and edges" do
      models = sample_models()
      {:ok, interfaces} = InterfaceRegistry.register(models, sample_domain_definitions())
      {:ok, variables} = SharedVariableResolver.resolve(interfaces)
      {:ok, sync_rules} = SynchronizationEngine.derive(interfaces, variables)
      {:ok, graph} = WorldGraphBuilder.build(models, interfaces, variables, sync_rules)
      assert String.starts_with?(graph.graph_id, "wg_")
      assert length(graph.nodes) >= 2
    end

    test "detect_cycles returns ok for acyclic graph" do
      models = sample_models()
      {:ok, interfaces} = InterfaceRegistry.register(models, sample_domain_definitions())
      {:ok, variables} = SharedVariableResolver.resolve(interfaces)
      {:ok, sync_rules} = SynchronizationEngine.derive(interfaces, variables)
      {:ok, graph} = WorldGraphBuilder.build(models, interfaces, variables, sync_rules)
      assert {:ok, _} = WorldGraphBuilder.detect_cycles(graph)
    end
  end

  describe "C17.6.95.7 — Consistency Verification" do
    test "verify passes for valid graph" do
      models = sample_models()
      {:ok, interfaces} = InterfaceRegistry.register(models, sample_domain_definitions())
      {:ok, variables} = SharedVariableResolver.resolve(interfaces)
      {:ok, sync_rules} = SynchronizationEngine.derive(interfaces, variables)
      {:ok, graph} = WorldGraphBuilder.build(models, interfaces, variables, sync_rules)
      assert {:ok, report} = ConsistencyVerificationEngine.verify(graph)
      assert report.overall == :pass
    end
  end

  describe "C17.6.95.8 — Archaeology" do
    test "record creates composition evidence" do
      composition = %ComposedWorldModel{
        composition_id: "cw_test", parent_model_ids: ["wm1"],
        interfaces: [], sync_rules: []
      }
      {:ok, evidence} = CompositionArchaeology.record(composition)
      assert String.starts_with?(evidence.evidence_id, "ce_")
    end

    test "record_replay appends attempt" do
      evidence = %CompositionEvidence{composition_id: "cw_test", replay_attempts: []}
      updated = CompositionArchaeology.record_replay(evidence, "fp_abc", "fp_abc", true)
      assert length(updated.replay_attempts) == 1
    end

    test "verify_replay succeeds with verified attempt" do
      evidence = %CompositionEvidence{composition_id: "cw_test",
        replay_attempts: [%{verified: true}]}
      assert {:ok, :replay_verified} = CompositionArchaeology.verify_replay(evidence, nil)
    end
  end

  describe "C17.6.95.9 — Math Verification" do
    test "verify passes for valid graph" do
      graph = %WorldGraph{graph_id: "wg_test", nodes: [], edges: []}
      assert {:ok, proof, _details} = MathVerificationEngine.verify(graph)
      assert String.length(proof) > 0
    end

    test "check equation consistency" do
      graph = %WorldGraph{graph_id: "wg_test", nodes: [], edges: []}
      result = MathVerificationEngine.verify_equation_consistency(graph)
      assert result.status == :pass
    end

    test "check causal consistency" do
      graph = %WorldGraph{graph_id: "wg_test", nodes: [], edges: []}
      result = MathVerificationEngine.verify_causal_consistency(graph)
      assert result.status == :pass
    end
  end

  describe "C17.6.95.10 — Full Composition Pipeline" do
    test "end-to-end composition" do
      models = sample_models()
      defs = sample_domain_definitions()
      assert {:ok, composed, certificate} = CompositionEngine.compose(models, defs)
      assert String.starts_with?(composed.composition_id, "cw_")
      assert String.starts_with?(composed.replay_fingerprint, "fp_")
      assert certificate.overall == :pass
      assert length(composed.interfaces) == 1
    end

    test "replay verification" do
      models = sample_models()
      defs = sample_domain_definitions()
      {:ok, composed, _cert} = CompositionEngine.compose(models, defs)
      assert {:ok, :replay_verified, _} = CompositionEngine.replay(composed)
    end

    test "composition metadata is complete" do
      models = sample_models()
      defs = sample_domain_definitions()
      {:ok, composed, _cert} = CompositionEngine.compose(models, defs)
      assert composed.shared_variables != nil
      assert composed.sync_rules != nil
      assert composed.world_graph != nil
    end
  end
end
