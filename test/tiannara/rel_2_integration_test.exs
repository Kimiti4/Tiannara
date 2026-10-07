defmodule Tiannara.REL.REL2IntegrationTest do
  use ExUnit.Case
  require Logger

  alias Tiannara.OMCS.Engine, as: OMCSEngine
  alias Tiannara.ROS.ShardManager
  alias Tiannara.ROS.CivilizationSpawner
  alias Tiannara.ROS.EvolutionEngine
  alias Tiannara.REL.EconomyEngine
  alias Tiannara.REL.DiscoveryLedger
  alias Tiannara.REL.ProductionEngine
  alias Tiannara.REL.DiscoveryEngine
  alias Tiannara.REL.CivilizationFitness
  alias Tiannara.Core.WorldModel.Discovery
  alias Tiannara.OAVL.DiscoveryVerifier

  # Application is already started by mix test

  test "Production Test: Verify prediction and observation yields resources" do
    assert {:ok, :shard_prod} = ShardManager.spawn_shard(:shard_prod)
    assert {:ok, civ_id} = CivilizationSpawner.spawn_civilization(:shard_prod, "ProdCiv", [])
    OMCSEngine.register_civilization(civ_id)
    
    # Base Compute is 1000, Attention is 1000
    initial_budget = EconomyEngine.get_budget(civ_id)
    
    ProductionEngine.reward_prediction(civ_id, 0.95) # Should grant ~10 compute
    ProductionEngine.reward_observation(civ_id, true) # Should grant 5 attention
    
    new_budget = EconomyEngine.get_budget(civ_id)
    assert new_budget.compute > initial_budget.compute
    assert new_budget.attention > initial_budget.attention
  end

  test "Epistemic Mutation Test: Verify Fission mutates the Epistemic Genome" do
    assert {:ok, :shard_fiss_parent} = ShardManager.spawn_shard(:shard_fiss_parent)
    assert {:ok, parent_civ_id} = CivilizationSpawner.spawn_civilization(:shard_fiss_parent, "FissParent", [])
    OMCSEngine.register_civilization(parent_civ_id)
    
    {:ok, parent_ent} = Tiannara.Core.WorldModel.EntityRegistry.get_entity(parent_civ_id, :shard_fiss_parent)
    parent_genome = parent_ent.attributes.epistemic_genome

    # Trigger fission
    assert {:ok, child_a, child_b} = EvolutionEngine.fission(
      :shard_fiss_parent, parent_civ_id,
      :shard_fiss_a, :shard_fiss_b,
      "FissChildA", "FissChildB"
    )
    
    {:ok, ent_a} = Tiannara.Core.WorldModel.EntityRegistry.get_entity(child_a, :shard_fiss_a)
    {:ok, ent_b} = Tiannara.Core.WorldModel.EntityRegistry.get_entity(child_b, :shard_fiss_b)
    
    # Due to random mutations, they should not be strictly equal
    assert ent_a.attributes.epistemic_genome != parent_genome
    assert ent_b.attributes.epistemic_genome != parent_genome
    assert ent_a.attributes.epistemic_genome != ent_b.attributes.epistemic_genome
  end

  test "Quantum Leap Test: OAVL fails closed — quantum leap candidates are charged but never admitted without evidence" do
    assert {:ok, :shard_ql} = ShardManager.spawn_shard(:shard_ql)
    assert {:ok, civ_id} = CivilizationSpawner.spawn_civilization(:shard_ql, "QLCiv", [])
    OMCSEngine.register_civilization(civ_id)
    
    # Inject massive compute/attention so cost can never starve the attempts:
    # any rejection below is the OAVL validation gate, not the budget.
    assert :ok = EconomyEngine.inject(civ_id, %{compute: 500000, attention: 500000})
    
    # Force their genome to extreme novelty (max quantum leap chance = 10% per attempt)
    {:ok, ent} = Tiannara.Core.WorldModel.EntityRegistry.get_entity(civ_id, :shard_ql)
    mutated = %{ent.attributes.epistemic_genome | abstraction_bias: 1.0, novelty_seeking: 1.0}
    Tiannara.Core.WorldModel.EntityRegistry.update_entity(civ_id, %{attributes: Map.put(ent.attributes, :epistemic_genome, mutated)}, :shard_ql)

    budget_before = EconomyEngine.get_budget(civ_id)

    # 100 attempts: quantum leaps (2000/1000) and normal discoveries (100/50).
    # A fresh civilization owns no discoveries, so recombination never triggers.
    results = Enum.map(1..100, fn _ -> DiscoveryEngine.attempt_discovery(civ_id, :shard_ql) end)
    
    # Fail-closed boundary: no candidate reaches {:ok, _} without structural validation.
    refute Enum.any?(results, &match?({:ok, _}, &1))
    assert Enum.all?(results, &match?({:error, {:discovery_unvalidated, :missing_structural_evidence}}, &1))

    # Costs are still charged — each attempt pays before validation is attempted.
    budget_after = EconomyEngine.get_budget(civ_id)
    assert budget_before.compute - budget_after.compute >= 10_000
    assert budget_before.attention - budget_after.attention >= 5_000

    # Nothing was admitted to the ledger: funds and novelty do not substitute for evidence.
    known = DiscoveryLedger.get_known_discoveries(civ_id)
    refute Enum.any?(known, &String.starts_with?(&1.id, "disc_"))

    # Direct OAVL probe: an evidence-less candidate fails the evidence gate first;
    # only an evidence-bearing candidate reaches the (unavailable) validation provider.
    candidate = Discovery.new(%{id: "probe_ql", name: "QL probe", domain: :physics, originator_civ_id: civ_id})
    assert {:error, :missing_structural_evidence} = DiscoveryVerifier.evaluate(candidate)
    assert {:error, :oavl_validation_provider_unavailable} =
             DiscoveryVerifier.evaluate(Map.put(candidate, :evidence, ["exp_1"]))
  end

  test "Fitness Test: Verify successful civilizations score higher than stagnant ones" do
    assert {:ok, :shard_fit1} = ShardManager.spawn_shard(:shard_fit1)
    assert {:ok, :shard_fit2} = ShardManager.spawn_shard(:shard_fit2)
    
    assert {:ok, civ_winner} = CivilizationSpawner.spawn_civilization(:shard_fit1, "Winner", [])
    assert {:ok, civ_loser} = CivilizationSpawner.spawn_civilization(:shard_fit2, "Loser", [])
    OMCSEngine.register_civilization(civ_winner)
    OMCSEngine.register_civilization(civ_loser)
    
    # Loser drains resources to starving
    EconomyEngine.consume(civ_loser, %{energy: 900})
    
    # Winner discovers things
    disc = Discovery.new(%{id: "win_d1", name: "Agri", domain: :agriculture, originator_civ_id: civ_winner})
    DiscoveryLedger.register_discovery(civ_winner, disc)
    
    fit_winner = CivilizationFitness.calculate(civ_winner)
    fit_loser = CivilizationFitness.calculate(civ_loser)
    
    assert fit_winner > fit_loser
  end
end
