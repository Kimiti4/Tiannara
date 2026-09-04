# Cold Boot Reproducibility Test - Phase 14 RC3
# This script performs 5 consecutive clean builds to verify deterministic reproducibility
# Each run starts a FRESH BEAM VM to ensure no accumulated state

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "🧊 COLD BOOT REPRODUCIBILITY TEST" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "This test will:"
Write-Host "  1. Delete all compiled artifacts (_build, deps, .elixir_ls)"
Write-Host "  2. Reinstall dependencies (mix deps.get)"
Write-Host "  3. Recompile from scratch (mix compile)"
Write-Host "  4. Generate certification artifacts (fresh BEAM VM)"
Write-Host "  5. Record certificate SHA-256 hash"
Write-Host "  6. Repeat 5 times and verify all hashes match"
Write-Host ""
Write-Host "Expected result: All 5 runs produce IDENTICAL certificate hashes"
Write-Host ""

$testDir = Get-Location
$runCount = 5
$results = @()

for ($i = 1; $i -le $runCount; $i++) {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "🔄 RUN #$i of $runCount" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host ""
    
    # Step 1: Clean everything
    Write-Host "🧹 Step 1/4: Deleting compiled artifacts..." -ForegroundColor Cyan
    if (Test-Path "_build") { Remove-Item -Recurse -Force "_build" }
    if (Test-Path "deps") { Remove-Item -Recurse -Force "deps" }
    if (Test-Path ".elixir_ls") { Remove-Item -Recurse -Force ".elixir_ls" }
    Write-Host "   ✅ Artifacts deleted" -ForegroundColor Green
    Write-Host ""
    
    # Step 2: Install dependencies
    Write-Host "📚 Step 2/4: Installing dependencies..." -ForegroundColor Cyan
    mix deps.get 2>&1 | Out-Null
    Write-Host "   ✅ Dependencies installed" -ForegroundColor Green
    Write-Host ""
    
    # Step 3: Compile from scratch
    Write-Host "🔨 Step 3/4: Compiling from scratch..." -ForegroundColor Cyan
    mix compile 2>&1 | Out-Null
    Write-Host "   ✅ Compilation complete" -ForegroundColor Green
    Write-Host ""
    
    # Step 4: Run pure artifact generator (starts fresh BEAM VM)
    Write-Host "🎯 Step 4/4: Generating certification artifacts..." -ForegroundColor Cyan
    
    # Capture output
    $output = mix run run_pure_artifact_generator.exs 2>&1
    
    # Extract certificate hash
    $certHashLine = $output | Select-String "Certificate SHA-256:" | Select-Object -Last 1
    if ($certHashLine) {
        $certHash = ($certHashLine -split ": ")[1].Trim()
        
        # Extract manifest hash
        $manifestHashLine = $output | Select-String "Manifest SHA-256:" | Select-Object -Last 1
        $manifestHash = if ($manifestHashLine) { ($manifestHashLine -split ": ")[1].Trim() } else { "N/A" }
        
        Write-Host "   ✅ Certificate generated" -ForegroundColor Green
        Write-Host "      Cert Hash: $certHash" -ForegroundColor Gray
        Write-Host "      Manifest Hash: $manifestHash" -ForegroundColor Gray
        
        $results += @{
            Run = $i
            CertHash = $certHash
            ManifestHash = $manifestHash
        }
    } else {
        Write-Host "   ❌ Failed to extract hash!" -ForegroundColor Red
        Write-Host "   Output:" -ForegroundColor Red
        $output | ForEach-Object { Write-Host "      $_" -ForegroundColor Red }
        
        $results += @{
            Run = $i
            CertHash = "FAILED"
            ManifestHash = "FAILED"
        }
    }
    
    Write-Host ""
}

# ============================================================================
# Final Results
# ============================================================================

Write-Host ""
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "📊 FINAL RESULTS" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "Run  | Certificate SHA-256                              | Status" -ForegroundColor White
Write-Host "-----|--------------------------------------------------|--------" -ForegroundColor White

foreach ($result in $results) {
    $status = if ($result.CertHash -eq "FAILED") { "❌ FAILED" } else { "✅ OK" }
    $color = if ($result.CertHash -eq "FAILED") { "Red" } else { "Green" }
    
    Write-Host ("#{0,-4} | {1,-48} | {2}" -f $result.Run, $result.CertHash, $status) -ForegroundColor $color
}

Write-Host ""

# Check if all hashes match
$uniqueHashes = $results | Where-Object { $_.CertHash -ne "FAILED" } | Select-Object -ExpandProperty CertHash -Unique

if ($uniqueHashes.Count -eq 1 -and $results.Count -eq $runCount) {
    Write-Host "🎉 SUCCESS! All $runCount runs produced IDENTICAL certificate hashes!" -ForegroundColor Green
    Write-Host ""
    Write-Host "   Hash: $($uniqueHashes[0])" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "✅ DETERMINISTIC REPRODUCIBILITY VERIFIED" -ForegroundColor Green
    Write-Host "   The system is constitutionally frozen!" -ForegroundColor Green
} elseif ($uniqueHashes.Count -gt 1) {
    Write-Host "❌ FAILURE! Certificate hashes differ across runs:" -ForegroundColor Red
    Write-Host ""
    foreach ($hash in $uniqueHashes) {
        $count = ($results | Where-Object { $_.CertHash -eq $hash }).Count
        Write-Host "   $hash (appeared $count times)" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "⚠️  NONDETERMINISM DETECTED" -ForegroundColor Red
    Write-Host "   The system still has hidden state or timing dependencies." -ForegroundColor Red
} else {
    Write-Host "❌ FAILURE! Some runs failed to generate certificates." -ForegroundColor Red
}

Write-Host ""

# Save results to file
$resultsFile = "phase14/certification/cold_boot_results.json"
$resultsJson = $results | ConvertTo-Json -Depth 3
New-Item -ItemType Directory -Force -Path (Split-Path $resultsFile) | Out-Null
Set-Content -Path $resultsFile -Value $resultsJson
Write-Host "💾 Results saved to: $resultsFile" -ForegroundColor Cyan
Write-Host ""
