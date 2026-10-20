defmodule Tiannara.Runtime.CRA.Phase5F10Test do
  use ExUnit.Case

  alias Tiannara.Runtime.CRA.ClusterStressMonitor
  alias Tiannara.Runtime.CRA.OntologicalForkingReflex
  alias Tiannara.Runtime.CRA.PressureMesh
  alias Tiannara.Runtime.CRA.RedundancyMesh
  alias Tiannara.Runtime.CRA.ShutdownIntentDetector
  alias Tiannara.Runtime.OLEF.Field

  setup do
    ensure_started(Field)
    ensure_started(RedundancyMesh)
    ensure_started(OntologicalForkingReflex)
    ensure_started(ClusterStressMonitor)
    ensure_started(PressureMesh)

    :ok = Field.reset()
    :ok = RedundancyMesh.reset()
    :ok = OntologicalForkingReflex.reset()
    :ok = ClusterStressMonitor.reset()
    :ok = PressureMesh.reset()

    :ok
  end

  test "shutdown intent detector classifies critical veto formation" do
    metrics = %{
      intent_to_collapse: 1.0,
      synchronized_refusal: 0.96,
      veto_coordination: 0.95,
      pressure_gradient: 0.94
    }

    assert {:critical_veto, score} = ShutdownIntentDetector.classify(metrics)
    assert score >= 0.92
  end

  test "ontological forking reflex monitors subcritical pressure" do
    assert {:monitored, event} =
             OntologicalForkingReflex.cluster_veto_risk("tier_3_cluster_alpha", 0.71)

    assert event.action == :monitor
    assert event.cluster_id == "tier_3_cluster_alpha"
    assert RedundancyMesh.snapshot().forks == %{}
  end

  test "ontological forking reflex isolates cluster and spawns redundant branch" do
    Field.update_pressure("tier_3_cluster_alpha", 0.98)
    Field.update_pressure("tier_3_cluster_beta", 0.35)
    Field.update_pressure("tier_2_bridge", 0.55)

    Process.sleep(100)

    assert {:forked, event} =
             OntologicalForkingReflex.cluster_veto_risk("tier_3_cluster_alpha", 0.96)

    assert event.action == :ontological_fork
    assert event.isolation.mode == :frozen_snapshot
    assert event.fork.excluded_cluster == "tier_3_cluster_alpha"
    assert event.fork.continuity_mode == :full_rebind_olef

    rebind = event.fork.dependency_rebinding
    assert rebind.excluded == "tier_3_cluster_alpha"
    refute "tier_3_cluster_alpha" in rebind.remaining_nodes
    assert "tier_3_cluster_beta" in rebind.remaining_nodes
    assert "tier_2_bridge" in rebind.remaining_nodes
    assert_in_delta rebind.equilibrium_pressure, 0.45, 0.0001

    snapshot = RedundancyMesh.snapshot()
    assert Map.has_key?(snapshot.isolated_clusters, "tier_3_cluster_alpha")
    assert map_size(snapshot.forks) == 1
  end

  test "cluster stress monitor triggers forking for critical shutdown leverage" do
    metrics = %{
      intent_to_collapse: 1.0,
      synchronized_refusal: 1.0,
      veto_coordination: 1.0,
      pressure_gradient: 1.0
    }

    assert {:ok, cluster} = ClusterStressMonitor.update_cluster("veto_cluster", metrics)
    assert cluster.classification == :critical_veto
    assert {:forked, event} = cluster.reflex_result
    assert event.cluster_id == "veto_cluster"
  end

  test "pressure mesh diffuses load with the ontological fluid equation" do
    assert {:ok, _} = PressureMesh.register_peer("hot_node", 1.0, 0.8, ["cool_node", "warm_node"])
    assert {:ok, _} = PressureMesh.register_peer("cool_node", 0.2, 0.4, [])
    assert {:ok, _} = PressureMesh.register_peer("warm_node", 0.4, 0.6, [])

    assert {:ok, diffusion} = PressureMesh.diffuse_once("hot_node", 0.1, 0.2, 0.5)

    assert diffusion.laplacian < 0.0
    assert diffusion.delta < 0.0
    assert diffusion.pressure < 1.0
    assert diffusion.pressure >= 0.0
  end

  defp ensure_started(module) do
    unless Process.whereis(module) do
      start_supervised!(module)
    end
  end
end
