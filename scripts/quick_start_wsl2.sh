#!/bin/bash
# One-command setup and test for Phase 5
# Copy this entire script into WSL2 and run it

set -e

echo "🚀 Tiannara Phase 5 WSL2 Quick Start"
echo "======================================"
echo ""

# Navigate to project (assumes already copied)
cd ~/projects/tiannara || {
    echo "❌ Project not found at ~/projects/tiannara"
    echo "   First run: cp -r /mnt/c/Users/user/Tiannara/Tiannara-MindCache-Prosthetic ~/projects/tiannara"
    exit 1
}

echo "✓ In project directory: $(pwd)"
echo ""

# Clean build
echo "🧹 Cleaning old builds..."
rm -rf _build deps
echo "✓ Cleaned"
echo ""

# Get dependencies
echo "📦 Installing dependencies..."
mix deps.get --only prod
echo "✓ Dependencies installed"
echo ""

# Compile
echo "⚙️  Compiling (this takes 3-5 minutes)..."
mix compile
echo "✓ Compilation complete!"
echo ""

# Run Phase 5 campaign
echo "🧬 Running Evolution Alpha 2 Campaign with Phase 5 metrics..."
echo "   This will take several minutes..."
echo ""
mix run scripts/evolution_alpha_2.exs 2>&1 | tee phase5_wsl2_results.txt

echo ""
echo "═══════════════════════════════════════"
echo "✅ Campaign Complete!"
echo "═══════════════════════════════════════"
echo ""
echo "Results saved to: phase5_wsl2_results.txt"
echo ""
echo "View summary:"
echo "  grep -A 30 'PHASE 5 CORE METRICS' phase5_wsl2_results.txt"
echo ""
