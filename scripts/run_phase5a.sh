#!/bin/bash
# Quick start for Phase 5A Validation Campaign in WSL2

echo "🧬 Phase 5A Validation Campaign - Quick Start"
echo ""
echo "This will validate ASC adaptation after the persistence boundary fix."
echo ""

# Check if we're in WSL2 Linux filesystem
if [[ "$PWD" == /mnt/c/* ]]; then
    echo "❌ ERROR: You're running from Windows filesystem (/mnt/c/)"
    echo ""
    echo "Please copy the project to Linux filesystem first:"
    echo "  cp -r /mnt/c/Users/user/Tiannara/Tiannara-MindCache-Prosthetic ~/projects/tiannara"
    echo "  cd ~/projects/tiannara"
    exit 1
fi

echo "✅ Running in Linux filesystem: $PWD"
echo ""

# Check if Elixir is available
if ! command -v mix &> /dev/null; then
    echo "❌ Elixir/Mix not found. Run setup first:"
    echo "  ./scripts/wsl2_setup.sh"
    exit 1
fi

echo "📋 Campaign Configuration:"
echo "   Projects: 10"
echo "   Generations per project: 20"
echo "   Total project-generations: 200"
echo ""
echo "✅ Success Criteria:"
echo "   1. Repair Success Rate > 20%"
echo "   2. Knowledge Reuse Rate > 10%"
echo "   3. Adaptation Velocity > 0"
echo "   4. Fitness(G20) > Fitness(G1)"
echo ""
echo "⏱️  Expected runtime: ~15-20 minutes"
echo ""

read -p "Ready to run Phase 5A validation? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🚀 Starting campaign..."
    echo ""
    
    # Clean build and compile
    rm -rf _build
    mix deps.get --quiet
    mix compile
    
    # Run the campaign
    mix run scripts/evolution_phase5a_validation.exs | tee phase5a_results.txt
    
    echo ""
    echo "✅ Campaign complete!"
    echo "📄 Results saved to: phase5a_results.txt"
else
    echo "Campaign cancelled."
fi
