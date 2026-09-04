defmodule Tiannara.Audit.FinalScorecard do
  @moduledoc """
  Final Scorecard — aggregates all audit tiers and produces an overall
  pass/fail verdict with per-tier breakdown.

  Called by `Tiannara.Audit.run_complete_audit/0`.
  """

  alias Tiannara.Audit.Tier1.ArchitecturalInvariants
  alias Tiannara.Audit.Tier2.WorldModelIntegrity
  alias Tiannara.Audit.Tier3.CoreIntegration
  alias Tiannara.Audit.Tier4.DomainCortex
  alias Tiannara.Audit.Tier5_8.SystemTests
  alias Tiannara.Audit.Tier9.EndToEnd

  @doc "Run the complete audit across all tiers and return a structured scorecard."
  def run_complete_audit do
    IO.puts("\n🔍 Running all audit tiers...\n")

    tiers = [
      {"Tier 1: Architectural Invariants", ArchitecturalInvariants.run_all_tests()},
      {"Tier 2: World Model Integrity",    WorldModelIntegrity.run_all_tests()},
      {"Tier 3: Core Integration",         CoreIntegration.run_all_tests()},
      {"Tier 4: Domain Cortex",            DomainCortex.run_all_tests()},
      {"Tier 5–8: System Tests",           SystemTests.run_all_tests()},
      {"Tier 9: End-to-End",              EndToEnd.run_all_tests()}
    ]

    tier_results =
      Enum.map(tiers, fn {name, {status, _results}} ->
        %{tier: name, status: status}
      end)

    overall_passed = Enum.all?(tier_results, &(&1.status == :pass))
    passed_count   = Enum.count(tier_results, &(&1.status == :pass))
    total_count    = length(tier_results)

    scorecard = %{
      timestamp:      DateTime.utc_now(),
      overall_passed: overall_passed,
      passed_tiers:   passed_count,
      total_tiers:    total_count,
      tier_results:   tier_results
    }

    IO.puts("\n" <> String.duplicate("=", 60))
    IO.puts("📋 FINAL SCORECARD: #{passed_count}/#{total_count} tiers passed")
    IO.puts(String.duplicate("=", 60))

    Enum.each(tier_results, fn %{tier: name, status: status} ->
      icon = if status == :pass, do: "✅", else: "❌"
      IO.puts("  #{icon} #{name}")
    end)

    scorecard
  end
end
