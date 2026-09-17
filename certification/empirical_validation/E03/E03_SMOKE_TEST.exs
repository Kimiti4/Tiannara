## E03 SMOKE TEST — harness wiring confirmation.
## This is NOT an E03 experiment. It does NOT write to the canonical
## E03_RUN_LEDGER.jsonl. It writes to a clearly-labeled smoke-test ledger.
## It does NOT invoke stabilizers (CONTROL A no-op hook).
## It does ONE LongHorizon cycle (cycles: 1) and confirms the harness
## boots, writes run_start + run_end records, and returns cleanly.

Mix.start()
Application.ensure_all_started(:logger)
Logger.configure(level: :warning)  # quiet the pre-existing warnings

# Start the Ecology GenServer so the harness's ecology snapshot returns
# real data (not the :ecology_not_running fallback).
{:ok, _} = Tiannara.Ecology.start_link([])

# Run the harness with a clearly-labeled smoke-test ledger path.
smoke_ledger = "certification/empirical_validation/E03/runs/E03_SMOKE_TEST_LEDGER.jsonl"
File.mkdir_p!("certification/empirical_validation/E03/runs")
# If a previous smoke test left a ledger, remove it so we see only this run.
File.rm(smoke_ledger)

result = Tiannara.EmpiricalValidation.E03.Harness.run(
  condition: :control_a,
  seed: 42,
  experiment_id: "E03-SMOKE-TEST",
  cycles: 1,
  ledger_path: smoke_ledger,
  stabilizer_hook: fn _tick, _snap -> nil end  # CONTROL A: no-op
)

IO.puts("=== E03 SMOKE TEST RESULT ===")
IO.puts("ledger_path: #{result.ledger_path}")
IO.puts("lineage_count: #{length(result.lineage)}")
IO.puts("trajectory keys: #{inspect(Map.keys(result.trajectory))}")
IO.puts("")

# Verify the ledger file exists and has run_start + run_end records.
if File.exists?(smoke_ledger) do
  lines = smoke_ledger |> File.read!() |> String.split("\n", trim: true)
  IO.puts("Ledger lines: #{length(lines)}")
  Enum.each(lines, fn line ->
    case Jason.decode(line) do
      {:ok, rec} -> IO.puts("  - type=#{rec["type"]} experiment_id=#{rec["experiment_id"]}")
      _ -> :skip
    end
  end)
  IO.puts("")
  IO.puts("SMOKE TEST: PASS (harness boots, writes run_start + run_end, returns cleanly)")
else
  IO.puts("SMOKE TEST: FAIL (ledger file not created)")
  System.halt(1)
end
