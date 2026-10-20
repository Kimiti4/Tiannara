defmodule TiannaraRuntime.Cognitive.WorkingMemoryValidationTest do
  use ExUnit.Case, async: false
  @moduletag :working_memory

  alias TiannaraRuntime.Cognitive.Engines.{
    WorkingMemory, MemoryFrame, CognitiveWorkspace,
    ActivationGraph, ContextAssembler, ContextSnapshot, ContextReplay
  }

  describe "Tier 1 — Working Memory Lifecycle" do
    test "create initializes empty store" do
      state = WorkingMemory.create()
      assert state.store == %{}
      assert state.capacity > 0
    end

    test "insert adds value" do
      state = WorkingMemory.create()
      assert {:ok, new_state} = WorkingMemory.insert(state, "x", 42)
      assert Map.has_key?(new_state.store, "x")
    end

    test "get retrieves value" do
      state = WorkingMemory.create()
      {:ok, state} = WorkingMemory.insert(state, "x", 42)
      assert {:ok, 42} = WorkingMemory.get(state, "x")
    end
  end

  describe "Tier 2 — Frame Creation/Removal" do
    test "create_frame returns frame map" do
      assert {:ok, frame} = MemoryFrame.create_frame("ms_1", "kernel")
      assert is_integer(frame.frame_id)
      assert frame.mission_id == "ms_1"
      assert frame.status == :active
    end

    test "add_evidence appends ref" do
      {:ok, frame} = MemoryFrame.create_frame("ms_1", "kernel")
      {:ok, frame} = MemoryFrame.add_evidence(frame, "ev_ref_1")
      assert length(frame.evidence_refs) == 1
    end

    test "expire sets status to expired" do
      {:ok, frame} = MemoryFrame.create_frame("ms_1", "kernel")
      {:ok, frame} = MemoryFrame.expire(frame)
      assert frame.status == :expired
    end
  end

  describe "Tier 3 — Activation Graph Determinism" do
    test "create returns empty graph" do
      graph = ActivationGraph.create()
      assert graph.nodes == %{}
      assert graph.edges == %{}
    end

    test "add_node and add_edge work" do
      graph = ActivationGraph.create()
      {:ok, graph} = ActivationGraph.add_node(graph, :a, %{name: "A"})
      {:ok, graph} = ActivationGraph.add_node(graph, :b, %{name: "B"})
      {:ok, graph} = ActivationGraph.add_edge(graph, :a, :b)
      assert graph.edges[:a] == [:b]
    end

    test "cycle detection returns error" do
      graph = ActivationGraph.create()
      {:ok, graph} = ActivationGraph.add_node(graph, :a, %{})
      {:ok, graph} = ActivationGraph.add_node(graph, :b, %{})
      {:ok, graph} = ActivationGraph.add_edge(graph, :a, :b)
      assert {:error, :cycle_detected} = ActivationGraph.add_edge(graph, :b, :a)
    end
  end

  describe "Tier 4 — Context Assembly" do
    test "assemble returns context state" do
      mission = %{id: "m1", objective: "test"}
      wm = WorkingMemory.create()
      graph = ActivationGraph.create()
      assert {:ok, context_state} = ContextAssembler.assemble(mission, wm, graph)
      assert is_map(context_state)
    end

    test "assemble sorts references" do
      mission = %{id: "m1"}
      wm = WorkingMemory.create()
      graph = ActivationGraph.create()
      unsorted = ["z", "a", "m"]
      {:ok, context_state} = ContextAssembler.assemble(mission, wm, graph, knowledge_refs: unsorted)
      assert context_state.knowledge_refs == ["a", "m", "z"]
    end

    test "assemble includes mission" do
      mission = %{id: "m1", objective: "test"}
      wm = WorkingMemory.create()
      graph = ActivationGraph.create()
      {:ok, context_state} = ContextAssembler.assemble(mission, wm, graph)
      assert context_state.mission == mission
    end
  end

  describe "Tier 5 — Snapshot Generation" do
    test "capture returns snapshot" do
      mission = %{id: "m1"}
      wm = WorkingMemory.create()
      graph = ActivationGraph.create()
      workspace = CognitiveWorkspace.create(mission, %{})
      {:ok, context_state} = ContextAssembler.assemble(mission, wm, graph)
      assert {:ok, snapshot} = ContextSnapshot.capture(workspace, context_state, graph)
      assert snapshot.fingerprint != nil
    end

    test "verify passes for valid snapshot" do
      mission = %{id: "m1"}
      wm = WorkingMemory.create()
      graph = ActivationGraph.create()
      workspace = CognitiveWorkspace.create(mission, %{})
      {:ok, context_state} = ContextAssembler.assemble(mission, wm, graph)
      {:ok, snapshot} = ContextSnapshot.capture(workspace, context_state, graph)
      assert {:ok, :verified} = ContextSnapshot.verify(snapshot)
    end

    test "verify fails for corrupted snapshot" do
      mission = %{id: "m1"}
      wm = WorkingMemory.create()
      graph = ActivationGraph.create()
      workspace = CognitiveWorkspace.create(mission, %{})
      {:ok, context_state} = ContextAssembler.assemble(mission, wm, graph)
      {:ok, snapshot} = ContextSnapshot.capture(workspace, context_state, graph)
      corrupted = %{snapshot | workspace: %{}}
      assert {:error, :hash_mismatch} = ContextSnapshot.verify(corrupted)
    end
  end

  describe "Tier 6 — Replay" do
    test "record creates replay record" do
      mission = %{id: "m1"}
      wm = WorkingMemory.create()
      graph = ActivationGraph.create()
      workspace = CognitiveWorkspace.create(mission, %{})
      {:ok, context_state} = ContextAssembler.assemble(mission, wm, graph)
      {:ok, snapshot} = ContextSnapshot.capture(workspace, context_state, graph)
      assert {:ok, replay_record} = ContextReplay.record(%{a: 1}, snapshot)
      assert replay_record.replay_id != nil
    end

    test "verify_state checks fingerprint" do
      state = %{a: 1}
      canonical = state |> Enum.sort_by(fn {k, _} -> k end) |> Enum.map(fn {k, v} -> "#{k}:#{inspect(v)}" end) |> Enum.join("|")
      fp = :crypto.hash(:sha256, canonical) |> Base.encode16(case: :lower)
      assert {:ok, :verified} = ContextReplay.verify_state(state, fp)
      assert {:error, :hash_mismatch} = ContextReplay.verify_state(state, "wrong_fingerprint")
    end
  end

  describe "Tier 7 — Memory Eviction" do
    test "insert at capacity evicts oldest" do
      wm = WorkingMemory.create(1)
      {:ok, wm} = WorkingMemory.insert(wm, "a", 1)
      {:ok, wm} = WorkingMemory.insert(wm, "b", 2)
      refute Map.has_key?(wm.store, "a")
    end

    test "eviction preserves other entries" do
      wm = WorkingMemory.create(5)
      wm = Enum.reduce(1..5, wm, fn i, acc ->
        {:ok, wm} = WorkingMemory.insert(acc, "k#{i}", i)
        wm
      end)
      {:ok, wm} = WorkingMemory.insert(wm, "k6", 6)
      assert Map.has_key?(wm.store, "k2")
      assert Map.has_key?(wm.store, "k3")
      assert Map.has_key?(wm.store, "k4")
      assert Map.has_key?(wm.store, "k5")
      refute Map.has_key?(wm.store, "k1")
    end
  end

  describe "Tier 8 — Archaeology" do
    test "workspace tracks refs" do
      workspace = CognitiveWorkspace.create(%{id: "m1"}, %{})
      {:ok, workspace} = CognitiveWorkspace.add_archaeology(workspace, "arch_ref_1")
      assert length(workspace.archaeology_refs) == 1
    end

    test "frame tracks refs" do
      {:ok, frame} = MemoryFrame.create_frame("ms_1", "kernel")
      {:ok, frame} = MemoryFrame.add_archaeology(frame, "arch_ref_1")
      assert frame.archaeology_refs == ["arch_ref_1"]
    end
  end

  describe "Tier 9 — Failure Injection" do
    test "get nonexistent key returns error" do
      state = WorkingMemory.create()
      assert {:error, :not_found} = WorkingMemory.get(state, "nonexistent")
    end

    test "update nonexistent key returns error" do
      state = WorkingMemory.create()
      assert {:error, :not_found} = WorkingMemory.update(state, "nonexistent", 99)
    end

    test "remove nonexistent key returns error" do
      state = WorkingMemory.create()
      assert {:error, :not_found} = WorkingMemory.remove(state, "nonexistent")
    end
  end

  describe "Tier 10 — Stress" do
    test "1000 inserts work" do
      wm = WorkingMemory.create(2000)
      wm = Enum.reduce(1..1000, wm, fn i, acc ->
        {:ok, wm} = WorkingMemory.insert(acc, "k#{i}", i)
        wm
      end)
      assert wm.usage == 1000
    end

    test "snapshot after many inserts" do
      wm = WorkingMemory.create(200)
      wm = Enum.reduce(1..100, wm, fn i, acc ->
        {:ok, wm} = WorkingMemory.insert(acc, "k#{i}", i)
        wm
      end)
      {:ok, _wm, snapshot} = WorkingMemory.snapshot(wm)
      assert map_size(snapshot.store) == 100
    end
  end
end
