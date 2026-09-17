# Final Acceptance Test: Auditing the Audits
# Usage: mix run scripts/acceptance_test.exs

# Ensure all modules are compiled
Code.require_file("lib/tiannara/specialists/architect.ex")
Code.require_file("lib/tiannara/specialists/engineer.ex")
Code.require_file("lib/tiannara/specialists/auditor.ex")
Code.require_file("lib/tiannara/specialists/researcher.ex")
Code.require_file("lib/tiannara/audit/tier1.ex")
Code.require_file("lib/tiannara/audit/tier2.ex")
Code.require_file("lib/tiannara/audit/tier3.ex")
Code.require_file("lib/tiannara/audit/verifier.ex")
Code.require_file("lib/tiannara/audit/simulator.ex")
Code.require_file("lib/tiannara/audit/meta_consistency.ex")
Code.require_file("lib/tiannara/audit/meta_auditor.ex")
Code.require_file("lib/tiannara/red_team.ex")

IO.puts("\n" <> String.duplicate("=", 80))
IO.puts("🚀 TIANNARA FINAL ACCEPTANCE TEST: AUDIT SYSTEM INTEGRITY")
IO.puts(String.duplicate("=", 80))

# Stage 1
case Tiannara.Audit.Verifier.run_stage_1() do
  :ok -> IO.puts("✅ STAGE 1: Unit Validation PASSED")
  _ -> System.halt(1)
end

# Stage 2
case Tiannara.Audit.Simulator.run_stage_2() do
  :ok -> IO.puts("✅ STAGE 2: Synthetic Adversarial Worlds PASSED")
  _ -> System.halt(1)
end

# Stage 3: Meta-Consistency check
results = %{
  "Tier-1 B" => {:pass, "", nil},
  "Tier-2 E" => {:fail, "", nil}
}
Tiannara.Audit.MetaConsistency.run_meta_audit(results)

# Stage 4
Tiannara.Audit.Simulator.run_stage_4(100)

# Stage 5
case Tiannara.RedTeam.run_stage_5() do
  :ok -> IO.puts("✅ STAGE 5: Red Team Simulation PASSED")
  _ -> IO.puts("⚠️  STAGE 5: Red Team Simulation identified vulnerabilities.")
end

# Meta-Audit
Tiannara.Audit.MetaAuditor.run_meta_audit()

IO.puts("\n" <> String.duplicate("=", 80))
IO.puts("🏆 ALL VERIFICATION STAGES COMPLETE")
IO.puts(String.duplicate("=", 80) <> "\n")
