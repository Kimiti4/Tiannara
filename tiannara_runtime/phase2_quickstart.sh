#!/bin/bash
# Phase 2 Quick Start Script
# 
# This script sets up and runs the complete Phase 2 closed-loop system:
# 1. Starts NATS server (Docker)
# 2. Installs Elixir dependencies
# 3. Installs Python dependencies
# 4. Starts Elixir runtime
# 5. Starts Python cortex
#
# Usage: ./phase2_quickstart.sh

set -e  # Exit on error

echo "=========================================="
echo "🚀 Phase 2 Quick Start"
echo "=========================================="
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Step 1: Start NATS server
echo "📡 Step 1: Starting NATS server..."
docker run -d --name nats-server -p 4222:4222 nats:latest
echo "✅ NATS server started on port 4222"
echo ""

# Step 2: Install Elixir dependencies
echo "📦 Step 2: Installing Elixir dependencies..."
cd "$(dirname "$0")"
mix deps.get
echo "✅ Elixir dependencies installed"
echo ""

# Step 3: Install Python dependencies
echo "🐍 Step 3: Installing Python dependencies..."
cd python_cortex
pip install -r requirements.txt
echo "✅ Python dependencies installed"
echo ""

# Step 4: Run Python cortex tests
echo "🧪 Step 4: Running Python cortex standalone tests..."
python test_cortex_standalone.py
echo ""

# Step 5: Start services
echo "=========================================="
echo "🎯 Starting Phase 2 Services"
echo "=========================================="
echo ""
echo "Opening two terminals:"
echo "  Terminal 1: Elixir runtime"
echo "  Terminal 2: Python cortex"
echo ""
echo "Press Ctrl+C to stop NATS server when done."
echo ""

# Start Elixir in background
cd ..
echo "🧠 Starting Elixir runtime..."
mix run --no-halt &
ELIXIR_PID=$!

# Wait a moment for Elixir to start
sleep 3

# Start Python cortex
echo "⚙️  Starting Python cortex..."
cd python_cortex
python grcc_simulation_cortex.py &
PYTHON_PID=$!

# Wait for user to press Ctrl+C
trap "kill $ELIXIR_PID $PYTHON_PID; docker stop nats-server; docker rm nats-server; exit" INT TERM

echo ""
echo "✅ Phase 2 system running!"
echo "   - Elixir PID: $ELIXIR_PID"
echo "   - Python PID: $PYTHON_PID"
echo "   - NATS: docker container 'nats-server'"
echo ""
echo "To test the system, open IEx in another terminal:"
echo "   cd tiannara_runtime"
echo "   iex -S mix"
echo "   TiannaraRuntime.EventGateway.request_simulation_step(%{})"
echo ""

# Keep running until interrupted
wait
