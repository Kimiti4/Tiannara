import os
import re

file_path = r"c:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic\lib\tiannara\os\civilization_scheduler.ex"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Fix world.wealth in enforce_scarcity
content = content.replace("world.wealth || 100_000", "Map.get(world.economy || %{}, :wealth, 100_000)")
content = content.replace("%{world | wealth: max(0, (world.wealth || 100_000) - maintenance_cost)}",
                          "%{world | economy: Map.put(world.economy || %{}, :wealth, max(0, Map.get(world.economy || %{}, :wealth, 100_000) - maintenance_cost))}")

# Also funding_pool
content = content.replace("updated_world.funding_pool || 500_000", "Map.get(updated_world.economy || %{}, :funding_pool, 500_000)")
content = content.replace("wealth_based_pool = (updated_world.wealth || 100_000) * 5",
                          "wealth_based_pool = Map.get(updated_world.economy || %{}, :wealth, 100_000) * 5")
content = content.replace("%{updated_world | funding_pool: funding_pool}",
                          "%{updated_world | economy: Map.put(updated_world.economy || %{}, :funding_pool, funding_pool)}")


with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("Fixed wealth and funding_pool struct errors in civilization_scheduler.ex")
