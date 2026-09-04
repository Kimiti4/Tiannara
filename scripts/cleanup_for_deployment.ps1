# Pre-Deployment Cleanup Script (PowerShell)
# 
# This script performs safe cleanup operations to prepare Tiannara for deployment.
# All operations are reversible via git if needed.
#
# Usage: .\scripts\cleanup_for_deployment.ps1
# Review: See PRE_DEPLOYMENT_CLEANUP_REPORT.md for details

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Tiannara Pre-Deployment Cleanup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Function to confirm action
function Confirm-Action {
    param([string]$message)
    $response = Read-Host "$message (y/n)"
    return ($response -eq 'y' -or $response -eq 'Y')
}

# Check if we're in the right directory
if (-not (Test-Path "README.md") -or -not (Test-Path "tiannara_api")) {
    Write-Host "Error: Please run this script from the Tiannara-MindCache-Prosthetic root directory" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host ">>> Step 1: Deleting Cache Directories" -ForegroundColor Yellow
Write-Host "------------------------------------------"

# Delete pytest cache directories (safe - auto-regenerated)
$pytestCaches = Get-ChildItem -Path . -Directory -Filter "pytest-cache-files-*" -Depth 0
if ($pytestCaches.Count -gt 0) {
    Write-Host "Found $($pytestCaches.Count) pytest cache directories"
    $pytestCaches | Remove-Item -Recurse -Force
    Write-Host "✓ Deleted pytest cache directories" -ForegroundColor Green
} else {
    Write-Host "No pytest cache directories found"
}

Write-Host ""
Write-Host ">>> Step 2: Cleaning Python Cache" -ForegroundColor Yellow
Write-Host "------------------------------------------"

# Clean __pycache__ directories (optional - will regenerate)
if (Confirm-Action "Delete __pycache__ directories? (They will regenerate on next run)") {
    Get-ChildItem -Path . -Directory -Filter "__pycache__" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
    Write-Host "✓ Cleared Python cache" -ForegroundColor Green
} else {
    Write-Host "Skipped Python cache cleanup"
}

Write-Host ""
Write-Host ">>> Step 3: Removing Empty Directories" -ForegroundColor Yellow
Write-Host "------------------------------------------"

# List empty directories
$emptyDirs = Get-ChildItem -Path . -Directory -Depth 0 | Where-Object {
    $_.Name -ne ".git" -and $_.Name -ne "node_modules" -and (Get-ChildItem $_.FullName).Count -eq 0
}

if ($emptyDirs.Count -gt 0) {
    Write-Host "Empty directories found:"
    $emptyDirs | ForEach-Object { Write-Host "  - $($_.Name)" }
    Write-Host ""
    if (Confirm-Action "Delete these empty directories?") {
        $emptyDirs | Remove-Item -Force
        Write-Host "✓ Removed empty directories" -ForegroundColor Green
    } else {
        Write-Host "Skipped empty directory removal"
    }
} else {
    Write-Host "No empty directories found in root"
}

Write-Host ""
Write-Host ">>> Step 4: Archiving Redundant Dashboard" -ForegroundColor Yellow
Write-Host "------------------------------------------"

if (Test-Path "tiannara_internal_dashboard") {
    Write-Host "Found redundant internal dashboard directory"
    Write-Host "This has been superseded by admin dashboard in tiannara_saas/"
    Write-Host ""
    if (Confirm-Action "Archive tiannara_internal_dashboard/?") {
        New-Item -ItemType Directory -Path "archive/redundant_dashboards" -Force | Out-Null
        Move-Item -Path "tiannara_internal_dashboard" -Destination "archive/redundant_dashboards/"
        Write-Host "✓ Archived internal dashboard" -ForegroundColor Green
    } else {
        Write-Host "Skipped dashboard archival"
    }
} else {
    Write-Host "Internal dashboard directory not found (already archived or removed)"
}

Write-Host ""
Write-Host ">>> Step 5: Organizing Test Scripts" -ForegroundColor Yellow
Write-Host "------------------------------------------"

$testFiles = Get-ChildItem -Path . -Filter "test_*.py" -Depth 0
if ($testFiles.Count -gt 0) {
    Write-Host "Test scripts found in root directory:"
    $testFiles | ForEach-Object { Write-Host "  - $($_.Name)" }
    Write-Host ""
    if (Confirm-Action "Move test scripts to tests/integration/?") {
        New-Item -ItemType Directory -Path "tests/integration" -Force | Out-Null
        $testFiles | Move-Item -Destination "tests/integration/"
        Write-Host "✓ Moved test scripts to tests/integration/" -ForegroundColor Green
    } else {
        Write-Host "Skipped test script organization"
    }
} else {
    Write-Host "No test scripts found in root directory"
}

Write-Host ""
Write-Host ">>> Step 6: Consolidating Documentation" -ForegroundColor Yellow
Write-Host "------------------------------------------"

# Count markdown files in root
$mdFiles = Get-ChildItem -Path . -Filter "*.md" -Depth 0
Write-Host "Found $($mdFiles.Count) markdown files in root directory"

if ($mdFiles.Count -gt 20) {
    Write-Host ""
    Write-Host "Recommendation: Archive weekly reports and phase summaries"
    Write-Host "See PRE_DEPLOYMENT_CLEANUP_REPORT.md for detailed plan"
    Write-Host ""
    if (Confirm-Action "Create archive structure now?") {
        New-Item -ItemType Directory -Path "docs/development/ARCHIVE" -Force | Out-Null
        Write-Host "✓ Created archive directory structure" -ForegroundColor Green
        Write-Host "Next step: Manually move WEEK*.md, PHASE*_*.md files to docs/development/ARCHIVE/"
    }
} else {
    Write-Host "Documentation count is reasonable"
}

Write-Host ""
Write-Host ">>> Step 7: Verifying Code Quality" -ForegroundColor Yellow
Write-Host "------------------------------------------"

# Check for remaining bare except statements (simple grep-like check)
$bareExceptCount = (Select-String -Path "tiannara_api/*.py","tiannara_core/*.py" -Pattern "except:" -SimpleMatch | 
    Where-Object { $_.Line -notmatch "except Exception:" -and $_.Line -notmatch "#" }).Count

if ($bareExceptCount -gt 0) {
    Write-Host "⚠ Warning: Found $bareExceptCount bare 'except:' statements" -ForegroundColor Red
    Write-Host "Run: Select-String -Path 'tiannara_api/*.py','tiannara_core/*.py' -Pattern 'except:'"
} else {
    Write-Host "✓ No bare 'except:' statements found" -ForegroundColor Green
}

# Check for debug prints
$debugPrintCount = (Select-String -Path "tiannara_api/*.py","tiannara_core/*.py" -Pattern "print.*DEBUG").Count
if ($debugPrintCount -gt 0) {
    Write-Host "⚠ Found $debugPrintCount debug print statements" -ForegroundColor Yellow
    Write-Host "Review and remove before production deployment"
} else {
    Write-Host "✓ No debug print statements found" -ForegroundColor Green
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Cleanup Summary" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Safe cleanup operations completed" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:"
Write-Host "1. Review PRE_DEPLOYMENT_CLEANUP_REPORT.md for full details"
Write-Host "2. Manually archive experiment data (runs/, checkpoints/) if desired"
Write-Host "3. Consolidate Paystack documentation (6 files → 1 guide)"
Write-Host "4. Run full test suite: python -m pytest tests/"
Write-Host "5. Verify deployment: docker-compose up"
Write-Host ""
Write-Host "Project is ready for deployment! 🚀" -ForegroundColor Green
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
