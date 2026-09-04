# Clean Repository Reproducibility Test - Phase 14 RC3 (PowerShell)
# This script clones the repository fresh and verifies certificate hashes match

param(
    [string]$RepoUrl = ".",
    [string]$CloneDir = "$env:TEMP\tiannara_clean_clone_$PID"
)

$ReferenceHashFile = "phase14/certification/hashes/reference_hashes.json"

Write-Host ""
Write-Host "🧪 Clean Repository Reproducibility Test" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Repository: $RepoUrl"
Write-Host "Clone directory: $CloneDir"
Write-Host ""

# Step 1: Clean up any previous clone
if (Test-Path $CloneDir) {
    Write-Host "🗑️  Removing previous clone..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $CloneDir
}

# Step 2: Clone repository
Write-Host "📦 Cloning repository..." -ForegroundColor Cyan
git clone $RepoUrl $CloneDir --depth 1
Set-Location $CloneDir

# Step 3: Install dependencies
Write-Host "📚 Installing dependencies..." -ForegroundColor Cyan
mix deps.get --only prod

# Step 4: Compile
Write-Host "🔨 Compiling..." -ForegroundColor Cyan
mix compile

# Step 5: Generate evidence package
Write-Host "🎯 Generating evidence package..." -ForegroundColor Cyan
mix run generate_phase14_evidence_package.exs

# Step 6: Extract hashes from generated package
Write-Host "🔍 Extracting certificate hashes..." -ForegroundColor Cyan
$GeneratedHashFile = Join-Path $CloneDir "phase14/certification/hashes/evidence_index.json"

if (-not (Test-Path $GeneratedHashFile)) {
    Write-Host "❌ ERROR: Generated hash file not found!" -ForegroundColor Red
    exit 1
}

# Step 7: Compare with reference hashes (if available)
if (Test-Path $ReferenceHashFile) {
    Write-Host "⚖️  Comparing with reference hashes..." -ForegroundColor Cyan
    
    try {
        $reference = Get-Content $ReferenceHashFile | ConvertFrom-Json
        $generated = Get-Content $GeneratedHashFile | ConvertFrom-Json
        
        # Compare file counts
        if ($reference.Count -ne $generated.Count) {
            Write-Host "❌ File count mismatch: $($reference.Count) vs $($generated.Count)" -ForegroundColor Red
            exit 1
        }
        
        # Build lookup maps
        $refMap = @{}
        foreach ($item in $reference) {
            $refMap[$item.file] = $item.sha256
        }
        
        $genMap = @{}
        foreach ($item in $generated) {
            $genMap[$item.file] = $item.sha256
        }
        
        # Compare each file's hash
        $mismatches = @()
        foreach ($key in $refMap.Keys) {
            if (-not $genMap.ContainsKey($key)) {
                $mismatches += "Missing file: $key"
            } elseif ($refMap[$key] -ne $genMap[$key]) {
                $mismatches += "Hash mismatch for $key:"
                $mismatches += "  Reference:  $($refMap[$key])"
                $mismatches += "  Generated:  $($genMap[$key])"
            }
        }
        
        if ($mismatches.Count -gt 0) {
            Write-Host "❌ Hash verification FAILED:" -ForegroundColor Red
            $mismatches | ForEach-Object { Write-Host $_ -ForegroundColor Red }
            exit 1
        } else {
            Write-Host "✅ All $($reference.Count) file hashes match perfectly!" -ForegroundColor Green
            Write-Host "✅ Clean repository reproducibility VERIFIED" -ForegroundColor Green
        }
        
    } catch {
        Write-Host "❌ Error during comparison: $_" -ForegroundColor Red
        exit 1
    }
    
} else {
    Write-Host "⚠️  No reference hash file found at $ReferenceHashFile" -ForegroundColor Yellow
    Write-Host "💡 Saving current hashes as reference for future comparisons..." -ForegroundColor Cyan
    Copy-Item $GeneratedHashFile $ReferenceHashFile
    Write-Host "✅ Reference hashes saved" -ForegroundColor Green
}

# Step 8: Cleanup
Write-Host ""
Write-Host "🧹 Cleaning up clone directory..." -ForegroundColor Yellow
Set-Location ..
Remove-Item -Recurse -Force $CloneDir

Write-Host ""
Write-Host "✅ Clean Repository Reproducibility Test COMPLETE" -ForegroundColor Green
Write-Host ""
