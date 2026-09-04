# Phase 13.5A - Validator Audit Execution Script
# Validates the validation framework before running expensive statistical trials

alias TiannaraOS.ValidatorAudit

IO.puts("=" |> String.duplicate(80))
IO.puts("Phase 13.5A - Validation of the Validator")
IO.puts("=" |> String.duplicate(80))
IO.puts("")
IO.puts("This audit will verify:")
IO.puts("  1. Seed Independence (10 trials)")
IO.puts("  2. Metric Independence (code analysis)")
IO.puts("  3. Reward Leakage Detection (pattern scanning)")
IO.puts("  4. Temporal Leakage Verification (20-gen trial)")
IO.puts("  5. Conservation Law Verification (20-gen trial)")
IO.puts("")
IO.puts("Expected duration: ~15 minutes")
IO.puts("")

# Execute full validator audit
case ValidatorAudit.execute_full_audit(%{
  output_dir: "data/phase13_5/audit",
  num_seed_trials: 10,
  generations_per_trial: 20
}) do
  {:ok, audit_report} ->
    IO.puts("\n" <> ("=" |> String.duplicate(80)))
    IO.puts("✅ Validator Audit Complete!")
    IO.puts("=" |> String.duplicate(80))
    IO.puts("")
    
    checks = audit_report.check_results
    
    IO.puts("📊 Check Results:")
    IO.puts("  1. Seed Independence: #{case checks.seed_independence.status do :pass -> "✅ PASS"; :fail -> "❌ FAIL"; :partial -> "⚠️ PARTIAL"; _ -> "🔴 ERROR" end}")
    IO.puts("  2. Metric Independence: #{case checks.metric_independence.status do :pass -> "✅ PASS"; :fail -> "❌ FAIL"; :partial -> "⚠️ PARTIAL"; _ -> "🔴 ERROR" end}")
    IO.puts("  3. Reward Leakage: #{case checks.reward_leakage.status do :pass -> "✅ PASS"; :fail -> "❌ FAIL"; :partial -> "⚠️ PARTIAL"; _ -> "🔴 ERROR" end}")
    IO.puts("  4. Temporal Leakage: #{case checks.temporal_leakage.status do :pass -> "✅ PASS"; :fail -> "❌ FAIL"; :partial -> "⚠️ PARTIAL"; _ -> "🔴 ERROR" end}")
    IO.puts("  5. Conservation Laws: #{case checks.conservation_laws.status do :pass -> "✅ PASS"; :fail -> "❌ FAIL"; :partial -> "⚠️ PARTIAL"; _ -> "🔴 ERROR" end}")
    IO.puts("")
    IO.puts("Overall Status: #{case audit_report.overall_status do :pass -> "✅ PASS - Ready for Full Validation"; :fail -> "❌ FAIL - Fix Framework First"; _ -> "⚠️ PARTIAL - Proceed with Caution" end}")
    IO.puts("")
    
    case audit_report.overall_status do
      :pass ->
        IO.puts("🎉 VALIDATOR AUDIT PASSED!")
        IO.puts("")
        IO.puts("The validation framework is scientifically rigorous and ready for")
        IO.puts("full-scale statistical trials.")
        IO.puts("")
        IO.puts("Next steps:")
        IO.puts("  1. Review VALIDATOR_AUDIT.md for detailed findings")
        IO.puts("  2. Execute progressive validation:")
        IO.puts("     - Phase 1: 10 adaptive + 10 static trials")
        IO.puts("     - Phase 2: 30 adaptive + 30 static trials")
        IO.puts("     - Phase 3: 100 adaptive + 100 static trials (if stable)")
        IO.puts("")
        
      :fail ->
        IO.puts("❌ VALIDATOR AUDIT FAILED!")
        IO.puts("")
        IO.puts("Critical issues detected in the validation framework.")
        IO.puts("Do NOT proceed with expensive statistical trials until fixed.")
        IO.puts("")
        IO.puts("Review VALIDATOR_AUDIT.md for specific failures and fixes needed.")
        IO.puts("")
        
      _ ->
        IO.puts("⚠️  VALIDATOR AUDIT PARTIAL")
        IO.puts("")
        IO.puts("Some checks passed, others showed warnings.")
        IO.puts("Review VALIDATOR_AUDIT.md before proceeding.")
        IO.puts("")
    end
    
    IO.puts("📄 Output files:")
    IO.puts("  data/phase13_5/audit/VALIDATOR_AUDIT.md")
    IO.puts("")

  {:error, reason} ->
    IO.puts("\n❌ Validator audit failed: #{inspect(reason)}")
end
