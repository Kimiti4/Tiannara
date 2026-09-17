#!/bin/bash

# Phase 5F.2 Performance Benchmark Monitor
# Tracks test execution times and alerts on regressions

set -e

echo "=========================================="
echo "Phase 5F.2 Performance Benchmark Monitor"
echo "=========================================="
echo ""

# Configuration
BENCHMARK_FILE="test_performance_benchmarks.json"
WARNING_THRESHOLD=10  # seconds
CRITICAL_THRESHOLD=30  # seconds

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to run tests and measure time
run_benchmark() {
    local test_file=$1
    local test_name=$2
    
    echo "📊 Running benchmark: $test_name"
    
    START_TIME=$(date +%s%N)
    mix test "$test_file" --no-compile 2>&1 | tail -5
    END_TIME=$(date +%s%N)
    
    # Calculate duration in milliseconds
    DURATION_MS=$(( (END_TIME - START_TIME) / 1000000 ))
    DURATION_S=$(echo "scale=2; $DURATION_MS / 1000" | bc)
    
    echo "   Duration: ${DURATION_S}s"
    
    # Check thresholds
    if (( $(echo "$DURATION_S > $CRITICAL_THRESHOLD" | bc -l) )); then
        echo -e "   ${RED}❌ CRITICAL: Exceeds ${CRITICAL_THRESHOLD}s threshold${NC}"
        STATUS="critical"
    elif (( $(echo "$DURATION_S > $WARNING_THRESHOLD" | bc -l) )); then
        echo -e "   ${YELLOW}⚠️  WARNING: Exceeds ${WARNING_THRESHOLD}s threshold${NC}"
        STATUS="warning"
    else
        echo -e "   ${GREEN}✅ PASS: Within acceptable range${NC}"
        STATUS="pass"
    fi
    
    echo ""
    
    # Return duration and status
    echo "$DURATION_S|$STATUS"
}

# Main execution
cd "$(dirname "$0")/../.."

echo "Starting performance benchmarks..."
echo ""

# Run individual benchmarks
OCG_RESULT=$(run_benchmark "test/tiannara/meta/observer_collapse_governor_test.exs" "Observer Collapse Governor")
OCAL_RESULT=$(run_benchmark "test/tiannara/meta/observer_arbitration_layer_test.exs" "Observer Arbitration Layer")
INTEGRATION_RESULT=$(run_benchmark "test/tiannara/meta/observer_collapse_integration_test.exs" "Integration Tests")

# Parse results
OCG_TIME=$(echo $OCG_RESULT | cut -d'|' -f1)
OCG_STATUS=$(echo $OCG_RESULT | cut -d'|' -f2)

OCAL_TIME=$(echo $OCAL_RESULT | cut -d'|' -f1)
OCAL_STATUS=$(echo $OCAL_RESULT | cut -d'|' -f2)

INTEGRATION_TIME=$(echo $INTEGRATION_RESULT | cut -d'|' -f1)
INTEGRATION_STATUS=$(echo $INTEGRATION_RESULT | cut -d'|' -f2)

# Generate summary
echo "=========================================="
echo "Performance Benchmark Summary"
echo "=========================================="
echo ""
echo "Test Suite                  | Time    | Status"
echo "----------------------------|---------|--------"
printf "%-28s| %6ss | %s\n" "OCG Tests" "$OCG_TIME" "$OCG_STATUS"
printf "%-28s| %6ss | %s\n" "OCAL Tests" "$OCAL_TIME" "$OCAL_STATUS"
printf "%-28s| %6ss | %s\n" "Integration Tests" "$INTEGRATION_TIME" "$INTEGRATION_STATUS"
echo ""

# Save results to JSON for historical tracking
cat > "$BENCHMARK_FILE" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "benchmarks": {
    "ocg_tests": {
      "duration_seconds": $OCG_TIME,
      "status": "$OCG_STATUS",
      "threshold_warning": $WARNING_THRESHOLD,
      "threshold_critical": $CRITICAL_THRESHOLD
    },
    "ocal_tests": {
      "duration_seconds": $OCAL_TIME,
      "status": "$OCAL_STATUS",
      "threshold_warning": $WARNING_THRESHOLD,
      "threshold_critical": $CRITICAL_THRESHOLD
    },
    "integration_tests": {
      "duration_seconds": $INTEGRATION_TIME,
      "status": "$INTEGRATION_STATUS",
      "threshold_warning": $WARNING_THRESHOLD,
      "threshold_critical": $CRITICAL_THRESHOLD
    }
  }
}
EOF

echo "Results saved to: $BENCHMARK_FILE"
echo ""

# Check for regressions
if [ "$OCG_STATUS" = "critical" ] || [ "$OCAL_STATUS" = "critical" ] || [ "$INTEGRATION_STATUS" = "critical" ]; then
    echo -e "${RED}❌ CRITICAL PERFORMANCE REGRESSION DETECTED${NC}"
    exit 1
elif [ "$OCG_STATUS" = "warning" ] || [ "$OCAL_STATUS" = "warning" ] || [ "$INTEGRATION_STATUS" = "warning" ]; then
    echo -e "${YELLOW}⚠️  WARNING: Performance degradation detected${NC}"
    exit 0
else
    echo -e "${GREEN}✅ All benchmarks within acceptable ranges${NC}"
    exit 0
fi
