# REA-1 Operational Cycle 1 Execution
# Usage: mix run scripts/rea1_cycle1.exs

Code.require_file("lib/tiannara/sentinel/operational_observatory.ex")
Code.require_file("lib/tiannara/rea/internal_authority.ex")

IO.puts("\n" <> String.duplicate("=", 80))
IO.puts("🚀 EXECUTING REA-1 OPERATIONAL CYCLE 1")
IO.puts(String.duplicate("=", 80))

proposal = %{
  id: "REA1-001",
  type: :audit_tuning,
  target_audit: :epistemic_rigor,
  description: "Implement adaptive threshold for Epistemic Rigor based on specialist confidence variance.",
  expected_gain: 0.05
}

case Tiannara.REA.InternalAuthority.execute_internal_improvement(proposal) do
  {:ok, :applied} ->
    IO.puts("\n✅ Cycle 1 Applied Successfully.")
    
    # Check Law Confidence evolution
    law_status = Tiannara.Sentinel.OperationalObservatory.track_law_confidence(:structured_forgetting)
    IO.puts("\n📊 Law Confidence: #{law_status.law}")
    IO.puts("   Status: #{law_status.status}")
    IO.puts("   Confidence: #{Float.round(law_status.confidence, 4)}")
    IO.puts("   Evidence: Sim(#{law_status.evidence.simulation_cycles}) | Op(#{law_status.evidence.operational_cycles})")

  {:error, reason} ->
    IO.puts("\n❌ Cycle 1 Failed: #{inspect reason}")
    System.halt(1)
end

IO.puts("\n" <> String.duplicate("=", 80))
IO.puts("🏁 REA-1 CYCLE 1 COMPLETE")
IO.puts(String.duplicate("=", 80) <> "\n")
