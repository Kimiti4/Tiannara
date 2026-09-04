#!/usr/bin/env bash
# Phase 4 Backend Integration - Quick Start Script
# 
# This script starts all required backend services for Phase 4 visualization
# Run from project root directory

set -e  # Exit on error

echo "=========================================="
echo "  Phase 4 Backend Integration Startup"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if a port is in use
check_port() {
    local port=$1
    if lsof -i :$port > /dev/null 2>&1; then
        return 0  # Port is in use
    else
        return 1  # Port is free
    fi
}

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check if Python is available
if ! command -v python &> /dev/null; then
    echo -e "${RED}❌ Python not found. Please install Python 3.8+${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Python found: $(python --version)${NC}"

# Check if Node.js is available
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js not found. Please install Node.js 18+${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Node.js found: $(node --version)${NC}"

# Check if Elixir/Mix is available
if ! command -v mix &> /dev/null; then
    echo -e "${YELLOW}⚠️  Elixir/Mix not found. Tiannara Runtime won't start.${NC}"
    echo -e "   Install from: https://elixir-lang.org/install.html"
else
    echo -e "${GREEN}✅ Elixir/Mix found: $(mix --version | head -n 1)${NC}"
fi

echo ""
echo -e "${YELLOW}Checking port availability...${NC}"

# Check ports
PORTS_IN_USE=0

if check_port 4000; then
    echo -e "${YELLOW}⚠️  Port 4000 already in use (Tiannara Runtime)${NC}"
    PORTS_IN_USE=$((PORTS_IN_USE + 1))
else
    echo -e "${GREEN}✅ Port 4000 available${NC}"
fi

if check_port 8000; then
    echo -e "${YELLOW}⚠️  Port 8000 already in use (Tiannara API)${NC}"
    PORTS_IN_USE=$((PORTS_IN_USE + 1))
else
    echo -e "${GREEN}✅ Port 8000 available${NC}"
fi

if check_port 3000; then
    echo -e "${YELLOW}⚠️  Port 3000 already in use (Dashboard)${NC}"
    PORTS_IN_USE=$((PORTS_IN_USE + 1))
else
    echo -e "${GREEN}✅ Port 3000 available${NC}"
fi

if [ $PORTS_IN_USE -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}Some ports are already in use. You may need to stop existing services.${NC}"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Aborted.${NC}"
        exit 1
    fi
fi

echo ""
echo "=========================================="
echo "  Starting Backend Services"
echo "=========================================="
echo ""

# Start Tiannara Runtime (Elixir/Phoenix)
if command -v mix &> /dev/null; then
    echo -e "${GREEN}🚀 Starting Tiannara Runtime (Port 4000)...${NC}"
    cd tiannara_runtime
    
    # Check if deps are installed
    if [ ! -d "_build" ]; then
        echo -e "${YELLOW}Installing Elixir dependencies...${NC}"
        mix deps.get
    fi
    
    # Start Phoenix server in background
    mix phx.server > /tmp/tiannara_runtime.log 2>&1 &
    RUNTIME_PID=$!
    echo -e "${GREEN}   Tiannara Runtime started (PID: $RUNTIME_PID)${NC}"
    echo -e "   Logs: /tmp/tiannara_runtime.log"
    
    cd ..
    
    # Wait for service to be ready
    echo -e "${YELLOW}   Waiting for Tiannara Runtime to be ready...${NC}"
    for i in {1..30}; do
        if curl -s http://localhost:4000/api/health > /dev/null 2>&1; then
            echo -e "${GREEN}   ✅ Tiannara Runtime is ready!${NC}"
            break
        fi
        if [ $i -eq 30 ]; then
            echo -e "${RED}   ❌ Tiannara Runtime failed to start. Check logs: /tmp/tiannara_runtime.log${NC}"
        fi
        sleep 1
    done
else
    echo -e "${YELLOW}⚠️  Skipping Tiannara Runtime (Elixir not installed)${NC}"
fi

echo ""

# Start Tiannara API (FastAPI)
echo -e "${GREEN}🚀 Starting Tiannara API (Port 8000)...${NC}"
cd tiannara_api

# Check if virtual environment exists
if [ ! -d "venv" ] && [ ! -d ".venv" ]; then
    echo -e "${YELLOW}Creating Python virtual environment...${NC}"
    python -m venv venv
fi

# Activate virtual environment
if [ -d "venv" ]; then
    source venv/bin/activate 2>/dev/null || source venv/Scripts/activate 2>/dev/null
elif [ -d ".venv" ]; then
    source .venv/bin/activate 2>/dev/null || source .venv/Scripts/activate 2>/dev/null
fi

# Install dependencies if needed
if ! python -c "import fastapi" 2>/dev/null; then
    echo -e "${YELLOW}Installing Python dependencies...${NC}"
    pip install -r requirements.txt 2>/dev/null || pip install fastapi uvicorn httpx python-dotenv
fi

# Start FastAPI server in background
uvicorn main:app --reload --port 8000 > /tmp/tiannara_api.log 2>&1 &
API_PID=$!
echo -e "${GREEN}   Tiannara API started (PID: $API_PID)${NC}"
echo -e "   Logs: /tmp/tiannara_api.log"

cd ..

# Wait for service to be ready
echo -e "${YELLOW}   Waiting for Tiannara API to be ready...${NC}"
for i in {1..30}; do
    if curl -s http://localhost:8000/health > /dev/null 2>&1; then
        echo -e "${GREEN}   ✅ Tiannara API is ready!${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}   ❌ Tiannara API failed to start. Check logs: /tmp/tiannara_api.log${NC}"
    fi
    sleep 1
done

echo ""

# Start Internal Dashboard (Next.js)
echo -e "${GREEN}🚀 Starting Internal Dashboard (Port 3000)...${NC}"
cd tiannara_internal_dashboard

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}Installing npm dependencies...${NC}"
    npm install
fi

# Start Next.js dev server in background
npm run dev > /tmp/tiannara_dashboard.log 2>&1 &
DASHBOARD_PID=$!
echo -e "${GREEN}   Dashboard started (PID: $DASHBOARD_PID)${NC}"
echo -e "   Logs: /tmp/tiannara_dashboard.log"

cd ..

# Wait for service to be ready
echo -e "${YELLOW}   Waiting for Dashboard to be ready...${NC}"
for i in {1..30}; do
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        echo -e "${GREEN}   ✅ Dashboard is ready!${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}   ❌ Dashboard failed to start. Check logs: /tmp/tiannara_dashboard.log${NC}"
    fi
    sleep 1
done

echo ""
echo "=========================================="
echo -e "${GREEN}  ✅ All Services Started!${NC}"
echo "=========================================="
echo ""
echo "Service URLs:"
echo "  📊 Dashboard:      http://localhost:3000"
echo "  🔌 API:            http://localhost:8000"
echo "  ⚡ WebSocket:      ws://localhost:4000/socket/websocket"
echo ""
echo "Phase 4 Demo Pages:"
echo "  🧪 Observatory:    http://localhost:3000/demo/observatory"
echo "  🎮 Meta-Control:   http://localhost:3000/demo/meta-control"
echo "  🌌 Universe:       http://localhost:3000/demo/universe"
echo ""
echo "Health Checks:"
echo "  curl http://localhost:8000/api/v1/observatory/health"
echo "  curl http://localhost:8000/health"
echo ""
echo "Process IDs:"
if [ ! -z "$RUNTIME_PID" ]; then
    echo "  Tiannara Runtime: $RUNTIME_PID"
fi
echo "  Tiannara API:     $API_PID"
echo "  Dashboard:        $DASHBOARD_PID"
echo ""
echo "To stop all services:"
echo "  kill $API_PID $DASHBOARD_PID ${RUNTIME_PID:-}"
echo ""
echo "View logs:"
echo "  tail -f /tmp/tiannara_runtime.log"
echo "  tail -f /tmp/tiannara_api.log"
echo "  tail -f /tmp/tiannara_dashboard.log"
echo ""
echo -e "${GREEN}Ready to test Phase 4 visualization components!${NC}"
