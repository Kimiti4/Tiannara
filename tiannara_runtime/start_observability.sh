#!/bin/bash
# COGNITIVE OBSERVABILITY LAYER: Quick Start Script
# 
# This script starts all components needed for the real-time visualization system.

set -e

echo "🧠 Starting Tiannara Cognitive Observatory..."
echo ""

# Check if NATS is running
if ! command -v nats-server &> /dev/null; then
    echo "❌ NATS server not found. Please install NATS:"
    echo "   brew install nats-server  (macOS)"
    echo "   or download from https://nats.io/download"
    exit 1
fi

# Start NATS in background if not already running
if ! pgrep -x "nats-server" > /dev/null; then
    echo "📡 Starting NATS server..."
    nats-server -DV &
    NATS_PID=$!
    sleep 2
    echo "✅ NATS server started (PID: $NATS_PID)"
else
    echo "✅ NATS server already running"
fi

# Start Tiannara Runtime (Elixir/Phoenix)
echo ""
echo "⚙️  Starting Tiannara Runtime..."
cd tiannara_runtime

# Install dependencies if needed
if [ ! -d "deps" ]; then
    echo "   Installing Elixir dependencies..."
    mix deps.get
fi

# Compile
echo "   Compiling Elixir modules..."
mix compile --quiet

# Start Phoenix server
echo "   Starting Phoenix endpoint on port 4000..."
mix phx.server &
PHOENIX_PID=$!
sleep 3

echo "✅ Tiannara Runtime started (PID: $PHOENIX_PID)"

# Start React frontend
echo ""
echo "🎨 Starting React frontend..."
cd ../tiannara_gui

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "   Installing npm dependencies..."
    npm install
fi

# Start dev server
echo "   Starting Vite dev server on port 5173..."
npm run dev &
REACT_PID=$!
sleep 2

echo "✅ React frontend started (PID: $REACT_PID)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧠 Cognitive Observatory is now running!"
echo ""
echo "📊 Dashboard: http://localhost:5173"
echo "🔌 WebSocket: ws://localhost:4000/socket/websocket"
echo "❤️  Health:     http://localhost:4000/health"
echo ""
echo "To stop all services, run: kill $NATS_PID $PHOENIX_PID $REACT_PID"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Wait for user interrupt
trap "echo ''; echo '🛑 Stopping all services...'; kill $NATS_PID $PHOENIX_PID $REACT_PID 2>/dev/null; echo '✅ All services stopped'; exit" INT TERM

wait
