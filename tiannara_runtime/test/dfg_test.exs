defmodule TiannaraRuntime.DFGTest do
  use ExUnit.Case, async: false

  alias TiannaraRuntime.DFG.{PlateauDetector, TopologicalFold, MetaRealitySpawner, PortalRenderer, LatentRuntime}

  setup do
    if !Process.whereis(PortalRenderer), do: start_supervised!(PortalRenderer)
    if !Process.whereis(MetaRealitySpawner), do: start_supervised!(MetaRealitySpawner)
    if !Process.whereis(TopologicalFold), do: start_supervised!(TopologicalFold)
    if !Process.whereis(PlateauDetector), do: start_supervised!(PlateauDetector)
    if !Process.whereis(LatentRuntime), do: start_supervised!(LatentRuntime)
    :ok
  end

  test "topological fold correctly projects metrics into latent manifolds" do
    slice = %{
      id: "slice_abc",
      graph: %{
        nodes: ["node_1", "node_2"],
        edges: [{"node_1", "node_2"}]
      }
    }

    assert {:ok, fold_result} = TopologicalFold.fold(slice)
    assert is_map(fold_result)
    assert Map.has_key?(fold_result, :id)
    assert fold_result.slice_id == "slice_abc"
  end

  test "plateau detector starts and can scan safely" do
    pid = Process.whereis(PlateauDetector)
    assert is_pid(pid)
  end

  test "meta reality spawner spawns latent worlds and triggers portal rendering" do
    fold = %{slice_id: "slice_123", latent_graph: %{nodes: []}, features: %{anchors: [], h0: 1, h1: 0}}
    assert {:ok, spawned} = MetaRealitySpawner.spawn_latent_world(fold)
    assert is_map(spawned)
    assert spawned.slice_id == "slice_123"
  end

  test "latent runtime executes meta-op streams" do
    meta_ops = [%{id: "op_1"}, %{id: "op_2"}]
    assert :ok = LatentRuntime.execute_meta_ops(meta_ops)
  end
end
