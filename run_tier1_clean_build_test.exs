# Phase 14 RC2 - Tier 1 Clean Build Reproducibility Test
# Verifies deterministic reproducibility across multiple clean builds

IO.puts("\n🧊 TIER 1: CLEAN BUILD REPRODUCIBILITY TEST")
IO.puts("══════════════════════════════════════════════\n")

num_runs = 5
hashes = []

Enum.each(1..num_runs, fn run_num ->
  IO.puts("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
  IO.puts("🔨 Run #{run_num}/#{num_runs}: Clean Build\n")
  
  # Step 1: Clean everything
  IO.puts("Step 1: Cleaning build artifacts...")
  
  # Use PowerShell Remove-Item for Windows compatibility
  if File.exists?("_build") do
    System.cmd("powershell", ["-Command", "Remove-Item -Recurse -Force _build -ErrorAction SilentlyContinue"])
  end
  
  if File.exists?("deps") do
    System.cmd("powershell", ["-Command", "Remove-Item -Recurse -Force deps -ErrorAction SilentlyContinue"])
  end
  
  if File.exists?(".elixir_ls") do
    System.cmd("powershell", ["-Command", "Remove-Item -Recurse -Force .elixir_ls -ErrorAction SilentlyContinue"])
  end
  
  :timer.sleep(2000)  # Give filesystem time to complete
  IO.puts("✅ Cleaned _build, deps, .elixir_ls\n")
  
  # Step 2: Recompile
  IO.puts("Step 2: Recompiling from scratch...")
  {_, exit_code} = System.cmd("mix", ["compile"], into: IO.stream(:stdio, :line))
  
  if exit_code != 0 do
    IO.puts("❌ Compilation failed!")
    System.halt(1)
  end
  
  IO.puts("✅ Compilation successful\n")
  
  # Step 3: Generate certification artifacts
  IO.puts("Step 3: Generating certification artifacts...")
  {:ok, result} = TiannaraOS.Governance.PureArtifactGenerator.generate(seed: 42)
  
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
  IO.puts("  Run #{h.run}: #{h.cert_hash}")
end)

IO.puts("\nManifest hashes:")
Enum.each(hashes, fn h ->
  IO.puts("  Run #{h.run}: #{h.manifest_hash}")
end)

IO.puts("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
IO.puts("🎯 Verification Results\n")

if length(unique_cert_hashes) == 1 and length(unique_manifest_hashes) == 1 do
  IO.puts("🎉 PERFECT REPRODUCIBILITY!\n")
  IO.puts("✅ All #{num_runs} runs produced identical certificate hashes")
  IO.puts("✅ All #{num_runs} runs produced identical manifest hashes")
  IO.puts("\n✅ TIER 1 PASSED: Local Reproducibility Verified")
  
  # Save results
  results = %{
    timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
    test_type: "tier1_clean_build_reproducibility",
    num_runs: num_runs,
    all_identical: true,
    certificate_hash: List.first(unique_cert_hashes),
    manifest_hash: List.first(unique_manifest_hashes),
    individual_runs: hashes
  }
  
  output_path = "phase14/certification/replay/tier1_clean_build_results.json"
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
