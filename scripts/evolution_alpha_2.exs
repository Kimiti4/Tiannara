#!/usr/bin/env elixir

# Evolution Alpha 2 Campaign Runner
# Phase 4.7 — Adaptive Repair Civilization & Knowledge Reuse Engine
# 
# Runs 5 Projects × 20 Generations = 100 Project-Generations
# Target: Repair Success Rate > 10%, Knowledge Reuse Rate > 10%

IO.puts("=" |> String.duplicate(80))
IO.puts("🧬 EVOLUTION ALPHA 2 CAMPAIGN")
IO.puts("Phase 4.7 — Adaptive Repair Civilization & Knowledge Reuse Engine")
IO.puts("=" |> String.duplicate(80))
IO.puts("")

# Run the evolution campaign
case Tiannara.ASC.Crucible.EvolutionCampaign.run() do
  {:ok, results} ->
    IO.puts("\n✅ Campaign completed successfully!")
    IO.inspect(results, limit: :infinity)
    
  {:error, error} ->
    IO.puts("\n❌ Campaign failed: #{inspect(error)}")
    System.halt(1)
end
