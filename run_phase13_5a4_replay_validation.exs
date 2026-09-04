# Phase 13.5A.4 - Replay Validation Script
# Verifies that scientific capital can be exactly reproduced from GenerationHistory

alias TiannaraOS.RecursiveCivilizationRunner
alias TiannaraOS.ScientificCapitalPolicy

IO.puts("=" |> String.duplicate(80))
IO.puts("Phase 13.5A.4 - Replay Validation")
IO.puts("=" |> String.duplicate(80))
IO.puts("")

# Run a trial to generate history
output_dir = "data/phase13_5/replay_validation"
File.mkdir_p!(output_dir)

IO.puts("\n📊 Step 1: Running 20-generation trial...")
case RecursiveCivilizationRunner.execute(20, %{
  output_dir: output_dir,
  episodes_per_generation: 200,
  checkpoint_interval: 20,
  enable_adaptation: true
}) do
  {:ok, histories} ->
    IO.puts("   ✅ Trial completed: #{length(histories)} generations")

    # Get current policy
    policy = ScientificCapitalPolicy.current()
    IO.puts("   Using policy version: #{policy.version}")
    IO.puts("   Policy coefficients:")
    IO.puts("     - Discovery value: #{policy.discovery_value}")
    IO.puts("     - Theory value: #{policy.theory_value}")
    IO.puts("     - Unknown resolution value: #{policy.unknown_resolution_value}")

    # Perform replay validation
    IO.puts("\n🔄 Step 2: Performing replay validation...")
    case ScientificCapitalPolicy.replay(histories, policy.version) do
      {:ok, :replay_successful} ->
        IO.puts("   ✅ REPLAY VALIDATION PASSED")
        IO.puts("   All #{length(histories)} generations reproduced exactly")
        IO.puts("")
        IO.puts("   Verification:")
        Enum.each(histories, fn history ->
          transactions = %{
            discoveries_made: history.discoveries_made,
            theories_formed: history.theories_formed,
            unknowns_resolved: history.unknowns_resolved
          }
          expected_delta = ScientificCapitalPolicy.calculate_delta(policy, transactions)
          recorded_delta = history.scientific_capital

          match = if expected_delta == recorded_delta, do: "✅", else: "❌"
          IO.puts("     #{match} Gen #{history.generation_number}: Expected #{expected_delta}, Recorded #{recorded_delta}")
        end)

        IO.puts("\n" <> ("=" |> String.duplicate(80)))
        IO.puts("Replay Validation Complete - EXACT MATCH for all generations")
        IO.puts("=" |> String.duplicate(80))

      {:error, violations} ->
        IO.puts("   ❌ REPLAY VALIDATION FAILED")
        IO.puts("   Found #{length(violations)} violations:")
        Enum.each(violations, fn violation ->
          IO.puts("     Generation #{violation.generation}:")
          IO.puts("       Expected delta: #{violation.expected_delta}")
          IO.puts("       Recorded delta: #{violation.recorded_delta}")
          IO.puts("       Difference: #{violation.difference}")
        end)

        IO.puts("\n" <> ("=" |> String.duplicate(80)))
        IO.puts("Replay Validation Failed - Mismatches detected")
        IO.puts("=" |> String.duplicate(80))
    end

  {:error, reason} ->
    IO.puts("   ❌ Trial failed: #{inspect(reason)}")
end
