# run_post_phase22_certification.exs
#
# Master runner script for the 30-campaign Constitutional Certification Framework.
#
# Usage:
#   # Run all 30 campaigns
#   TIANNARA_SCALE=full TIANNARA_SEED=42 elixir run_post_phase22_certification.exs
#
#   # Run a specific domain only
#   TIANNARA_DOMAIN=evolution_integrity elixir run_post_phase22_certification.exs
#
#   # Run a subset of campaigns
#   TIANNARA_CAMPAIGN_FILTER="1,4,5,7,9,10,11,15,18,23,24" elixir run_post_phase22_certification.exs
#
# Scale modes:
#   TIANNARA_SCALE=quick    — reduced iteration counts for development validation
#   TIANNARA_SCALE=standard — recommended thresholds
#   TIANNARA_SCALE=full     — certification-grade thresholds (mandatory for final verdict)

alias TiannaraRuntime.OS.Governance.Certification.CampaignOrchestrator

# ── Configuration ──────────────────────────────────────────────

scale = case System.get_env("TIANNARA_SCALE") do
  "quick" -> :quick
  "full" -> :full
  _ -> :standard
end

seed = case System.get_env("TIANNARA_SEED") do
  nil -> 42
  s -> String.to_integer(s)
end

domain = case System.get_env("TIANNARA_DOMAIN") do
  nil -> nil
  "constitutional_integrity" -> :constitutional_integrity
  "runtime_integrity" -> :runtime_integrity
  "scientific_integrity" -> :scientific_integrity
  "evolution_integrity" -> :evolution_integrity
  "planetary_readiness" -> :planetary_readiness
  "civilizational_readiness" -> :civilizational_readiness
  d -> String.to_atom(d)
end

campaign_filter = case System.get_env("TIANNARA_CAMPAIGN_FILTER") do
  nil -> nil
  s -> String.split(s, ",") |> Enum.map(&String.trim/1) |> Enum.map(&String.to_integer/1)
         |> Enum.map(fn n -> "CC-#{String.pad_leading(Integer.to_string(n), 3, "0")}" end)
  _ -> nil
end

config = %{
  scale: scale,
  seed: seed,
  domain: domain,
  campaign_filter: campaign_filter
}

# ── Execution ──────────────────────────────────────────────────

IO.puts("\n" <> String.duplicate("=", 70))
IO.puts("  Tiannara Constitutional OS — 30-Campaign Certification Framework")
IO.puts("  Scale: #{inspect(scale)} | Seed: #{seed}")
if domain, do: IO.puts("  Domain: #{domain}")
if campaign_filter, do: IO.puts("  Campaigns: #{Enum.join(campaign_filter, ", ")}")
IO.puts(String.duplicate("=", 70) <> "\n")

result = cond do
  campaign_filter != nil ->
    CampaignOrchestrator.run_campaigns(campaign_filter, config)

  domain != nil ->
    tier = case domain do
      :constitutional_integrity -> 1
      :runtime_integrity -> 2
      :scientific_integrity -> 3
      :evolution_integrity -> 4
      :planetary_readiness -> 5
      :civilizational_readiness -> 6
    end
    CampaignOrchestrator.run_tier(tier, config)

  true ->
    CampaignOrchestrator.run_all(config)
end

# ── Results ────────────────────────────────────────────────────

case result do
  {:ok, run_result} ->
    IO.puts("\n" <> String.duplicate("=", 70))
    IO.puts("  CERTIFICATION RESULTS")
    IO.puts(String.duplicate("=", 70))
    IO.puts("  Total Campaigns: #{run_result.total_campaigns}")
    IO.puts("  Passed:          #{run_result.passed}")
    IO.puts("  Failed:          #{run_result.failed}")
    IO.puts("  Skipped:         #{run_result.skipped}")
    IO.puts("  Duration:        #{run_result.duration_ms}ms")

    if run_result.readiness_index != nil do
      ri = run_result.readiness_index
      IO.puts("\n  Readiness Index: #{Float.round(ri.overall_score, 3)}")
      IO.puts("  Status:          #{ri.overall_status}")
      IO.puts("\n  Dimension Scores:")
      Enum.each(ri.dimensions, fn d ->
        IO.puts("    #{d.dimension}: #{Float.round(d.score, 3)} (#{d.status})")
      end)
    end

    IO.puts(String.duplicate("=", 70) <> "\n")

    if run_result.failed == 0 do
      IO.puts("  ✓ ALL CAMPAIGNS PASSED — CERTIFIED FOR PLANETARY INTELLIGENCE\n")
    else
      IO.puts("  ✗ #{run_result.failed} CAMPAIGN(S) FAILED\n")
    end

  {:error, reason} ->
    IO.puts("\n  ✗ CERTIFICATION FAILED: #{reason}\n")
end
