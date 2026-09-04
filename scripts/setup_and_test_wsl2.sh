#!/bin/bash
# Complete WSL2 Setup and Phase 5 Test - One Command
# Usage: Copy this file to WSL2, make executable, and run

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Tiannara ASC - Phase 5 WSL2 Quick Start    ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
echo ""

# Step 0: Verify we're not in /mnt/c/
if [[ "$PWD" == /mnt/c/* ]]; then
    echo -e "${RED}❌ ERROR: Running from Windows filesystem (/mnt/c/)${NC}"
    echo -e "${YELLOW}   This will be extremely slow!${NC}"
    echo ""
    echo "Please copy the project to Linux filesystem first:"
    echo "  mkdir -p ~/projects"
    echo "  cp -r /mnt/c/Users/user/Tiannara/Tiannara-MindCache-Prosthetic ~/projects/tiannara"
    echo "  cd ~/projects/tiannara"
    echo "  chmod +x scripts/setup_and_test_wsl2.sh"
    echo "  ./scripts/setup_and_test_wsl2.sh"
    exit 1
fi

# Step 1: Check if project exists
if [ ! -f "mix.exs" ]; then
    echo -e "${RED}❌ ERROR: mix.exs not found in current directory${NC}"
    echo -e "${YELLOW}   Are you in the right directory?${NC}"
    echo ""
    echo "Expected location: ~/projects/tiannara"
    echo "Current location: $(pwd)"
    exit 1
fi

echo -e "${GREEN}✓ Project found at: $(pwd)${NC}"
echo ""

# Step 2: Check Elixir
echo -e "${YELLOW}📦 Checking Elixir installation...${NC}"
if ! command -v elixir &> /dev/null; then
    echo -e "${RED}Elixir not found. Installing...${NC}"
    sudo apt update -qq
    sudo apt install -y -qq elixir erlang-dev erlang-parsetools > /dev/null 2>&1
    echo -e "${GREEN}✓ Elixir installed${NC}"
else
    ELIXIR_VERSION=$(elixir --version | head -1)
    echo -e "${GREEN}✓ $ELIXIR_VERSION${NC}"
fi
echo ""

# Step 3: Install Hex and Rebar
echo -e "${YELLOW}🔧 Setting up Mix tools...${NC}"
mix local.hex --force > /dev/null 2>&1
mix local.rebar --force > /dev/null 2>&1
echo -e "${GREEN}✓ Hex and Rebar ready${NC}"
echo ""

# Step 4: Clean build
echo -e "${YELLOW}🧹 Cleaning old builds...${NC}"
rm -rf _build deps
echo -e "${GREEN}✓ Cleaned${NC}"
echo ""

# Step 5: Get dependencies
echo -e "${YELLOW}📥 Installing dependencies (this may take a minute)...${NC}"
mix deps.get --only prod > /dev/null 2>&1
echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# Step 6: Compile
echo -e "${YELLOW}⚙️  Compiling project (3-5 minutes)...${NC}"
echo -e "${YELLOW}   This is where WSL2 shines - much faster than Windows!${NC}"
mix compile 2>&1 | grep -E "(Compiling|Generated|error:|warning:)" || true
echo -e "${GREEN}✓ Compilation complete!${NC}"
echo ""

# Step 7: Run Phase 5 Campaign
echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Starting Evolution Alpha 2 Campaign         ║${NC}"
echo -e "${BLUE}║  Phase 5 Core: Adaptation & Knowledge Reuse  ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Running campaign... This will take 5-10 minutes${NC}"
echo -e "${YELLOW}Watch for these key metrics:${NC}"
echo -e "  ${GREEN}✓${NC} Knowledge Reuse Rate > 10%"
echo -e "  ${GREEN}✓${NC} Transfer Success Rate > 5%"
echo -e "  ${GREEN}✓${NC} Adaptation Velocity > 0"
echo ""
echo "─────────────────────────────────────────────"
echo ""

# Run campaign and capture output
mix run scripts/evolution_alpha_2.exs 2>&1 | tee phase5_wsl2_results.txt

EXIT_CODE=${PIPESTATUS[0]}

echo ""
echo "─────────────────────────────────────────────"
echo ""

# Step 8: Analyze results
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ Campaign completed successfully!${NC}"
    echo ""
    
    # Extract Phase 5 metrics
    if grep -q "PHASE 5 CORE METRICS SUMMARY" phase5_wsl2_results.txt; then
        echo -e "${BLUE}📊 Phase 5 Metrics Summary:${NC}"
        echo ""
        grep -A 40 "PHASE 5 CORE METRICS SUMMARY" phase5_wsl2_results.txt | tail -n +2 | head -35
        echo ""
        
        # Check exit criteria
        echo -e "${BLUE}🎯 Exit Criteria Check:${NC}"
        
        # Knowledge Reuse Rate
        REUSE_RATE=$(grep "Reuse Rate:" phase5_wsl2_results.txt | grep -oP '\d+\.\d+' | head -1)
        if [ -n "$REUSE_RATE" ]; then
            if (( $(echo "$REUSE_RATE > 10" | bc -l) )); then
                echo -e "  ${GREEN}✓${NC} Knowledge Reuse Rate: ${REUSE_RATE}% (>10%)"
            else
                echo -e "  ${RED}✗${NC} Knowledge Reuse Rate: ${REUSE_RATE}% (need >10%)"
            fi
        fi
        
        # Transfer Success Rate
        TRANSFER_RATE=$(grep "Transfer Success Rate:" phase5_wsl2_results.txt | grep -oP '\d+\.\d+' | head -1)
        if [ -n "$TRANSFER_RATE" ]; then
            if (( $(echo "$TRANSFER_RATE > 5" | bc -l) )); then
                echo -e "  ${GREEN}✓${NC} Transfer Success Rate: ${TRANSFER_RATE}% (>5%)"
            else
                echo -e "  ${RED}✗${NC} Transfer Success Rate: ${TRANSFER_RATE}% (need >5%)"
            fi
        fi
        
        # Adaptation Velocity
        VELOCITY=$(grep "Velocity:" phase5_wsl2_results.txt | grep -oP '[+-]?\d+\.\d+' | head -1)
        if [ -n "$VELOCITY" ]; then
            if (( $(echo "$VELOCITY > 0" | bc -l) )); then
                echo -e "  ${GREEN}✓${NC} Adaptation Velocity: ${VELOCITY}% per generation (>0)"
            else
                echo -e "  ${RED}✗${NC} Adaptation Velocity: ${VELOCITY}% per generation (need >0)"
            fi
        fi
        
        echo ""
    fi
    
    echo -e "${GREEN}Results saved to: phase5_wsl2_results.txt${NC}"
    echo ""
    echo "To view full results:"
    echo "  cat phase5_wsl2_results.txt"
    echo ""
    echo "To view just the summary:"
    echo "  grep -A 40 'PHASE 5 CORE METRICS' phase5_wsl2_results.txt"
    
else
    echo -e "${RED}❌ Campaign failed with exit code: $EXIT_CODE${NC}"
    echo ""
    echo "Check the output above for error messages."
    echo "Results saved to: phase5_wsl2_results.txt"
fi

echo ""
echo -e "${BLUE}══════════════════════════════════════════════${NC}"
