# Meta-Certification (Certification of Certification) - Phase 14 RC3
IO.puts("\n🏆 Generating Meta-Certification...\n")

# Start required GenServers
{:ok, _pid} = TiannaraOS.Governance.GovernanceLedger.start_link([])
{:ok, _pid} = TiannaraOS.Governance.GovernanceCostLedger.start_link([])

# Generate meta-certification
case TiannaraOS.Governance.CertificationCertificate.generate() do
  {:ok, cert} ->
    IO.puts("\n✅ Meta-certification generated successfully!")
    IO.puts("   Recursive certification chain complete.")
    
  {:error, reason} ->
    IO.puts("\n❌ Meta-certification failed!")
    IO.puts("Reason: #{reason}")
    System.halt(1)
end
