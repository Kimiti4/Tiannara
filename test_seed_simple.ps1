# Simple Multi-Seed Test
$seeds = @(42, 123, 999, 7777)

Write-Host ""
Write-Host "🌱 MULTI-SEED TEST" -ForegroundColor Cyan
Write-Host ""

foreach ($seed in $seeds) {
    Write-Host "Testing seed $seed..." -ForegroundColor Yellow
    
    # Set environment variable and run
    $env:SEED = "$seed"
    $output = & mix run run_pure_artifact_generator.exs 2>&1
    Remove-Item Env:SEED
    
    # Extract hash
    $hashLine = $output | Select-String "Certificate SHA-256:" | Select-Object -Last 1
    if ($hashLine) {
        $hash = ($hashLine.Line -split ": ")[1].Trim()
        Write-Host "  ✅ Seed $seed → $hash" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Failed" -ForegroundColor Red
        Write-Host "  Output: $($output[-5..-1] -join "`n")" -ForegroundColor Gray
    }
}

Write-Host ""
