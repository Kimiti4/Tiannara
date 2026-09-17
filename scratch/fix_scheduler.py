import os
import re

file_path = r"c:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic\lib\tiannara\os\civilization_scheduler.ex"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Replace analyze_results chunk correctly
content = content.replace(
"""    # NEW TELEMETRY
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
    
    rediscovery_ratio = if total_capabilities > 0, do: Float.round(capability_births / total_capabilities, 2), else: 0.0""",
"""    # NEW TELEMETRY
    program_capabilities = length(Enum.uniq_by(prog_caps, & &1.id))
    world_capabilities = length(Enum.uniq_by(world_caps, & &1.id))
    civ_capabilities = length(Enum.uniq_by(civ_caps, & &1.id))
    
    meta = state.metadata || %{}
    capability_births = Map.get(meta, :capability_births, 0)
    capability_extinctions = Map.get(meta, :capability_extinctions, 0)
    capability_promotions = Map.get(meta, :capability_promotions, 0)
    
    final_tick_for_k = state.economy[:tick] || 0
    k_ticks = if final_tick_for_k > 0, do: final_tick_for_k / 1000, else: 1.0
    
    births_per_k = Float.round(capability_births / k_ticks, 2)
    extinctions_per_k = Float.round(capability_extinctions / k_ticks, 2)
    promotions_per_k = Float.round(capability_promotions / k_ticks, 2)
    
    avg_depth = if Enum.empty?(all_caps), do: 0.0, else: Float.round(Enum.sum(Enum.map(all_caps, &(&1.depth || 1))) / length(all_caps), 2)
    
    rediscovery_ratio = if total_capabilities > 0, do: Float.round(capability_births / total_capabilities, 2), else: 0.0""")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("Fixed final_tick compile error in civilization_scheduler.ex")
