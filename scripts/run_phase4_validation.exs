# Run with: mix run scripts/run_phase4_validation.exs
#
# Produces a real validation report for Phase 4.
# No simulated results. No hardcoded values.

Mix.shell().info("\n=== Tiannara Phase 4 Validation Campaign ===\n")

results = %{}

# 1. Property tests
Mix.shell().info("\n[1/5] Running Phase 4 property tests...")
{_out, prop_status} = System.cmd("mix", [
  "test",
  "test/tiannara/discovery/",
  "test/tiannara/engineering/",
  "test/tiannara/simulation/",
  "test/tiannara/hai/",
  "--only", "property",
  "--trace"
], into: IO.stream(:stdio, :line), stderr_to_stdout: true)
results = Map.put(results, :properties, prop_status)

# 2. Integration tests
Mix.shell().info("\n[2/5] Running Phase 4 integration tests...")
{_out, int_status} = System.cmd("mix", [
  "test",
  "test/tiannara/phase4/integration/",
  "--trace"
], into: IO.stream(:stdio, :line), stderr_to_stdout: true)
results = Map.put(results, :integration, int_status)

# 3. Chaos tests
Mix.shell().info("\n[3/5] Running Phase 4 chaos tests...")
{_out, chaos_status} = System.cmd("mix", [
  "test",
  "test/tiannara/phase4/chaos/",
  "--trace",
  "--timeout", "60000"
], into: IO.stream(:stdio, :line), stderr_to_stdout: true)
results = Map.put(results, :chaos, chaos_status)

# 4. Constitutional compliance audit
Mix.shell().info("\n[4/5] Running constitutional compliance audit...")
{_out, const_status} = System.cmd("mix", [
  "test",
  "test/tiannara/phase4/constitutional/",
  "--trace"
], into: IO.stream(:stdio, :line), stderr_to_stdout: true)
results = Map.put(results, :constitutional, const_status)

# 5. Adversarial tests
Mix.shell().info("\n[5/5] Running adversarial tests...")
{_out, adv_status} = System.cmd("mix", [
  "test",
  "test/tiannara/phase4/adversarial/",
  "--trace"
], into: IO.stream(:stdio, :line), stderr_to_stdout: true)
results = Map.put(results, :adversarial, adv_status)

# Summary
Mix.shell().info("\n=== PHASE 4 VALIDATION SUMMARY ===")
all_passed = Enum.all?(results, fn {_k, v} -> v == 0 end)

Enum.each(results, fn {suite, exit_code} ->
  status = if exit_code == 0, do: "PASS", else: "FAIL (exit #{exit_code})"
  Mix.shell().info("  #{suite}: #{status}")
end)

if all_passed do
  Mix.shell().info("\nPhase 4 VALIDATED. All test suites passed.")
  Mix.shell().info("   Phase 4 is constitutionally complete.")
  Mix.shell().info("   Proceed to Phase 4.X refinements or Phase 5.")
else
  Mix.shell().info("\nPhase 4 validation INCOMPLETE.")
  Mix.shell().info("   Do NOT declare Phase 4 complete until all suites pass.")
  System.halt(1)
end
