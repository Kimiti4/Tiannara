defmodule Tiannara.REL.EpistemicCapitalTest do
  use ExUnit.Case
  alias Tiannara.REL.EconomyEngine
  alias Tiannara.REL.DiscoveryLedger
  alias Tiannara.ROS.Registry, as: ROSRegistry

  setup do
    shard_id = :shard_ec_test
    civ_id = "lineage:ec_tester"
    
    # Start or clear processes
    # Because these are registered globally, we might need to be careful with state,
    # but since civ_id and shard_id are unique per test, we can just use the global processes.
    EconomyEngine.register_civilization(shard_id, civ_id)
    
    %{shard_id: shard_id, civ_id: civ_id}
  end

  test "granting and penalizing truth capital", %{civ_id: civ_id} do
    assert :ok = EconomyEngine.grant_truth_capital(civ_id, 100.0)
    budget = EconomyEngine.get_budget(civ_id)
    assert budget.truth_capital == 100.0
    
    assert :ok = EconomyEngine.penalize_truth_capital(civ_id, 30.0)
    budget2 = EconomyEngine.get_budget(civ_id)
    assert budget2.truth_capital == 70.0
  end
  
  test "granting influence capital", %{civ_id: civ_id} do
    assert :ok = EconomyEngine.grant_influence_capital(civ_id, 50.0)
    budget = EconomyEngine.get_budget(civ_id)
    assert budget.influence_capital == 50.0
  end

  test "trust score computation", %{civ_id: civ_id} do
    EconomyEngine.grant_truth_capital(civ_id, 100.0)
    EconomyEngine.grant_influence_capital(civ_id, 50.0)
    
    {:ok, trust_score} = EconomyEngine.compute_trust_score(civ_id)
    # trust_score = (100 * 1.5) + (50 * 0.5) = 150 + 25 = 175
    assert trust_score == 175.0
  end

  test "tick decay", %{civ_id: civ_id} do
    EconomyEngine.grant_truth_capital(civ_id, 100.0)
    EconomyEngine.grant_influence_capital(civ_id, 100.0)
    
    # Tick should decay them by 0.995
    EconomyEngine.tick(civ_id)
    
    # Need to sync state since tick is a cast
    :sys.get_state(Tiannara.REL.EconomyEngine)
    
    budget = EconomyEngine.get_budget(civ_id)
    assert_in_delta budget.truth_capital, 99.5, 0.001
    assert_in_delta budget.influence_capital, 99.5, 0.001
  end
end
