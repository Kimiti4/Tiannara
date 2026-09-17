# Phase 5F.2 Integration Tests - Observer Collapse Governor & Arbitration Layer

## Overview

This directory contains comprehensive integration tests for the **Phase 5F.2 Observer Collapse Governor (OCG)** and **Observer Collapse Arbitration Layer (OCAL)** systems.

These tests verify the complete reality arbitration pipeline that transitions Tiannara from "multi-world simulation" to a **selection mechanism over incompatible realities**.

---

## Test Files

### 1. `observer_collapse_governor_test.exs`
Tests the OCG GenServer responsible for:
- OSS (Observer Stability Score) computation
- Pairwise observer evaluation
- Arbitration rule enforcement (Rules A, B, C, D)
- Integration with MSCL for live MSF scores
- Full sweep across all registered observers

**Key test scenarios:**
- OSS calculation with various parameter combinations
- Classification into stability tiers (dominant/stable/merge/collapse candidates)
- Triggering merge/suppress/collapse decisions based on OSS deltas
- Handling edge cases (identical observers, extreme values, missing fields)

### 2. `observer_arbitration_layer_test.exs`
Tests the OCAL GenServer responsible for:
- MERGE outcome (chimera synthesis from two parents)
- SUPPRESS outcome (dormant reality with resurrection capability)
- COLLAPSE outcome (hard termination with archival)
- ETS table management for suppressed/collapsed observers
- Resurrection workflows

**Key test scenarios:**
- Chimera creation with weighted field blending
- Suppression metadata persistence
- Collapse trace archival for future recompilation
- Observer resurrection from both suppressed and collapsed states
- Statistics tracking (chimera count, suppression count, collapse count)

### 3. `observer_collapse_integration_test.exs`
End-to-end integration tests covering:
- Complete arbitration lifecycle (OCG → OCAL → MCK)
- Multi-observer ecosystem simulation
- MSCL integration for live MSF hydration
- NATS event publishing verification
- Performance and scalability under load
- Error handling and resilience

**Key test scenarios:**
- Full merge/suppress/collapse workflows
- Managing 20+ competing observers simultaneously
- Cascading collapses in unstable ecosystems
- Rapid successive evaluations (performance benchmark)
- ETS table consistency under concurrent operations

### 4. `test_helpers.ex`
Utility module providing:
- Realistic observer manifold generation
- Arbitration pair creation for specific outcomes
- Population simulation helpers
- OSS validation utilities
- CTN interference simulation

---

## Running the Tests

### Prerequisites

Ensure you have Elixir and Mix installed:
```bash
elixir --version
mix --version
```

### Run All Phase 5F.2 Tests

```bash
cd tiannara_runtime
mix test test/tiannara/meta/observer_collapse_governor_test.exs
mix test test/tiannara/meta/observer_arbitration_layer_test.exs
mix test test/tiannara/meta/observer_collapse_integration_test.exs
```

### Run Specific Test Suite

```bash
# OCG tests only
mix test test/tiannara/meta/observer_collapse_governor_test.exs

# OCAL tests only
mix test test/tiannara/meta/observer_arbitration_layer_test.exs

# Integration tests only
mix test test/tiannara/meta/observer_collapse_integration_test.exs
```

### Run Single Test Case

```bash
mix test test/tiannara/meta/observer_collapse_governor_test.exs:25
# Replace :25 with the line number of the test you want to run
```

### Run with Verbose Output

```bash
mix test --trace test/tiannara/meta/
```

### Run with Coverage Report

```bash
mix coveralls.html test/tiannara/meta/
# Opens coverage report in browser
```

---

## Test Architecture

### Component Dependencies

```
┌─────────────────────────────────────────┐
│   ObserverCollapseGovernor (OCG)        │
│   - OSS computation                     │
│   - Arbitration rules                   │
│   - Pairwise evaluation                 │
└──────────────┬──────────────────────────┘
               │ calls
               ▼
┌─────────────────────────────────────────┐
│   ObserverArbitrationLayer (OCAL)       │
│   - Merge/Suppress/Collapse actions     │
│   - ETS table management                │
│   - Resurrection workflows              │
└──────────────┬──────────────────────────┘
               │ interacts with
               ▼
┌─────────────────────────────────────────┐
│   Meta-Causal Kernel (MCK)              │
│   - Observer registration               │
│   - Manifold compilation                │
│   - Collapse/resurrect operations       │
└──────────────┬──────────────────────────┘
               │ queries
               ▼
┌─────────────────────────────────────────┐
│   MSCL (Meta-Stability Constraint Layer)│
│   - Live MSF score retrieval            │
│   - Stability operator application      │
└─────────────────────────────────────────┘
```

### Test Isolation Strategy

Each test file uses `async: false` to ensure:
- Clean ETS table state between tests
- No race conditions in GenServer interactions
- Deterministic NATS event ordering
- Isolated observer lifecycle management

The `setup` block in each test:
1. Starts required GenServers (OCG, OCAL, MSCL)
2. Initializes ETS tables (`:suppressed_observers`, `:collapsed_causal_archive`)
3. Provides clean state for each test case

---

## Key Concepts Tested

### 1. Observer Stability Score (OSS)

Formula: `OSS = (Coherence × MSF × Prediction) / (Interference + ε)`

**Tested ranges:**
- `0.0 - 0.3`: Collapse candidate
- `0.3 - 0.6`: Merge candidate
- `0.6 - 0.85`: Stable runtime world
- `0.85 - 1.0`: Dominant attractor reality

### 2. Arbitration Rules

**RULE A - No duplicate dominant realities:**
- When `|OSS_A - OSS_B| < 0.10` AND high interference → trigger merge

**RULE B - Stability beats fidelity:**
- Less "true" but more stable observer wins persistence

**RULE C - High interference forces resolution:**
- When CTN overlap density > 0.75 → force collapse decision

**RULE D - No infinite coexistence:**
- Only allowed when MSCL elasticity maintains separation cost

### 3. Three Outcomes

**MERGE (🧬 Hybrid Reality Spawn):**
- Creates chimera observer from blended parent fields
- Both parents collapsed after successful merge
- Weighted by OSS (higher-OSS parent dominates blend)

**SUPPRESS (🧊 Dormant Reality):**
- Lower-OSS observer paused but not deleted
- Stored in ETS with metadata for resurrection
- Auto-resurrection after 10 minutes if OSS > 0.40

**COLLAPSE (☠️ Hard Termination):**
- Observer removed from execution topology
- Archived in causal archive for future recompilation
- Trace preserved for debugging

### 4. Integration Points

**MSCL Integration:**
- OCG hydrates MSF scores from MSCL before computing OSS
- Falls back to local estimation if MSCL unavailable
- Validates MSF retrieval and fallback mechanisms

**MCK Integration:**
- OCAL calls MCK to register chimera observers
- MCK handles collapse/resurrect operations
- Verifies observer lifecycle transitions

**NATS Integration:**
- OCG publishes to `tiannara.meta.ocg.arbitration`
- OCAL publishes to `tiannara.meta.ocal.decisions`
- Tests verify event publishing without blocking

---

## Test Helpers Usage

### Creating Test Observers

```elixir
alias Tiannara.Meta.TestHelpers

# Create a stable observer with medium interference
observer = TestHelpers.create_observer("my_observer", :stable, :medium)

# Create a pair designed to trigger merge
{obs_a, obs_b} = TestHelpers.create_arbitration_pair(:merge)

# Create population of 20 mixed observers
population = TestHelpers.create_observer_population(20, :mixed)
```

### Validating OSS Computations

```elixir
# Calculate expected OSS for an observer
expected = TestHelpers.expected_oss(observer)

# Validate observer has required fields
:ok = TestHelpers.validate_observer(observer)
```

### Simulating CTN Interference

```elixir
# Calculate interference between two observers
interference = TestHelpers.simulate_ctn_interference(obs_a, obs_b)
```

---

## Performance Benchmarks

The integration tests include performance benchmarks:

### Rapid Successive Evaluations
- **Test**: 20 observers, 190 pairwise evaluations
- **Expected**: < 5 seconds completion time
- **Purpose**: Verify OCG handles high-frequency updates

### ETS Table Consistency Under Load
- **Test**: 10 simultaneous suppressions
- **Expected**: All entries persisted correctly
- **Purpose**: Verify ETS table integrity under concurrent writes

---

## Common Test Patterns

### Pattern 1: Evaluate and Verify Scores

```elixir
test "evaluates pair and updates scores" do
  observer_a = %{observer_id: "a", coherence: 0.75, msf: 0.70, ...}
  observer_b = %{observer_id: "b", coherence: 0.60, msf: 0.55, ...}
  
  OCG.evaluate_pair(observer_a, observer_b)
  Process.sleep(100)  # Allow GenServer to process
  
  {:ok, scores} = OCG.get_scores()
  assert Map.has_key?(scores, "a")
  assert Map.has_key?(scores, "b")
end
```

### Pattern 2: Trigger Specific Outcome

```elixir
test "triggers merge with similar OSS and high interference" do
  {obs_a, obs_b} = TestHelpers.create_arbitration_pair(:merge)
  
  {:ok, outcome} = OCAL.resolve(:merge, obs_a, obs_b, 0.70, 0.71)
  
  assert outcome.decision == :merge
  assert outcome.chimera_id =~ "CHIMERA-"
end
```

### Pattern 3: Full Lifecycle Test

```elixir
test "complete suppress → resurrect cycle" do
  # Suppress
  {:ok, _} = OCAL.resolve(:suppress, observer, %{}, 0.45, 0.80)
  
  # Verify suppressed
  {:ok, suppressed} = OCAL.list_suppressed()
  assert Enum.any?(suppressed, & &1.observer_id == "test_obs")
  
  # Resurrect
  {:ok, "test_obs"} = OCAL.attempt_resurrection("test_obs")
  
  # Verify no longer suppressed
  {:ok, after} = OCAL.list_suppressed()
  refute Enum.any?(after, & &1.observer_id == "test_obs")
end
```

---

## Debugging Failed Tests

### Enable Detailed Logging

Add to `config/test.exs`:
```elixir
config :logger, level: :debug
```

### Inspect ETS Tables During Test

```elixir
# In IEx or test
:ets.tab2list(:suppressed_observers)
:ets.tab2list(:collapsed_causal_archive)
```

### Check GenServer State

```elixir
# Get OCG internal state
:sys.get_state(Tiannara.Meta.ObserverCollapseGovernor)

# Get OCAL internal state
:sys.get_state(Tiannara.Meta.ObserverArbitrationLayer)
```

### Verify NATS Events

Check NATS JetStream for published events:
```bash
# Monitor OCG events
gnat sub tiannara.meta.ocg.arbitration

# Monitor OCAL events
gnat sub tiannara.meta.ocal.decisions
```

---

## Extending the Tests

### Adding New Test Scenarios

1. Use `TestHelpers` to create realistic observers
2. Follow existing patterns for evaluate → verify workflow
3. Add assertions for expected outcomes
4. Include edge cases (missing fields, extreme values)

### Example: Testing New Arbitration Rule

```elixir
test "new rule triggers custom outcome" do
  observer_a = TestHelpers.create_observer("rule_a", :stable, :high)
  observer_b = TestHelpers.create_observer("rule_b", :stable, :high)
  
  OCG.evaluate_pair(observer_a, observer_b)
  Process.sleep(100)
  
  # Verify new rule behavior
  {:ok, scores} = OCG.get_scores()
  assert ... # Your assertions here
end
```

---

## Continuous Integration

These tests are designed to run in CI/CD pipelines:

```yaml
# .github/workflows/test.yml
test_phase_5f2:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v2
    - name: Setup Elixir
      uses: erlef/setup-beam@v1
    - name: Install dependencies
      run: mix deps.get
    - name: Run Phase 5F.2 tests
      run: mix test test/tiannara/meta/
```

---

## Related Documentation

- [Phase 5F.2 Specification](../../../markdown/5F.md) - Lines 1-2448
- [Observer Collapse Governor Implementation](../../lib/tiannara/runtime/meta/observer_collapse_governor.ex)
- [Observer Arbitration Layer Implementation](../../lib/tiannara/runtime/meta/observer_arbitration_layer.ex)
- [MSCL Implementation](../../lib/tiannara/runtime/meta/mscl.ex)
- [MCK Implementation](../../lib/tiannara/runtime/meta/meta_causal_kernel.ex)

---

## Key Principles Verified

✅ **"Existence is a privilege, not a state"**
- Observers must earn persistence through stability

✅ **"Collapse is a resource"**
- Collapse = compute pressure release, not failure

✅ **"Reality is selected under constraints"**
- Selection based on stability, interference, compressibility

✅ **"No global truth, only observer-relative consistency"**
- Each observer validated on self-consistency, not global agreement

---

## Maintenance Notes

- Update tests when arbitration thresholds change
- Add new test scenarios for emerging edge cases
- Monitor performance benchmarks for regressions
- Keep TestHelpers synchronized with production code changes
- Review NATS event schemas when payloads evolve

---

**Last Updated**: 2026-05-20  
**Test Coverage Target**: 85%+ for OCG/OCAL modules  
**Status**: ✅ Production Ready
