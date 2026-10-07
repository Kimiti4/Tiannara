defmodule Tiannara.ACM.REL6IntegrationTest do
  use ExUnit.Case
  require Logger

  alias Tiannara.ROS.ShardManager
  alias Tiannara.ROS.CivilizationSpawner
  alias Tiannara.OMCS.Engine, as: OMCSEngine
  alias Tiannara.REL.EconomyEngine
  alias Tiannara.REL.DiscoveryLedger
  alias Tiannara.REL.DiscoveryEngine
  alias Tiannara.Core.WorldModel.EntityRegistry

  test "Predator Test: Verify targeted ACM traps drain resources if genomes are weak" do
    assert {:ok, :shard_pred} = ShardManager.spawn_shard(:shard_pred)
    assert {:ok, civ_id} = CivilizationSpawner.spawn_civilization(:shard_pred, "PredCiv", [])
    OMCSEngine.register_civilization(civ_id)
    
    # Inject initial resources
    EconomyEngine.inject(civ_id, %{compute: 2000, attention: 2000})

    # Mutate genome to be highly susceptible to Pattern Mirage (High Novelty, Low Statistical Reasoning)
    {:ok, ent} = EntityRegistry.get_entity(civ_id, :shard_pred)
    mutated = %{ent.attributes.epistemic_genome | novelty_seeking: 0.95, statistical_reasoning: 0.1}
    EntityRegistry.update_entity(civ_id, %{attributes: Map.put(ent.attributes, :epistemic_genome, mutated)}, :shard_pred)
    
    budget_before = EconomyEngine.get_budget(civ_id)

    # Attack with Predator
    result = Tiannara.ACM.EpistemicPredator.attack(:shard_pred, civ_id, mutated)
    assert {:hit, :pattern_mirage, 500} = result
    
    # Verify resources drained
    budget = EconomyEngine.get_budget(civ_id)
    assert budget.compute == budget_before.compute - 500
    assert budget.attention == budget_before.attention - 500

    # Mutate to resist it
    mutated_resilient = %{mutated | statistical_reasoning: 0.9}
    EntityRegistry.update_entity(civ_id, %{attributes: Map.put(ent.attributes, :epistemic_genome, mutated_resilient)}, :shard_pred)
    
    budget_before2 = EconomyEngine.get_budget(civ_id)
    result2 = Tiannara.ACM.EpistemicPredator.attack(:shard_pred, civ_id, mutated_resilient)
    assert {:resisted, :pattern_mirage} = result2
    
    # Verify no more resources drained
    budget2 = EconomyEngine.get_budget(civ_id)
    assert budget2.compute == budget_before2.compute
  end

  test "Disease Test: Verify Epistemic Diseases spread and consume compute exponentially" do
    assert {:ok, :shard_dis} = ShardManager.spawn_shard(:shard_dis)
    assert {:ok, civ_id} = CivilizationSpawner.spawn_civilization(:shard_dis, "DisCiv", [])
    OMCSEngine.register_civilization(civ_id)
    
    # Infect
    disease = Tiannara.ACM.EpistemicDisease.infect(civ_id)
    DiscoveryLedger.register_discovery(civ_id, disease)
    
    # Progress without cure
    {:ok, ent} = EntityRegistry.get_entity(civ_id, :shard_dis)
    # Set to definitely not cure (e.g. low empiricism for Conspiracy Ontology)
    mutated = %{ent.attributes.epistemic_genome | empiricism_bias: 0.1, formalism_bias: 0.1, abstraction_bias: 0.5, contradiction_tolerance: 0.5, causal_reasoning: 0.5}
    EntityRegistry.update_entity(civ_id, %{attributes: Map.put(ent.attributes, :epistemic_genome, mutated)}, :shard_dis)
    
    {:progressed, worse_disease} = Tiannara.ACM.EpistemicDisease.progress_disease(disease, mutated)
    assert worse_disease.complexity_cost == disease.complexity_cost * 2
    
    # Progress with cure
    # Force a disease we know we can cure, e.g. Conspiracy Ontology (needs high empiricism)
    known_disease = %Tiannara.Core.WorldModel.Discovery{id: "dis_test", name: "Conspiracy Ontology", complexity_cost: 100, domain: :cognition, originator_civ_id: civ_id}
    mutated_cure = %{mutated | empiricism_bias: 0.9}
    
    assert {:cured, "dis_test"} = Tiannara.ACM.EpistemicDisease.progress_disease(known_disease, mutated_cure)
  end

  test "Verification Test: OAVL rejects unvalidated discoveries instead of assigning fabricated stability" do
    assert {:ok, :shard_ver} = ShardManager.spawn_shard(:shard_ver)
    assert {:ok, civ_id} = CivilizationSpawner.spawn_civilization(:shard_ver, "VerCiv", [])
    OMCSEngine.register_civilization(civ_id)
    
    # Massive funds so no attempt starves: every rejection below is the OAVL gate.
    assert :ok = EconomyEngine.inject(civ_id, %{compute: 500000, attention: 500000})
    {:ok, ent} = EntityRegistry.get_entity(civ_id, :shard_ver)
    mutated = %{ent.attributes.epistemic_genome | abstraction_bias: 1.0, novelty_seeking: 1.0}
    EntityRegistry.update_entity(civ_id, %{attributes: Map.put(ent.attributes, :epistemic_genome, mutated)}, :shard_ver)
    
    results = Enum.map(1..100, fn _ -> DiscoveryEngine.attempt_discovery(civ_id, :shard_ver) end)

    # Fail-closed: verification never fabricates a result, so nothing is admitted
    # and no stability value is produced by the verification path.
    refute Enum.any?(results, &match?({:ok, _}, &1))
    assert Enum.all?(results, &match?({:error, {:discovery_unvalidated, :missing_structural_evidence}}, &1))

    # Direct OAVL probe: identity passes, then the evidence gate fails for an
    # evidence-less candidate; with evidence the (unavailable) provider gate fails.
    # Neither path can return a stability/confidence value it does not have.
    candidate = Tiannara.Core.WorldModel.Discovery.new(%{id: "probe_ver", name: "Verification probe", domain: :physics, originator_civ_id: civ_id})
    assert {:error, :missing_structural_evidence} = Tiannara.OAVL.DiscoveryVerifier.evaluate(candidate)
    assert {:error, :oavl_validation_provider_unavailable} =
             Tiannara.OAVL.DiscoveryVerifier.evaluate(Map.put(candidate, :evidence, ["exp_1"]))

    # Nothing reached the ledger, so no discovery carries a verification-assigned stability.
    known = DiscoveryLedger.get_known_discoveries(civ_id)
    refute Enum.any?(known, &String.starts_with?(&1.id, "disc_"))

    # The struct default is a fixed 1.0 — creating a discovery never randomizes stability.
    probe = Tiannara.Core.WorldModel.Discovery.new(%{id: "probe_stab", name: "Stability probe", domain: :physics, originator_civ_id: civ_id})
    assert probe.stability == 1.0
  end

  test "Quarantine Test: OED never fabricates quarantine decisions without an evidence-backed risk provider" do
    assert {:ok, :shard_quar} = ShardManager.spawn_shard(:shard_quar)
    assert {:ok, civ_id} = CivilizationSpawner.spawn_civilization(:shard_quar, "QuarCiv", [])
    OMCSEngine.register_civilization(civ_id)
    
    # Craft a discovery whose name would trip any danger heuristic
    dangerous = Tiannara.Core.WorldModel.Discovery.new(%{
      id: "dang_1",
      name: "Infinite Recombination Paradox",
      domain: :cognition,
      originator_civ_id: civ_id
    })
    
    # 100 evaluations: without an evidence-backed adoption-risk provider there is
    # no decision to return — neither :safe nor a random 10% :quarantine.
    results = Enum.map(1..100, fn _ -> Tiannara.OED.AdoptionEvaluator.evaluate(civ_id, :shard_quar, dangerous) end)
    
    assert results == List.duplicate({:error, :adoption_risk_provider_unavailable}, 100)
    refute Enum.any?(results, &match?({:quarantine, _}, &1))
    
    # The shard stays unquarantined: quarantine requires a provider decision,
    # not a chance roll on the discovery's name.
    {:ok, ent} = EntityRegistry.get_entity(civ_id, :shard_quar)
    refute Map.get(ent.attributes, :quarantined, false)
  end
end
