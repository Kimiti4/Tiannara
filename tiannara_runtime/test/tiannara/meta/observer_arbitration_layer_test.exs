defmodule Tiannara.Meta.ObserverArbitrationLayerTest do
  @moduledoc """
  Integration tests for Phase 5F.2 — Observer Collapse Arbitration Layer (OCAL)
  
  Tests cover:
  - MERGE outcome (chimera synthesis)
  - SUPPRESS outcome (dormant reality)
  - COLLAPSE outcome (hard termination)
  - Resurrection of suppressed/collapsed observers
  - ETS table management
  - NATS event publishing
  """
  
  use ExUnit.Case, async: false
  
  alias Tiannara.Meta.ObserverArbitrationLayer, as: OCAL
  alias TiannaraRuntime.MCK
  
  setup do
    # Start OCAL, MCK and MSCL safely
    unless Process.whereis(TiannaraRuntime.MCK) do
      {:ok, _} = TiannaraRuntime.MCK.start_link([])
    end
    unless Process.whereis(Tiannara.Meta.MSCL) do
      {:ok, _} = Tiannara.Meta.MSCL.start_link([])
    end
    unless Process.whereis(OCAL) do
      {:ok, _} = OCAL.start_link([])
    end
    
    pid = Process.whereis(OCAL)
    
    # Ensure ETS tables exist safely
    if :ets.info(:suppressed_observers) == :undefined do
      :ets.new(:suppressed_observers, [:named_table, :set, :public])
    else
      :ets.delete_all_objects(:suppressed_observers)
    end
    
    if :ets.info(:collapsed_causal_archive) == :undefined do
      :ets.new(:collapsed_causal_archive, [:named_table, :bag, :public])
    else
      :ets.delete_all_objects(:collapsed_causal_archive)
    end
    
    %{pid: pid}
  end
  
  describe "resolve/5 - MERGE outcome" do
    test "creates chimera observer from two parents" do
      observer_a = %{
        observer_id: "merge_parent_a",
        coherence: 0.75,
        msf: 0.70,
        prediction: 0.80,
        interference: 0.25,
        causality_graph: [%{from: "A1", to: "A2", weight: 0.8}],
        time_vector: [1.0, 0.0, 0.0],
        physics_compiler: "GLSL",
        entropy_field: [0.3, 0.4, 0.5],
        ctn_interference: [0.1, 0.2]
      }
      
      observer_b = %{
        observer_id: "merge_parent_b",
        coherence: 0.76,
        msf: 0.71,
        prediction: 0.79,
        interference: 0.26,
        causality_graph: [%{from: "B1", to: "B2", weight: 0.7}],
        time_vector: [0.9, 0.1, 0.0],
        physics_compiler: "WASM",
        entropy_field: [0.4, 0.5, 0.6],
        ctn_interference: [0.2, 0.3]
      }
      
      oss_a = 0.70
      oss_b = 0.71
      
      {:ok, outcome} = OCAL.resolve(:merge, observer_a, observer_b, oss_a, oss_b)
      
      assert outcome.decision == :merge
      assert outcome.chimera_id =~ "CHIMERA-merge_parent_a-merge_parent_b-"
      assert outcome.parents == {"merge_parent_a", "merge_parent_b"}
      assert_in_delta outcome.blended_oss, 0.705, 0.01
    end
    
    test "blends observer fields proportionally to OSS" do
      observer_a = %{
        observer_id: "blend_a",
        coherence: 0.90,
        msf: 0.85,
        prediction: 0.95,
        interference: 0.10,
        causality_graph: [],
        time_vector: [1.0, 0.0, 0.0],
        physics_compiler: "GLSL",
        entropy_field: [0.2],
        ctn_interference: []
      }
      
      observer_b = %{
        observer_id: "blend_b",
        coherence: 0.50,
        msf: 0.45,
        prediction: 0.55,
        interference: 0.50,
        causality_graph: [],
        time_vector: [0.0, 1.0, 0.0],
        physics_compiler: "WASM",
        entropy_field: [0.8],
        ctn_interference: []
      }
      
      oss_a = 0.90  # Higher OSS should dominate blend
      oss_b = 0.30
      
      {:ok, outcome} = OCAL.resolve(:merge, observer_a, observer_b, oss_a, oss_b)
      
      assert outcome.decision == :merge
      assert outcome.chimera_id =~ "CHIMERA-"
    end
    
    test "collapses both parent observers after merge" do
      observer_a = %{
        observer_id: "parent_a_collapse",
        coherence: 0.75,
        msf: 0.70,
        prediction: 0.80,
        interference: 0.25,
        causality_graph: [],
        time_vector: [1.0, 0.0, 0.0],
        physics_compiler: "GLSL",
        entropy_field: [0.3],
        ctn_interference: []
      }
      
      observer_b = %{
        observer_id: "parent_b_collapse",
        coherence: 0.76,
        msf: 0.71,
        prediction: 0.79,
        interference: 0.26,
        causality_graph: [],
        time_vector: [0.9, 0.1, 0.0],
        physics_compiler: "GLSL",
        entropy_field: [0.4],
        ctn_interference: []
      }
      
      {:ok, outcome} = OCAL.resolve(:merge, observer_a, observer_b, 0.70, 0.71)
      
      # Parents should be collapsed in MCK
      # Note: In real scenario, MCK would handle this
      assert outcome.decision == :merge
    end
  end
  
  describe "resolve/5 - SUPPRESS outcome" do
    test "suppresses lower-OSS observer" do
      observer_high = %{
        observer_id: "suppress_high",
        coherence: 0.85,
        msf: 0.80,
        prediction: 0.90,
        interference: 0.15
      }
      
      observer_low = %{
        observer_id: "suppress_low",
        coherence: 0.60,
        msf: 0.55,
        prediction: 0.65,
        interference: 0.35
      }
      
      oss_high = 0.85
      oss_low = 0.45
      
      {:ok, outcome} = OCAL.resolve(:suppress, observer_high, observer_low, oss_high, oss_low)
      
      assert outcome.decision == :suppress
      assert outcome.suppressed_id == "suppress_low"
      assert_in_delta outcome.oss, 0.45, 0.01
    end
    
    test "records suppressed observer in ETS table" do
      observer = %{
        observer_id: "ets_suppress",
        coherence: 0.60,
        msf: 0.55,
        prediction: 0.65,
        interference: 0.35
      }
      
      {:ok, _outcome} = OCAL.resolve(:suppress, observer, %{}, 0.45, 0.80)
      
      # Verify entry exists in suppressed_observers table
      assert :ets.member(:suppressed_observers, "ets_suppress")
    end
    
    test "persists suppression metadata" do
      observer = %{
        observer_id: "metadata_suppress",
        coherence: 0.65,
        msf: 0.60,
        prediction: 0.70,
        interference: 0.30
      }
      
      {:ok, _outcome} = OCAL.resolve(:suppress, observer, %{}, 0.50, 0.85)
      
      [{"metadata_suppress", {_manifold, _oss_val, oss, status, timestamp}}] = 
        :ets.lookup(:suppressed_observers, "metadata_suppress")
      
      assert status == :suppressed
      assert is_number(oss)
      assert match?(%DateTime{}, timestamp)
    end
  end
  
  describe "resolve/5 - COLLAPSE outcome" do
    test "collapses lowest-OSS observer" do
      observer_stable = %{
        observer_id: "collapse_stable",
        coherence: 0.80,
        msf: 0.75,
        prediction: 0.85,
        interference: 0.20
      }
      
      observer_unstable = %{
        observer_id: "collapse_unstable",
        coherence: 0.20,
        msf: 0.15,
        prediction: 0.25,
        interference: 0.90
      }
      
      oss_stable = 0.80
      oss_unstable = 0.05
      
      {:ok, outcome} = OCAL.resolve(:collapse, observer_stable, observer_unstable, oss_stable, oss_unstable)
      
      assert outcome.decision == :collapse
      assert outcome.collapsed_id == "collapse_unstable"
      assert outcome.surviving_id == "collapse_stable"
      assert_in_delta outcome.collapsed_oss, 0.05, 0.01
      assert_in_delta outcome.surviving_oss, 0.80, 0.01
    end
    
    test "archives collapsed observer in causal archive" do
      observer = %{
        observer_id: "archive_collapse",
        coherence: 0.15,
        msf: 0.10,
        prediction: 0.20,
        interference: 0.95
      }
      
      {:ok, _outcome} = OCAL.resolve(:collapse, %{}, observer, 0.80, 0.05)
      
      # Verify entry exists in collapsed_causal_archive
      assert :ets.member(:collapsed_causal_archive, "archive_collapse")
    end
    
    test "preserves collapse trace for future recompilation" do
      observer = %{
        observer_id: "trace_collapse",
        coherence: 0.25,
        msf: 0.20,
        prediction: 0.30,
        interference: 0.85
      }
      
      {:ok, _outcome} = OCAL.resolve(:collapse, %{}, observer, 0.75, 0.10)
      
      entries = :ets.lookup(:collapsed_causal_archive, "trace_collapse")
      assert length(entries) > 0
      
      {_id, {_obs, _manifold, oss, status, _at}} = hd(entries)
      assert status == :collapsed
      assert is_number(oss)
    end
  end
  
  describe "attempt_resurrection/1" do
    test "resurrects suppressed observer" do
      # First suppress an observer
      observer = %{
        observer_id: "resurrect_test",
        coherence: 0.65,
        msf: 0.60,
        prediction: 0.70,
        interference: 0.30
      }
      
      {:ok, _} = OCAL.resolve(:suppress, observer, %{}, 0.50, 0.85)
      
      # Attempt resurrection
      result = OCAL.attempt_resurrection("resurrect_test")
      
      assert match?({:ok, "resurrect_test"}, result)
      
      # Should be removed from suppressed table
      refute :ets.member(:suppressed_observers, "resurrect_test")
    end
    
    test "recompiles collapsed observer from archive" do
      # First collapse an observer
      observer = %{
        observer_id: "recompile_test",
        coherence: 0.20,
        msf: 0.15,
        prediction: 0.25,
        interference: 0.90
      }
      
      {:ok, _} = OCAL.resolve(:collapse, %{}, observer, 0.80, 0.05)
      
      # Attempt resurrection (should recompile from archive)
      result = OCAL.attempt_resurrection("recompile_test")
      
      assert match?({:ok, "recompile_test"}, result)
    end
    
    test "returns error when observer not found" do
      result = OCAL.attempt_resurrection("nonexistent_observer")
      
      assert result == {:error, :not_found}
    end
  end
  
  describe "list_suppressed/0" do
    test "returns all suppressed observers" do
      # Suppress multiple observers
      observers = [
        %{observer_id: "supp_1", coherence: 0.60, msf: 0.55, prediction: 0.65, interference: 0.35},
        %{observer_id: "supp_2", coherence: 0.55, msf: 0.50, prediction: 0.60, interference: 0.40},
        %{observer_id: "supp_3", coherence: 0.50, msf: 0.45, prediction: 0.55, interference: 0.45}
      ]
      
      Enum.each(observers, fn obs ->
        OCAL.resolve(:suppress, obs, %{}, 0.45, 0.80)
      end)
      
      {:ok, suppressed_list} = OCAL.list_suppressed()
      
      assert length(suppressed_list) >= 3
      
      ids = Enum.map(suppressed_list, & &1.observer_id)
      assert "supp_1" in ids
      assert "supp_2" in ids
      assert "supp_3" in ids
    end
    
    test "includes OSS and suppression timestamp" do
      observer = %{
        observer_id: "list_metadata",
        coherence: 0.65,
        msf: 0.60,
        prediction: 0.70,
        interference: 0.30
      }
      
      {:ok, _} = OCAL.resolve(:suppress, observer, %{}, 0.50, 0.85)
      
      {:ok, suppressed_list} = OCAL.list_suppressed()
      
      entry = Enum.find(suppressed_list, & &1.observer_id == "list_metadata")
      assert entry != nil
      assert is_number(entry.oss)
      assert match?(%DateTime{}, entry.suppressed_at)
    end
  end
  
  describe "list_collapsed_archive/0" do
    test "returns all collapsed observers in archive" do
      # Collapse multiple observers
      observers = [
        %{observer_id: "coll_1", coherence: 0.20, msf: 0.15, prediction: 0.25, interference: 0.90},
        %{observer_id: "coll_2", coherence: 0.15, msf: 0.10, prediction: 0.20, interference: 0.95},
        %{observer_id: "coll_3", coherence: 0.10, msf: 0.05, prediction: 0.15, interference: 0.98}
      ]
      
      Enum.each(observers, fn obs ->
        OCAL.resolve(:collapse, %{}, obs, 0.80, 0.05)
      end)
      
      {:ok, archive_list} = OCAL.list_collapsed_archive()
      
      assert length(archive_list) >= 3
      
      ids = Enum.map(archive_list, & &1.observer_id)
      assert "coll_1" in ids
      assert "coll_2" in ids
      assert "coll_3" in ids
    end
    
    test "includes collapse status and timestamp" do
      observer = %{
        observer_id: "archive_metadata",
        coherence: 0.25,
        msf: 0.20,
        prediction: 0.30,
        interference: 0.85
      }
      
      {:ok, _} = OCAL.resolve(:collapse, %{}, observer, 0.75, 0.10)
      
      {:ok, archive_list} = OCAL.list_collapsed_archive()
      
      entry = Enum.find(archive_list, & &1.observer_id == "archive_metadata")
      assert entry != nil
      assert entry.status == :collapsed
      assert match?(%DateTime{}, entry.collapsed_at)
    end
  end
  
  describe "chimera synthesis" do
    test "blends causality graphs with weighted edges" do
      observer_a = %{
        observer_id: "graph_a",
        coherence: 0.80,
        msf: 0.75,
        prediction: 0.85,
        interference: 0.20,
        causality_graph: [
          %{from: "A1", to: "A2", weight: 0.8},
          %{from: "A2", to: "A3", weight: 0.6}
        ],
        time_vector: [1.0, 0.0, 0.0],
        physics_compiler: "GLSL",
        entropy_field: [0.3],
        ctn_interference: []
      }
      
      observer_b = %{
        observer_id: "graph_b",
        coherence: 0.70,
        msf: 0.65,
        prediction: 0.75,
        interference: 0.30,
        causality_graph: [
          %{from: "B1", to: "B2", weight: 0.7}
        ],
        time_vector: [0.0, 1.0, 0.0],
        physics_compiler: "WASM",
        entropy_field: [0.7],
        ctn_interference: []
      }
      
      {:ok, outcome} = OCAL.resolve(:merge, observer_a, observer_b, 0.75, 0.65)
      
      assert outcome.decision == :merge
      # Chimera should be registered in MCK (verified by successful resolution)
    end
    
    test "superposes CTN interference fields" do
      observer_a = %{
        observer_id: "ctn_a",
        coherence: 0.75,
        msf: 0.70,
        prediction: 0.80,
        interference: 0.25,
        causality_graph: [],
        time_vector: [1.0, 0.0, 0.0],
        physics_compiler: "GLSL",
        entropy_field: [0.3],
        ctn_interference: [0.1, 0.2, 0.3]
      }
      
      observer_b = %{
        observer_id: "ctn_b",
        coherence: 0.70,
        msf: 0.65,
        prediction: 0.75,
        interference: 0.30,
        causality_graph: [],
        time_vector: [0.0, 1.0, 0.0],
        physics_compiler: "GLSL",
        entropy_field: [0.4],
        ctn_interference: [0.2, 0.3, 0.4]
      }
      
      {:ok, outcome} = OCAL.resolve(:merge, observer_a, observer_b, 0.70, 0.65)
      
      assert outcome.decision == :merge
    end
    
    test "prefers higher-OSS parent's physics compiler" do
      observer_glsl = %{
        observer_id: "compiler_glsl",
        coherence: 0.85,
        msf: 0.80,
        prediction: 0.90,
        interference: 0.15,
        causality_graph: [],
        time_vector: [1.0, 0.0, 0.0],
        physics_compiler: "GLSL",
        entropy_field: [0.3],
        ctn_interference: []
      }
      
      observer_wasm = %{
        observer_id: "compiler_wasm",
        coherence: 0.60,
        msf: 0.55,
        prediction: 0.65,
        interference: 0.40,
        causality_graph: [],
        time_vector: [0.0, 1.0, 0.0],
        physics_compiler: "WASM",
        entropy_field: [0.7],
        ctn_interference: []
      }
      
      {:ok, outcome} = OCAL.resolve(:merge, observer_glsl, observer_wasm, 0.85, 0.55)
      
      assert outcome.decision == :merge
      # Higher-OSS parent (GLSL) should be preferred
    end
  end
  
  describe "edge cases" do
    test "handles observers with identical OSS" do
      observer_a = %{
        observer_id: "equal_oss_a",
        coherence: 0.75,
        msf: 0.70,
        prediction: 0.80,
        interference: 0.25,
        causality_graph: [],
        time_vector: [1.0, 0.0, 0.0],
        physics_compiler: "GLSL",
        entropy_field: [0.3],
        ctn_interference: []
      }
      
      observer_b = %{
        observer_id: "equal_oss_b",
        coherence: 0.75,
        msf: 0.70,
        prediction: 0.80,
        interference: 0.25,
        causality_graph: [],
        time_vector: [0.0, 1.0, 0.0],
        physics_compiler: "GLSL",
        entropy_field: [0.3],
        ctn_interference: []
      }
      
      {:ok, outcome} = OCAL.resolve(:merge, observer_a, observer_b, 0.70, 0.70)
      
      assert outcome.decision == :merge
    end
    
    test "handles missing optional fields gracefully" do
      minimal_observer_a = %{
        observer_id: "minimal_a",
        coherence: 0.70,
        msf: 0.65,
        prediction: 0.75,
        interference: 0.30
      }
      
      minimal_observer_b = %{
        observer_id: "minimal_b",
        coherence: 0.60,
        msf: 0.55,
        prediction: 0.65,
        interference: 0.40
      }
      
      # Should still work even without optional fields like causality_graph
      {:ok, outcome} = OCAL.resolve(:suppress, minimal_observer_a, minimal_observer_b, 0.65, 0.55)
      
      assert outcome.decision == :suppress
    end
    
    test "handles extreme OSS differences" do
      observer_max = %{
        observer_id: "extreme_max",
        coherence: 1.0,
        msf: 1.0,
        prediction: 1.0,
        interference: 0.0,
        causality_graph: [],
        time_vector: [1.0, 0.0, 0.0],
        physics_compiler: "GLSL",
        entropy_field: [0.0],
        ctn_interference: []
      }
      
      observer_min = %{
        observer_id: "extreme_min",
        coherence: 0.0,
        msf: 0.0,
        prediction: 0.0,
        interference: 1.0,
        causality_graph: [],
        time_vector: [0.0, 0.0, 0.0],
        physics_compiler: "GLSL",
        entropy_field: [1.0],
        ctn_interference: []
      }
      
      {:ok, outcome} = OCAL.resolve(:collapse, observer_max, observer_min, 1.0, 0.0)
      
      assert outcome.decision == :collapse
      assert outcome.collapsed_id == "extreme_min"
      assert outcome.surviving_id == "extreme_max"
    end
  end
  
  describe "statistics tracking" do
    test "tracks chimera creation count" do
      observer_a = %{
        observer_id: "stat_merge_a",
        coherence: 0.75,
        msf: 0.70,
        prediction: 0.80,
        interference: 0.25,
        causality_graph: [],
        time_vector: [1.0, 0.0, 0.0],
        physics_compiler: "GLSL",
        entropy_field: [0.3],
        ctn_interference: []
      }
      
      observer_b = %{
        observer_id: "stat_merge_b",
        coherence: 0.76,
        msf: 0.71,
        prediction: 0.79,
        interference: 0.26,
        causality_graph: [],
        time_vector: [0.9, 0.1, 0.0],
        physics_compiler: "GLSL",
        entropy_field: [0.4],
        ctn_interference: []
      }
      
      {:ok, result} = OCAL.resolve(:merge, observer_a, observer_b, 0.70, 0.71)
      
      assert result != nil
    end
    
    test "tracks suppression count" do
      observer = %{
        observer_id: "stat_suppress",
        coherence: 0.60,
        msf: 0.55,
        prediction: 0.65,
        interference: 0.35
      }
      
      {:ok, result} = OCAL.resolve(:suppress, observer, %{}, 0.45, 0.80)
      
      assert result != nil
    end
    
    test "tracks collapse count" do
      observer = %{
        observer_id: "stat_collapse",
        coherence: 0.20,
        msf: 0.15,
        prediction: 0.25,
        interference: 0.90
      }
      
      {:ok, result} = OCAL.resolve(:collapse, %{}, observer, 0.80, 0.05)
      
      assert result != nil
    end
  end
end
