import os
import re

file_path = r"c:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic\lib\tiannara\os\civilization_scheduler.ex"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Update analyze_results
content = content.replace("total_capabilities = length(Enum.uniq_by(all_caps, & &1.id))",
"""total_capabilities = length(Enum.uniq_by(all_caps, & &1.id))
    
    # NEW TELEMETRY
    program_capabilities = length(Enum.uniq_by(prog_caps, & &1.id))
    world_capabilities = length(Enum.uniq_by(world_caps, & &1.id))
    civ_capabilities = length(Enum.uniq_by(civ_caps, & &1.id))
    
    meta = state.metadata || %{}
    capability_births = Map.get(meta, :capability_births, 0)
    capability_extinctions = Map.get(meta, :capability_extinctions, 0)
    capability_promotions = Map.get(meta, :capability_promotions, 0)
    
    k_ticks = if final_tick > 0, do: final_tick / 1000, else: 1.0
    births_per_k = Float.round(capability_births / k_ticks, 2)
    extinctions_per_k = Float.round(capability_extinctions / k_ticks, 2)
    promotions_per_k = Float.round(capability_promotions / k_ticks, 2)
    
    avg_depth = if Enum.empty?(all_caps), do: 0.0, else: Float.round(Enum.sum(Enum.map(all_caps, &(&1.depth || 1))) / length(all_caps), 2)
    
    rediscovery_ratio = if total_capabilities > 0, do: Float.round(capability_births / total_capabilities, 2), else: 0.0
""")

content = content.replace("technological_depth: technological_depth,",
"""technological_depth: technological_depth,
      avg_technological_depth: avg_depth,
      program_capabilities: program_capabilities,
      world_capabilities: world_capabilities,
      civ_capabilities: civ_capabilities,
      capability_births_per_k: births_per_k,
      capability_extinctions_per_k: extinctions_per_k,
      promotion_rate_per_k: promotions_per_k,
      rediscovery_ratio: rediscovery_ratio,
""")

# Update print_civilization_summary
content = content.replace("""    IO.puts("\\n🔬 Capabilities:")
    IO.puts("   Total capabilities: #{metrics.total_capabilities} (Unique)")
    IO.puts("   Technological Depth: #{metrics.technological_depth}")
    IO.puts("   Capability velocity: #{metrics.capability_velocity} per 1000 ticks")""",
"""    IO.puts("\\n🧠 TECHNOLOGICAL EVOLUTION:")
    IO.puts("   Program Capabilities: #{Map.get(metrics, :program_capabilities, 0)}")
    IO.puts("   World Capabilities: #{Map.get(metrics, :world_capabilities, 0)}")
    IO.puts("   Civilization Capabilities: #{Map.get(metrics, :civ_capabilities, 0)}")
    IO.puts("")
    IO.puts("   Capability Births/k: #{Map.get(metrics, :capability_births_per_k, 0.0)}")
    IO.puts("   Capability Extinctions/k: #{Map.get(metrics, :capability_extinctions_per_k, 0.0)}")
    IO.puts("   Promotion Rate/k: #{Map.get(metrics, :promotion_rate_per_k, 0.0)}")
    IO.puts("")
    IO.puts("   Technological Depth:")
    IO.puts("     Avg: #{Map.get(metrics, :avg_technological_depth, 0.0)}")
    IO.puts("     Max: #{metrics.technological_depth}")
    IO.puts("")
    IO.puts("   Capability Velocity: #{metrics.capability_velocity}")
    IO.puts("   Rediscovery Ratio: #{Map.get(metrics, :rediscovery_ratio, 0.0)}x")
""")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("Patched civilization_scheduler.ex for metrics")
