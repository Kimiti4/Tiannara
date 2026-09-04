defmodule Tiannara.Debug.Audit do
  @moduledoc """
  Run 15.6: Instrumentation Audit Protocol
  
  Diagnoses why ecology tracking shows zero values despite active capability evolution.
  """

  def inspect_ecology_state do
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("ECOLOGY ETS INSPECTION")
    IO.puts(String.duplicate("=", 80))
    
    # Check if tables exist
    birth_info = :ets.info(:eco_births)
    lineage_info = :ets.info(:eco_lineages)
    stats_info = :ets.info(:eco_stats)
    
    IO.puts("\nTable Existence:")
    IO.puts("  eco_births:   #{if birth_info != :undefined, do: "EXISTS", else: "MISSING"}")
    IO.puts("  eco_lineages: #{if lineage_info != :undefined, do: "EXISTS", else: "MISSING"}")
    IO.puts("  eco_stats:    #{if stats_info != :undefined, do: "EXISTS", else: "MISSING"}")
    
    if birth_info != :undefined do
      birth_count = :ets.info(:eco_births, :size)
      IO.puts("\neco_births table:")
      IO.puts("  Entries: #{birth_count}")
      IO.puts("  Memory:  #{:ets.info(:eco_births, :memory)} words")
      
      if birth_count > 0 do
        sample = :ets.match(:eco_births, {~c"$1", ~c"$2", ~c"$3"}) |> Enum.take(5)
        IO.puts("  Sample entries (cap_id, birth_tick, lineage_id):")
        Enum.each(sample, fn entry -> IO.puts("    #{inspect(entry)}") end)
      end
    end
    
    if lineage_info != :undefined do
      lineage_count = :ets.info(:eco_lineages, :size)
      IO.puts("\neco_lineages table:")
      IO.puts("  Entries: #{lineage_count}")
      
      if lineage_count > 0 do
        sample = :ets.match(:eco_lineages, {~c"$1", ~c"$2"}) |> Enum.take(5)
        IO.puts("  Sample entries (lineage_id, count):")
        Enum.each(sample, fn entry -> IO.puts("    #{inspect(entry)}") end)
      end
    end
    
    if stats_info != :undefined do
      IO.puts("\neco_stats table:")
      stats = :ets.tab2list(:eco_stats)
      Enum.each(stats, fn {key, value} -> 
        IO.puts("  #{key}: #{value}")
      end)
    end
    
    IO.puts(String.duplicate("=", 80) <> "\n")
  end

  def compare_graph_vs_ecology(state) do
    # Count actual capability nodes at each architectural layer
    civilization_caps = map_size(state.capabilities || %{})
    
    world_caps = 
      state.worlds
      |> Map.values()
      |> Enum.map(fn world -> map_size(world.capabilities || %{}) end)
      |> Enum.sum()
    
    program_caps = 
      state.research_programs
      |> Map.values()
      |> Enum.map(fn prog -> map_size(prog.capabilities || %{}) end)
      |> Enum.sum()
    
    total_actual_capabilities = civilization_caps + world_caps + program_caps
    
    # Count discoveries
    total_discoveries = map_size(state.discoveries || %{})
    programs_with_caps = 
      state.research_programs
      |> Map.values()
      |> Enum.count(fn prog -> map_size(prog.capabilities || %{}) > 0 end)
    
    # Count ecology-tracked births from ETS
    ecology_births = 
      case :ets.info(:eco_births) do
        :undefined -> 0
        _ -> :ets.info(:eco_births, :size)
      end
    
    # Count from stats table
    [{:total_births, stats_births}] = 
      case :ets.info(:eco_stats) do
        :undefined -> [{:total_births, 0}]
        _ -> :ets.lookup(:eco_stats, :total_births)
      end
    
    [{:total_deaths, stats_deaths}] = 
      case :ets.info(:eco_stats) do
        :undefined -> [{:total_deaths, 0}]
        _ -> :ets.lookup(:eco_stats, :total_deaths)
      end
    
    expected_alive = stats_births - stats_deaths
    
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("GRAPH vs ECOLOGY COMPARISON")
    IO.puts(String.duplicate("=", 80))
    IO.puts("Discoveries:                 #{total_discoveries}")
    IO.puts("Programs with capabilities:  #{programs_with_caps}")
    IO.puts("")
    IO.puts("Civilization capabilities:   #{civilization_caps}")
    IO.puts("World capabilities:          #{world_caps}")
    IO.puts("Program capabilities:        #{program_caps}")
    IO.puts("TOTAL actual nodes:          #{total_actual_capabilities}")
    IO.puts("")
    IO.puts("Ecology tracked (ETS size):  #{ecology_births}")
    IO.puts("Ecology tracked (stats):     #{stats_births}")
    IO.puts("Ecology deaths (stats):      #{stats_deaths}")
    IO.puts("Expected alive (birth-death): #{expected_alive}")
    IO.puts("")
    
    cond do
      total_actual_capabilities > 0 and ecology_births == 0 ->
        IO.puts("❌ CRITICAL: Graph has nodes but ecology has ZERO tracking")
        IO.puts("   → Instrumentation not wired to capability creation")
        
        if program_caps > 0 do
          IO.puts("   → Program layer has #{program_caps} nodes")
          IO.puts("   → Check CapabilityRegistry.apply_*_mutation functions")
        end
      
      total_actual_capabilities > 0 and ecology_births > 0 and ecology_births < total_actual_capabilities ->
        IO.puts("⚠️  PARTIAL: Ecology tracking #{ecology_births}/#{total_actual_capabilities} nodes")
        IO.puts("   → Some creation paths not instrumented")
      
      total_actual_capabilities == ecology_births ->
        IO.puts("✅ ALIGNED: All capabilities tracked")
      
      ecology_births > total_actual_capabilities ->
        IO.puts("⚠️  ANOMALY: More births tracked than nodes exist")
        IO.puts("   → Possible double-counting or deletion tracking issue")
      
      true ->
        IO.puts("❓ UNKNOWN: Both are zero or tables missing")
    end
    
    # Invariant check
    IO.puts("\nINVARIANT CHECK:")
    if abs(expected_alive - total_actual_capabilities) < 100 do
      IO.puts("✅ Birth-Death invariant holds (diff: #{abs(expected_alive - total_actual_capabilities)})")
    else
      IO.puts("❌ INVARIANT VIOLATION: Expected #{expected_alive}, got #{total_actual_capabilities}")
      IO.puts("   Discrepancy: #{total_actual_capabilities - expected_alive}")
    end
    
    IO.puts(String.duplicate("=", 80) <> "\n")
  end
end
