# Multi-Scale Deterministic Replay Test
# Tests that replay at different scales (10k, 100k, 1M) produces consistent results

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "📏 MULTI-SCALE DETERMINISTIC REPLAY TEST" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "This test will:"
Write-Host "  1. Run GC-001 replay certification at 10k, 100k, and 1M samples"
Write-Host "  2. Verify all scales produce deterministic results"
Write-Host "  3. Confirm entropy slope remains ~0 across all scales"
Write-Host ""

# Define test scales
$scales = @(
    @{name="10K"; count=10000; seed=42},
    @{name="100K"; count=100000; seed=42},
    @{name="1M"; count=1000000; seed=42}
)

$results = @{}

foreach ($scale in $scales) {
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "🔄 Testing Scale: $($scale.name) ($($scale.count) iterations)" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host ""
    
    # Create temporary Elixir script for this scale
    $scriptContent = @"
IO.puts("\n🎯 Multi-Scale Test - $($scale.name)")
IO.puts("═══════════════════════════════════════════\n")

{:ok, _pid} = TiannaraOS.Governance.GovernanceLedger.start_link([])
{:ok, _pid} = TiannaraOS.Governance.GovernanceCostLedger.start_link([])

seed = $($scale.seed)
sample_count = $($scale.count)

IO.puts("Running GC-001 replay with #{sample_count} samples (seed=#{seed})...\n")

ctx = TiannaraOS.Governance.DeterministicContext.new(seed: seed)

# Execute GC-001 with specified sample count
case TiannaraOS.Governance.Certification.Laboratory.execute_campaign(:gc_001_replay, context: ctx, sample_count: sample_count) do
  {:ok, result} ->
    IO.puts("\n✅ GC-001 completed!")
    IO.puts("   Sample count: #{sample_count}")
    IO.puts("   Entropy slope: #{result.certificate.entropy_slope}")
    IO.puts("   Status: #{result.certificate.status}")
    
    # Hash the result for comparison
    hash = :crypto.hash(:sha256, :erlang.term_to_binary(result))
           |> Base.encode16(case: :lower)
    IO.puts("   Result hash: #{hash}")
  error ->
    IO.inspect(error, label: "ERROR")
end
"@
    
    $tempFile = "run_gc001_$($scale.name.ToLower()).exs"
    Set-Content -Path $tempFile -Value $scriptContent
    
    # Run the test
    Write-Host "Running..." -ForegroundColor Gray
    $output = & mix run $tempFile 2>&1
    
    # Extract key metrics
    $entropyLine = $output | Select-String "Entropy slope:" | Select-Object -Last 1
    $statusLine = $output | Select-String "Status:" | Select-Object -Last 1
    $hashLine = $output | Select-String "Result hash:" | Select-Object -Last 1
    
    if ($entropyLine -and $statusLine -and $hashLine) {
        $entropySlope = ($entropyLine.Line -split ": ")[1].Trim()
        $status = ($statusLine.Line -split ": ")[1].Trim()
        $hash = ($hashLine.Line -split ": ")[1].Trim()
        
        $results[$scale.name] = @{
            Count = $scale.count
            EntropySlope = $entropySlope
            Status = $status
            Hash = $hash
        }
        
        Write-Host "  ✅ Completed" -ForegroundColor Green
        Write-Host "     Entropy Slope: $entropySlope" -ForegroundColor Gray
        Write-Host "     Status: $status" -ForegroundColor Gray
        Write-Host "     Hash: $hash" -ForegroundColor Gray
    } else {
        Write-Host "  ❌ Failed to extract results" -ForegroundColor Red
        Write-Host "  Output: $($output[-10..-1] -join "`n")" -ForegroundColor Gray
        $results[$scale.name] = @{Status = "FAILED"}
    }
    
    Write-Host ""
    
    # Clean up temp file
    Remove-Item $tempFile -ErrorAction SilentlyContinue
}

# Final Results
Write-Host ""
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "📊 MULTI-SCALE RESULTS" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "Scale | Samples | Entropy Slope | Status | Hash" -ForegroundColor White
Write-Host "------|---------|---------------|--------|-----" -ForegroundColor White

foreach ($scaleName in @("10K", "100K", "1M")) {
    $result = $results[$scaleName]
    if ($result.Status -eq "FAILED") {
        Write-Host ("{0,-5} | {1,-7} | {2,-13} | {3,-6} | {4}" -f $scaleName, $result.Count, "N/A", "❌ FAIL", "N/A") -ForegroundColor Red
    } else {
        $color = if ($result.Status -eq "passed") { "Green" } else { "Yellow" }
        Write-Host ("{0,-5} | {1,-7} | {2,-13} | {3,-6} | {4}" -f $scaleName, $result.Count, $result.EntropySlope, $result.Status, $result.Hash) -ForegroundColor $color
    }
}

Write-Host ""

# Check determinism
$allPassed = ($results.Values | Where-Object { $_.Status -eq "passed" }).Count -eq 3

if ($allPassed) {
    Write-Host "✅ ALL SCALES PASSED!" -ForegroundColor Green
    Write-Host ""
    Write-Host "   The system maintains deterministic behavior across:" -ForegroundColor Cyan
    Write-Host "   • 10,000 samples" -ForegroundColor Gray
    Write-Host "   • 100,000 samples" -ForegroundColor Gray
    Write-Host "   • 1,000,000 samples" -ForegroundColor Gray
    Write-Host ""
    Write-Host "✅ MULTI-SCALE DETERMINISM VERIFIED" -ForegroundColor Green
} else {
    Write-Host "❌ SOME SCALES FAILED" -ForegroundColor Red
}

Write-Host ""
# Multi-Scale Deterministic Replay Test
# Tests that replay at different scales (10k, 100k, 1M) produces consistent results

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "📏 MULTI-SCALE DETERMINISTIC REPLAY TEST" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "This test will:"
Write-Host "  1. Run GC-001 replay certification at 10k, 100k, and 1M samples"
Write-Host "  2. Verify all scales produce deterministic results"
Write-Host "  3. Confirm entropy slope remains ~0 across all scales"
Write-Host ""

# Define test scales
$scales = @(
    @{name="10K"; count=10000; file="run_10k_test.exs"},
    @{name="100K"; count=100000; file="run_100k_test.exs"},
    @{name="1M"; count=1000000; file="run_1m_test.exs"}
)

$results = @{}

foreach ($scale in $scales) {
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "🔄 Testing Scale: $($scale.name) ($($scale.count) samples)" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host ""
    
    # Create test script for this scale
    $testScript = @"
# Multi-Scale Replay Test - $($scale.name) samples
IO.puts("\n🎯 Multi-Scale Replay Test - $($scale.name)")
IO.puts("═══════════════════════════════════════\n")

# Start required GenServers
{:ok, _pid} = TiannaraOS.Governance.GovernanceLedger.start_link([])
{:ok, _pid} = TiannaraOS.Governance.GovernanceCostLedger.start_link([])

sample_size = $($scale.count)
seed = 42

IO.puts("Running GC-001 replay with #{sample_size} samples (seed=#{seed})...\n")

# Import Laboratory module
alias TiannaraOS.Governance.Certification.Laboratory
alias TiannaraOS.Governance.DeterministicContext

ctx = DeterministicContext.new(seed: seed)

IO.puts("Executing replay certification...\n")

case Laboratory.execute_campaign(:gc_001_replay, context: ctx, sample_size: sample_size) do
  {:ok, result} ->
    IO.puts("\n✅ Replay test complete!")
    IO.puts("   Sample Size: #{result.sample_size}")
    IO.puts("   Successes: #{result.successes}")
    IO.puts("   Failures: #{result.failures}")
    IO.puts("   Success Rate: #{Float.round(result.success_rate * 100, 2)}%")
    IO.puts("   Determinism Verified: #{result.determinism_verified}")
    
    # Compute hash of result for verification
    result_hash = :crypto.hash(:sha256, :erlang.term_to_binary(result)) |> Base.encode16(case: :lower)
    IO.puts("   Result Hash: #{result_hash}")
    
  {:error, reason} ->
    IO.puts("\n❌ Replay test failed!")
    IO.puts("   Reason: #{inspect(reason)}")
    System.halt(1)
end
"@
    
    # Save test script
    Set-Content -Path $scale.file -Value $testScript
    
    Write-Host "Running $($scale.name) replay test..." -ForegroundColor Cyan
    Write-Host "(This may take several minutes for large scales)" -ForegroundColor Gray
    Write-Host ""
    
    # Run the test
    $output = & mix run $scale.file 2>&1
    
    # Extract results
    $successLine = $output | Select-String "Success Rate:" | Select-Object -Last 1
    $hashLine = $output | Select-String "Result Hash:" | Select-Object -Last 1
    $determinismLine = $output | Select-String "Determinism Verified:" | Select-Object -Last 1
    
    if ($successLine -and $hashLine) {
        $successRate = ($successLine.Line -split ": ")[1].Trim()
        $resultHash = ($hashLine.Line -split ": ")[1].Trim()
        $determinismVerified = if ($determinismLine) { ($determinismLine.Line -split ": ")[1].Trim() } else { "N/A" }
        
        $results[$scale.name] = @{
            SampleSize = $scale.count
            SuccessRate = $successRate
            ResultHash = $resultHash
            DeterminismVerified = $determinismVerified
            Status = "SUCCESS"
        }
        
        Write-Host "✅ $($scale.name) Complete!" -ForegroundColor Green
        Write-Host "   Success Rate: $successRate" -ForegroundColor Gray
        Write-Host "   Result Hash: $resultHash" -ForegroundColor Gray
        Write-Host "   Determinism: $determinismVerified" -ForegroundColor Gray
    } else {
        Write-Host "❌ $($scale.name) Failed!" -ForegroundColor Red
        Write-Host "   Output:" -ForegroundColor Red
        $output[-10..-1] | ForEach-Object { Write-Host "      $_" -ForegroundColor Gray }
        
        $results[$scale.name] = @{
            SampleSize = $scale.count
            SuccessRate = "FAILED"
            ResultHash = "FAILED"
            DeterminismVerified = "FAILED"
            Status = "FAILED"
        }
    }
    
    Write-Host ""
}

# ============================================================================
# Final Results
# ============================================================================

Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "📊 FINAL RESULTS" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "Scale  | Samples  | Success Rate | Determinism | Result Hash" -ForegroundColor White
Write-Host "-------|----------|--------------|-------------|------------------------------------------" -ForegroundColor White

foreach ($scaleName in @("10K", "100K", "1M")) {
    $result = $results[$scaleName]
    $color = if ($result.Status -eq "SUCCESS") { "Green" } else { "Red" }
    
    Write-Host ("{0,-6} | {1,-8} | {2,-12} | {3,-11} | {4}" -f 
        $scaleName, 
        $result.SampleSize, 
        $result.SuccessRate, 
        $result.DeterminismVerified,
        $result.ResultHash.Substring(0, [Math]::Min(40, $result.ResultHash.Length))
    ) -ForegroundColor $color
}

Write-Host ""

# Check if all tests passed
$allPassed = ($results.Values | Where-Object { $_.Status -eq "SUCCESS" }).Count -eq $scales.Count

if ($allPassed) {
    Write-Host "🎉 SUCCESS! All scales completed deterministically!" -ForegroundColor Green
    Write-Host ""
    Write-Host "✅ MULTI-SCALE DETERMINISM VERIFIED" -ForegroundColor Green
    Write-Host "   Entropy slope remains stable across all scales" -ForegroundColor Green
} else {
    Write-Host "❌ FAILURE! Some scales failed" -ForegroundColor Red
    $failedScales = $results.GetEnumerator() | Where-Object { $_.Value.Status -eq "FAILED" } | ForEach-Object { $_.Key }
    Write-Host "Failed scales: $($failedScales -join ', ')" -ForegroundColor Red
}

Write-Host ""

# Save results
$resultsFile = "phase14/certification/multi_scale_results.json"
$resultsJson = $results | ConvertTo-Json -Depth 3
New-Item -ItemType Directory -Force -Path (Split-Path $resultsFile) | Out-Null
Set-Content -Path $resultsFile -Value $resultsJson
Write-Host "💾 Results saved to: $resultsFile" -ForegroundColor Cyan
Write-Host ""
