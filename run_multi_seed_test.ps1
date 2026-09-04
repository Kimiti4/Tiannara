# Multi-Seed Deterministic Replay Test
# Tests that different seeds produce different certificates,
# but the same seed always produces the same certificate.

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "🌱 MULTI-SEED DETERMINISTIC REPLAY TEST" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "This test will:"
Write-Host "  1. Run certification with 4 different seeds (42, 123, 999, 7777)"
Write-Host "  2. Verify each seed produces a DIFFERENT certificate"
Write-Host "  3. Rerun each seed to verify it produces the SAME certificate"
Write-Host ""

# Define test seeds
$seeds = @(42, 123, 999, 7777)
$results = @{}

# First pass: Generate certificates for each seed
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "📊 PASS 1: Initial Certificate Generation" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

foreach ($seed in $seeds) {
    Write-Host "🔄 Testing Seed $seed..." -ForegroundColor Cyan
    
    # Start fresh BEAM VM by running mix run with SEED environment variable
    $env:SEED = $seed
    $output = mix run run_pure_artifact_generator.exs 2>&1 | Select-String "Certificate SHA-256:" | Select-Object -Last 1
    Remove-Item Env:SEED
    
    if ($output) {
        $certHash = ($output -split ": ")[1].Trim()
        $results[$seed] = @{
            FirstRun = $certHash
            SecondRun = $null
            Match = $false
        }
        Write-Host "   ✅ Seed $seed → $certHash" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Failed to generate certificate for seed $seed" -ForegroundColor Red
        $results[$seed] = @{
            FirstRun = "FAILED"
            SecondRun = $null
            Match = $false
        }
    }
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "📊 PASS 2: Reproducibility Verification" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

# Second pass: Verify each seed reproduces the same hash
foreach ($seed in $seeds) {
    Write-Host "🔄 Verifying Seed $seed reproducibility..." -ForegroundColor Cyan
    
    $env:SEED = $seed
    $output = mix run run_pure_artifact_generator.exs 2>&1 | Select-String "Certificate SHA-256:" | Select-Object -Last 1
    Remove-Item Env:SEED
    
    if ($output) {
        $certHash = ($output -split ": ")[1].Trim()
        $results[$seed].SecondRun = $certHash
        $results[$seed].Match = ($results[$seed].FirstRun -eq $certHash)
        
        if ($results[$seed].Match) {
            Write-Host "   ✅ Seed $seed reproduced identically" -ForegroundColor Green
            Write-Host "      Hash: $certHash" -ForegroundColor Gray
        } else {
            Write-Host "   ❌ Seed $seed produced DIFFERENT hash!" -ForegroundColor Red
            Write-Host "      First:  $($results[$seed].FirstRun)" -ForegroundColor Yellow
            Write-Host "      Second: $certHash" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   ❌ Failed to reproduce certificate for seed $seed" -ForegroundColor Red
        $results[$seed].SecondRun = "FAILED"
        $results[$seed].Match = $false
    }
}

Write-Host ""
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "📊 FINAL RESULTS" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "Seed | First Run                                      | Second Run                                     | Match" -ForegroundColor White
Write-Host "-----|------------------------------------------------|------------------------------------------------|------" -ForegroundColor White

foreach ($seed in $seeds) {
    $result = $results[$seed]
    $matchStatus = if ($result.Match) { "✅ YES" } else { "❌ NO" }
    $color = if ($result.Match) { "Green" } else { "Red" }
    
    Write-Host ("{0,-4} | {1,-46} | {2,-46} | {3}" -f $seed, $result.FirstRun, $result.SecondRun, $matchStatus) -ForegroundColor $color
}

Write-Host ""

# Check uniqueness across different seeds
$uniqueHashes = $results.Values | Where-Object { $_.FirstRun -ne "FAILED" } | Select-Object -ExpandProperty FirstRun -Unique

Write-Host "Unique Certificates Generated: $($uniqueHashes.Count) out of $($seeds.Count) seeds" -ForegroundColor Cyan

if ($uniqueHashes.Count -eq $seeds.Count) {
    Write-Host "✅ All seeds produced UNIQUE certificates" -ForegroundColor Green
} else {
    Write-Host "⚠️  Some seeds produced DUPLICATE certificates" -ForegroundColor Yellow
    Write-Host "   This may indicate insufficient entropy in seed differentiation" -ForegroundColor Yellow
}

Write-Host ""

# Check reproducibility
$allReproducible = ($results.Values | Where-Object { $_.Match }).Count -eq $seeds.Count

if ($allReproducible) {
    Write-Host "🎉 SUCCESS! All seeds are deterministically reproducible!" -ForegroundColor Green
    Write-Host ""
    Write-Host "✅ DETERMINISTIC REPRODUCIBILITY VERIFIED ACROSS MULTIPLE SEEDS" -ForegroundColor Green
} else {
    Write-Host "❌ FAILURE! Some seeds failed to reproduce deterministically" -ForegroundColor Red
    Write-Host ""
    $failedSeeds = $results.GetEnumerator() | Where-Object { -not $_.Value.Match } | ForEach-Object { $_.Key }
    Write-Host "Failed seeds: $($failedSeeds -join ', ')" -ForegroundColor Red
}

Write-Host ""

# Save results
$resultsFile = "phase14/certification/multi_seed_results.json"
$resultsJson = $results | ConvertTo-Json -Depth 3
New-Item -ItemType Directory -Force -Path (Split-Path $resultsFile) | Out-Null
Set-Content -Path $resultsFile -Value $resultsJson
Write-Host "💾 Results saved to: $resultsFile" -ForegroundColor Cyan
Write-Host ""
