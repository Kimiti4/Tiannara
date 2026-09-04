#!/usr/bin/env bash
set -euo pipefail

echo "=== Tiannara Phase 3.5: Staged Build ==="

# Stage 1: Dependencies only (cached after first run)
echo "[1/5] Compiling dependencies..."
mix deps.compile 2>&1 | tail -5

# Stage 2: Core modules (Council, Kernel, Executive Services)
echo "[2/5] Compiling core modules..."
mix compile --no-deps-check --paths lib/tiannara/council/ 2>&1 | tail -5
mix compile --no-deps-check --paths lib/tiannara/cel/ 2>&1 | tail -5

# Stage 3: World layer
echo "[3/5] Compiling world layer..."
mix compile --no-deps-check --paths lib/tiannara/world/ 2>&1 | tail -5

# Stage 4: Remaining modules (including web/, needs dep resolution for Phoenix)
echo "[4/5] Compiling remaining modules..."
mix compile 2>&1 | tail -5

# Stage 5: Verify startup
echo "[5/5] Verifying application startup..."
timeout 30 mix run -e "
  case Application.ensure_all_started(:tiannara) do
    {:ok, _} -> IO.puts(\"✅ Application started successfully\")
    {:error, reason} ->
      IO.puts(\"❌ Startup failed: #{inspect(reason)}\")
      System.halt(1)
  end
" 2>&1

echo "=== Build complete ==="
