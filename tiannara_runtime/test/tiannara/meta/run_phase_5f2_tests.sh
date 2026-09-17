#!/bin/bash

# Phase 5F.2 Integration Test Runner
# Quick script to run all Observer Collapse Governor & Arbitration Layer tests

set -e

echo "=========================================="
echo "Phase 5F.2 Integration Test Suite"
echo "Observer Collapse Governor (OCG)"
echo "Observer Arbitration Layer (OCAL)"
echo "=========================================="
echo ""

# Change to tiannara_runtime directory
cd "$(dirname "$0")/../.."

# Check if dependencies are installed
echo "📦 Checking dependencies..."
mix deps.get --quiet

# Run tests with different verbosity levels based on argument
case "${1:-normal}" in
  verbose)
    echo ""
    echo "🧪 Running tests with verbose output..."
    echo ""
    mix test --trace test/tiannara/meta/observer_collapse_governor_test.exs
    mix test --trace test/tiannara/meta/observer_arbitration_layer_test.exs
    mix test --trace test/tiannara/meta/observer_collapse_integration_test.exs
    ;;
  
  coverage)
    echo ""
    echo "📊 Running tests with coverage report..."
    echo ""
    mix coveralls.html test/tiannara/meta/
    echo ""
    echo "Coverage report generated at: cover/excoveralls.html"
    open cover/excoveralls.html 2>/dev/null || xdg-open cover/excoveralls.html 2>/dev/null || true
    ;;
  
  watch)
    echo ""
    echo "👀 Running tests in watch mode..."
    echo ""
    mix test.watch test/tiannara/meta/
    ;;
  
  *)
    echo ""
    echo "🧪 Running standard test suite..."
    echo ""
    
    echo "  [1/3] Testing Observer Collapse Governor..."
    mix test test/tiannara/meta/observer_collapse_governor_test.exs
    
    echo ""
    echo "  [2/3] Testing Observer Arbitration Layer..."
    mix test test/tiannara/meta/observer_arbitration_layer_test.exs
    
    echo ""
    echo "  [3/3] Testing Integration Scenarios..."
    mix test test/tiannara/meta/observer_collapse_integration_test.exs
    ;;
esac

echo ""
echo "=========================================="
echo "✅ All Phase 5F.2 tests completed!"
echo "=========================================="
echo ""
echo "Usage:"
echo "  ./run_phase_5f2_tests.sh [verbose|coverage|watch]"
echo ""
