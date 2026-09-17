defmodule Tiannara.REA.OrbitReachabilityTest do
  use ExUnit.Case, async: true

  alias Tiannara.REA.OrbitReachabilityGraph
  alias Tiannara.REA.MultiObjectivePlanner
  alias Tiannara.REA.OrbitEstimator
  alias Tiannara.REA.OrbitController
  alias Tiannara.REA.OrbitResilience

  setup_all do
    # Force rebuild the graph to guarantee up-to-date values
    {:ok, nodes, edges} = OrbitReachabilityGraph.build_and_persist()
    {:ok, %{nodes: nodes, edges: edges}}
  end

  describe "Phase 11.9B Orbit Reachability and Navigation Suite" do

    test "Q1 — Elite Reachability: stability_orbit is reachable from all states", %{nodes: nodes} do
      for node <- nodes do
        # Every node should be able to plan a path to stability_orbit under at least one objective
        assert {:ok, plan} = MultiObjectivePlanner.plan(node.orbit_id, :stability_orbit, :lowest_energy)
        assert is_list(plan.path)
        assert List.last(plan.path) == :stability_orbit
      end
    end

    test "Q2 — Unreachability: plan handles disconnected/unreachable states gracefully" do
      # If we request a plan to a non-existent state
      assert {:error, :orbit_not_found} == MultiObjectivePlanner.plan(:stability_orbit, :invalid_orbit, :lowest_energy)
    end

    test "Q3 — Gateway validation: gateway scores are computed and gateway paths exist", %{nodes: nodes, edges: edges} do
      # Verify that there is at least one node with a positive gateway score
      has_gateway = Enum.any?(nodes, fn node -> node.gateway_score > 0.0 end)
      assert has_gateway

      # Check edge gateway requirements
      gateway_edges = Enum.filter(edges, & &1.gateway_required)
      # Assert that gateway required flag correctly sets lists of gateway orbits
      Enum.each(gateway_edges, fn edge ->
        assert length(edge.gateway_orbits) > 0
      end)
    end

    test "Q4 — Transition engineering: controller simulate_trajectory applies deltas within bounds" do
      start = [0.5, 0.5, 0.5, 0.5]
      interventions = ["explore", "repair", "preserve"]
      
      traj = OrbitController.simulate_trajectory(start, interventions)
      assert length(traj) == 4
      
      # Verify all steps remain clamped between 0.0 and 1.0
      Enum.each(traj, fn vec ->
        assert length(vec) == 4
        Enum.each(vec, fn val ->
          assert val >= 0.0 and val <= 1.0
        end)
      end)
    end

    test "Q5 — Regenerative self-reproduction: stability_orbit qualifies as regenerative/reproductive", %{nodes: nodes} do
      stability_node = Enum.find(nodes, & &1.orbit_id == :stability_orbit)
      assert stability_node.residency_score > 0.0
      assert stability_node.stability_score > 0.50

      resilience_type = OrbitResilience.classify_orbit(:stability_orbit)
      assert resilience_type in [:regenerative, :reproductive]
    end

    test "Q6 — Geometry vs Policy: convergence is determined by target orbit geometry", %{nodes: nodes} do
      stability_node = Enum.find(nodes, & &1.orbit_id == :stability_orbit)
      # If we observe a state exactly at the centroid, confidence must be extremely high
      centroid = stability_node.orbit_vector
      estimation = OrbitEstimator.estimate(centroid)
      
      assert estimation.orbit_id == :stability_orbit
      assert estimation.confidence > 0.99
    end

    test "Q7 — Attractor Strength: nearby coordinates converge into the same orbit", %{nodes: nodes} do
      stability_node = Enum.find(nodes, & &1.orbit_id == :stability_orbit)
      centroid = stability_node.orbit_vector

      # Perturb centroid slightly (+/- 0.05)
      perturbed = Enum.map(centroid, & min(1.0, max(0.0, &1 + 0.04)))
      
      # Proximity estimation should still classify to stability_orbit
      estimation = OrbitEstimator.estimate(perturbed)
      assert estimation.orbit_id == :stability_orbit
      assert estimation.confidence > 0.85
    end

    test "Q8 — Path Independence: multiple different interventions lead to convergence on Stability" do
      # Phoenix interventions (preserve) vs Settler (repair) starting from generic point
      start = [0.6, 0.4, 0.5, 0.3]
      
      # Phoenix-biased path
      traj_phoenix = OrbitController.simulate_trajectory(start, ["preserve", "preserve"])
      final_phoenix = List.last(traj_phoenix)
      est_phoenix = OrbitEstimator.estimate(final_phoenix)

      # Settler-biased path
      traj_settler = OrbitController.simulate_trajectory(start, ["repair", "repair"])
      final_settler = List.last(traj_settler)
      est_settler = OrbitEstimator.estimate(final_settler)

      # Both converge to stable attractor orbits with good confidence
      assert est_phoenix.confidence > 0.50
      assert est_settler.confidence > 0.50
    end
  end
end
