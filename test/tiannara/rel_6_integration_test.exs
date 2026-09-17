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

  test "Verification Test: Verify unstable discoveries pass through OAVL but receive low stability" do
    assert {:ok, :shard_ver} = ShardManager.spawn_shard(:shard_ver)
    assert {:ok, civ_id} = CivilizationSpawner.spawn_civilization(:shard_ver, "VerCiv", [])
    OMCSEngine.register_civilization(civ_id)
    
    # Quantum Leap gets low stability initially (0.1 - 0.5)
    EconomyEngine.inject(civ_id, %{compute: 5000, attention: 5000})
    {:ok, ent} = EntityRegistry.get_entity(civ_id, :shard_ver)
    mutated = %{ent.attributes.epistemic_genome | abstraction_bias: 1.0, novelty_seeking: 1.0}
    EntityRegistry.update_entity(civ_id, %{attributes: Map.put(ent.attributes, :epistemic_genome, mutated)}, :shard_ver)
    
    # Loop until Quantum Leap
    results = Enum.map(1..100, fn _ -> DiscoveryEngine.attempt_discovery(civ_id, :shard_ver) end)
    ql = Enum.find(results, fn 
      {:ok, %{id: "disc_ql_" <> _}} -> true
      _ -> false
    end)
    
    assert {:ok, ql_disc} = ql
    assert ql_disc.stability < 0.8
  end

  test "Quarantine Test: Verify OED quarantines highly dangerous shards" do
    assert {:ok, :shard_quar} = ShardManager.spawn_shard(:shard_quar)
    assert {:ok, civ_id} = CivilizationSpawner.spawn_civilization(:shard_quar, "QuarCiv", [])
    OMCSEngine.register_civilization(civ_id)
    
    # Craft a dangerous discovery
    dangerous = Tiannara.Core.WorldModel.Discovery.new(%{
      id: "dang_1",
      name: "Infinite Recombination Paradox",
      domain: :cognition,
      originator_civ_id: civ_id
    })
    
    # Keep evaluating until it hits the 10% quarantine chance
    results = Enum.map(1..100, fn _ -> Tiannara.OED.AdoptionEvaluator.evaluate(civ_id, :shard_quar, dangerous) end)
    
    assert Enum.any?(results, fn res -> res == {:quarantine, "dang_1"} end)
    
    # Verify entity is quarantined
    {:ok, ent} = EntityRegistry.get_entity(civ_id, :shard_quar)
    assert ent.attributes.quarantined == true
  end
end
