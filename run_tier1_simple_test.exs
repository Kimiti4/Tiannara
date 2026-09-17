# Phase 14 RC2 - Tier 1 Deterministic Reproducibility Test
# Verifies that same seed produces identical hashes across multiple runs

IO.puts("\n🧊 TIER 1: DETERMINISTIC REPRODUCIBILITY TEST")
IO.puts("══════════════════════════════════════════════\n")

num_runs = 5
seed = 42
hashes = []

Enum.each(1..num_runs, fn run_num ->
  IO.puts("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
  IO.puts("🔨 Run #{run_num}/#{num_runs}: Generate Artifacts (seed=#{seed})\n")
  
  # Generate certification artifacts
  IO.puts("Generating certification artifacts...")
  {:ok, result} = TiannaraOS.Governance.PureArtifactGenerator.generate(seed: seed)
  
  cert_hash = result.hashes.certificate_sha256
  manifest_hash = result.hashes.manifest_sha256
  
  IO.puts("✅ Certificate SHA-256: #{cert_hash}")
  IO.puts("✅ Manifest SHA-256: #{manifest_hash}\n")
  
  hashes = hashes ++ [%{
    run: run_num,
    cert_hash: cert_hash,
    manifest_hash: manifest_hash
  }]
end)

IO.puts("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
IO.puts("📊 Analyzing Results\n")

# Check if all certificate hashes match
cert_hashes = Enum.map(hashes, & &1.cert_hash)
unique_cert_hashes = Enum.uniq(cert_hashes)

manifest_hashes = Enum.map(hashes, & &1.manifest_hash)
unique_manifest_hashes = Enum.uniq(manifest_hashes)

IO.puts("Certificate hashes:")
Enum.each(hashes, fn h ->
  marker = if h.run == 1, do: " ← Baseline", else: ""
  IO.puts("  Run #{h.run}: #{h.cert_hash}#{marker}")
end)

IO.puts("\nManifest hashes:")
Enum.each(hashes, fn h ->
  marker = if h.run == 1, do: " ← Baseline", else: ""
  IO.puts("  Run #{h.run}: #{h.manifest_hash}#{marker}")
end)

IO.puts("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
IO.puts("🎯 Verification Results\n")

if length(unique_cert_hashes) == 1 and length(unique_manifest_hashes) == 1 do
  IO.puts("🎉 PERFECT REPRODUCIBILITY!\n")
  IO.puts("✅ All #{num_runs} runs produced identical certificate hashes")
  IO.puts("✅ All #{num_runs} runs produced identical manifest hashes")
  IO.puts("\n✅ TIER 1 PASSED: Deterministic Reproducibility Verified")
  
  # Save results
  results = %{
    timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
    test_type: "tier1_deterministic_reproducibility",
    seed: seed,
    num_runs: num_runs,
    all_identical: true,
    certificate_hash: List.first(unique_cert_hashes),
    manifest_hash: List.first(unique_manifest_hashes),
    individual_runs: hashes
  }
  
  output_path = "phase14/certification/replay/tier1_deterministic_results.json"
  File.mkdir_p!(Path.dirname(output_path))
  File.write!(output_path, Jason.encode!(results, pretty: true))
  
  IO.puts("\n💾 Results saved to: #{output_path}")
else
  IO.puts("❌ REPRODUCIBILITY FAILED!\n")
  IO.puts("Unique certificate hashes: #{length(unique_cert_hashes)}")
  IO.puts("Unique manifest hashes: #{length(unique_manifest_hashes)}")
  IO.puts("\n❌ TIER 1 FAILED: Non-deterministic behavior detected")
  System.halt(1)
end
