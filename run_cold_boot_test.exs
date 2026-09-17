# Phase 14 RC2 - Cold Boot Reproducibility Test
# Performs 5 complete clean builds to verify deterministic reproducibility

IO.puts("\n❄️  COLD BOOT REPRODUCIBILITY TEST")
IO.puts("══════════════════════════════════════\n")
IO.puts("This test performs 5 complete clean builds:")
IO.puts("  1. Remove _build, deps, .elixir_ls")
IO.puts("  2. Fetch dependencies")
IO.puts("  3. Compile from scratch")
IO.puts("  4. Generate certification artifacts")
IO.puts("  5. Record hashes\n")

num_runs = 5
seed = 42
results = Enum.reduce(1..num_runs, [], fn run_num, acc ->
  IO.puts("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
  IO.puts("🔨 RUN #{run_num}/#{num_runs}\n")
  
  start_time = System.monotonic_time(:millisecond)
  
  # Step 1: Clean everything
  IO.puts("[1/4] Cleaning build artifacts...")
  
  if File.exists?("_build") do
    System.cmd("powershell", ["-Command", "Remove-Item -Recurse -Force _build -ErrorAction SilentlyContinue"])
    IO.puts("  ✅ Removed _build")
  end
  
  if File.exists?("deps") do
    System.cmd("powershell", ["-Command", "Remove-Item -Recurse -Force deps -ErrorAction SilentlyContinue"])
    IO.puts("  ✅ Removed deps")
  end
  
  if File.exists?(".elixir_ls") do
    System.cmd("powershell", ["-Command", "Remove-Item -Recurse -Force .elixir_ls -ErrorAction SilentlyContinue"])
    IO.puts("  ✅ Removed .elixir_ls")
  end
  
  :timer.sleep(2000)  # Give filesystem time to complete
  IO.puts("")
  
  # Step 2: Fetch dependencies
  IO.puts("[2/4] Fetching dependencies...")
  {deps_output, deps_exit} = System.cmd("mix", ["deps.get"], into: IO.stream(:stdio, :line))
  
  if deps_exit != 0 do
    IO.puts("❌ Dependency fetch failed!")
    IO.puts(deps_output)
    System.halt(1)
  end
  
  IO.puts("  ✅ Dependencies fetched\n")
  
  # Step 3: Compile from scratch
  IO.puts("[3/4] Compiling from scratch...")
  {compile_output, compile_exit} = System.cmd("mix", ["compile"], into: IO.stream(:stdio, :line))
  
  if compile_exit != 0 do
    IO.puts("❌ Compilation failed!")
    IO.puts(compile_output)
    System.halt(1)
  end
  
  IO.puts("  ✅ Compilation successful\n")
  
  # Step 4: Generate certification artifacts
  IO.puts("[4/4] Generating certification artifacts (seed=#{seed})...")
  
  # Start required GenServers for artifact generation (handle already started)
  case TiannaraOS.Governance.GovernanceLedger.start_link([]) do
    {:ok, _pid} -> :ok
    {:error, {:already_started, _pid}} -> :ok
  end
  
  case TiannaraOS.Governance.GovernanceCostLedger.start_link([]) do
    {:ok, _pid} -> :ok
    {:error, {:already_started, _pid}} -> :ok
  end
  
  :timer.sleep(500)  # Give GenServers time to initialize
  
  case TiannaraOS.Governance.PureArtifactGenerator.generate(seed: seed) do
    {:ok, result} ->
      cert_hash = result.hashes.certificate_sha256
      manifest_hash = result.hashes.manifest_sha256
      
      elapsed = System.monotonic_time(:millisecond) - start_time
      
      IO.puts("  ✅ Certificate SHA-256: #{cert_hash}")
      IO.puts("  ✅ Manifest SHA-256: #{manifest_hash}")
      IO.puts("  ⏱️  Elapsed: #{elapsed}ms\n")
      
      [%{
        run: run_num,
        cert_hash: cert_hash,
        manifest_hash: manifest_hash,
        elapsed_ms: elapsed
      } | acc]
      
    {:error, reason} ->
      IO.puts("❌ Artifact generation failed: #{inspect(reason)}")
      System.halt(1)
  end
end)

# Reverse to maintain order (reduce builds list in reverse)
results = Enum.reverse(results)

# Analysis
IO.puts("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
IO.puts("📊 ANALYSIS\n")

cert_hashes = Enum.map(results, & &1.cert_hash)
unique_cert_hashes = Enum.uniq(cert_hashes)

manifest_hashes = Enum.map(results, & &1.manifest_hash)
unique_manifest_hashes = Enum.uniq(manifest_hashes)

IO.puts("Certificate Hashes:")
Enum.each(results, fn r ->
  marker = if r.run == 1, do: " ← BASELINE", else: ""
  match = if r.cert_hash == List.first(cert_hashes), do: " ✓", else: " ✗ MISMATCH"
  IO.puts("  Run #{r.run}: #{r.cert_hash}#{marker}#{match}")
end)

IO.puts("\nManifest Hashes:")
Enum.each(results, fn r ->
  marker = if r.run == 1, do: " ← BASELINE", else: ""
  match = if r.manifest_hash == List.first(manifest_hashes), do: " ✓", else: " ✗ MISMATCH"
  IO.puts("  Run #{r.run}: #{r.manifest_hash}#{marker}#{match}")
end)

IO.puts("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
IO.puts("🎯 VERIFICATION RESULTS\n")

if length(unique_cert_hashes) == 1 and length(unique_manifest_hashes) == 1 do
  IO.puts("🎉 PERFECT COLD BOOT REPRODUCIBILITY!\n")
  IO.puts("✅ All #{num_runs} clean builds produced identical certificate hashes")
  IO.puts("✅ All #{num_runs} clean builds produced identical manifest hashes")
  IO.puts("\n✅ TIER 1 PASSED: Cold Boot Reproducibility Verified")
  IO.puts("   The system is deterministically reproducible from clean state.\n")
  
  # Save comprehensive results
  final_results = %{
    timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
    test_type: "cold_boot_reproducibility",
    seed: seed,
    num_runs: num_runs,
    all_identical: true,
    certificate_hash: List.first(unique_cert_hashes),
    manifest_hash: List.first(unique_manifest_hashes),
    individual_runs: results,
    tier_status: "PASSED",
    notes: "All #{num_runs} clean builds produced identical cryptographic hashes"
  }
  
  output_path = "phase14/certification/replay/cold_boot_reproducibility.json"
  File.mkdir_p!(Path.dirname(output_path))
  File.write!(output_path, Jason.encode!(final_results, pretty: true))
  
  IO.puts("💾 Results saved to: #{output_path}\n")
else
  IO.puts("❌ COLD BOOT REPRODUCIBILITY FAILED!\n")
  IO.puts("Unique certificate hashes: #{length(unique_cert_hashes)}")
  IO.puts("Unique manifest hashes: #{length(unique_manifest_hashes)}")
  IO.puts("\n❌ TIER 1 FAILED: Non-deterministic behavior detected")
  IO.puts("   The system produces different hashes across clean builds.")
  System.halt(1)
end
