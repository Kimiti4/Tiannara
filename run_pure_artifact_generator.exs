# Pure Artifact Generator - Multi-Seed Test Support
IO.puts("\n🎯 Pure Artifact Generation")
IO.puts("═══════════════════════════════════════════\n")

# Start required GenServers
{:ok, _pid} = TiannaraOS.Governance.GovernanceLedger.start_link([])
{:ok, _pid} = TiannaraOS.Governance.GovernanceCostLedger.start_link([])

# Accept seed from command line argument or default to 42
seed = case System.get_env("SEED") do
  nil -> 42
  str -> String.to_integer(str)
end

IO.puts("Generating certification package (seed=#{seed})...\n")

case TiannaraOS.Governance.PureArtifactGenerator.generate(seed: seed) do
  {:ok, result} ->
    IO.puts("\n✅ Pure artifact generation successful!")
    IO.puts("   Certificate SHA-256: #{result.hashes.certificate_sha256}")
    IO.puts("   Manifest SHA-256: #{result.hashes.manifest_sha256}")
    IO.puts("   Output directory: #{result.output_dir}")
    
    # Save hash for comparison
    hash_file = "phase14/certification/run_hash_#{seed}.txt"
    File.write!(hash_file, result.hashes.certificate_sha256)
    IO.puts("   Hash saved to: #{hash_file}")
    
  {:error, reason} ->
    IO.puts("\n❌ Pure artifact generation failed!")
    IO.puts("   Reason: #{inspect(reason)}")
    System.halt(1)
end
