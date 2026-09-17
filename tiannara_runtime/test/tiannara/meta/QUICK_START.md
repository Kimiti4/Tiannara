# Phase 5F.2 Tests - Quick Start Guide

## 🚀 Run All Tests (30 seconds)

```bash
cd tiannara_runtime
mix test test/tiannara/meta/
```

---

## 📋 Test Files Overview

| File | Purpose | Test Count |
|------|---------|------------|
| `observer_collapse_governor_test.exs` | OCG unit tests | 20+ |
| `observer_arbitration_layer_test.exs` | OCAL unit tests | 25+ |
| `observer_collapse_integration_test.exs` | End-to-end integration | 15+ |
| `test_helpers.ex` | Test utilities | N/A |

**Total**: 60+ test cases covering complete Phase 5F.2 functionality

---

## 🎯 Common Commands

### Run Specific Test File
```bash
# OCG tests only
mix test test/tiannara/meta/observer_collapse_governor_test.exs

# OCAL tests only
mix test test/tiannara/meta/observer_arbitration_layer_test.exs

# Integration tests only
mix test test/tiannara/meta/observer_collapse_integration_test.exs
```

### Run Single Test
```bash
mix test test/tiannara/meta/observer_collapse_governor_test.exs:25
# Replace :25 with line number of desired test
```

### Verbose Output
```bash
mix test --trace test/tiannara/meta/
```

### With Coverage
```bash
mix coveralls.html test/tiannara/meta/
open cover/excoveralls.html
```

### Watch Mode (TDD)
```bash
mix test.watch test/tiannara/meta/
```

---

## 🔍 What Gets Tested

### Observer Collapse Governor (OCG)
- ✅ OSS computation formula
- ✅ Stability tier classification
- ✅ Pairwise evaluation logic
- ✅ Arbitration rules (A, B, C, D)
- ✅ MSCL integration (live MSF scores)
- ✅ Full sweep across observers

### Observer Arbitration Layer (OCAL)
- ✅ MERGE outcome (chimera synthesis)
- ✅ SUPPRESS outcome (dormant reality)
- ✅ COLLAPSE outcome (hard termination)
- ✅ Resurrection workflows
- ✅ ETS table management
- ✅ Statistics tracking

### Integration Scenarios
- ✅ Complete arbitration lifecycle
- ✅ Multi-observer ecosystems (5-20 observers)
- ✅ Cascading collapses
- ✅ Performance under load
- ✅ Error handling & resilience
- ✅ NATS event publishing

---

## 🛠️ Using Test Helpers

```elixir
alias Tiannara.Meta.TestHelpers

# Create observer
obs = TestHelpers.create_observer("my_obs", :stable, :medium)

# Create merge-triggering pair
{a, b} = TestHelpers.create_arbitration_pair(:merge)

# Create population
pop = TestHelpers.create_observer_population(20, :mixed)

# Calculate expected OSS
expected = TestHelpers.expected_oss(obs)
```

---

## 🐛 Debugging Tips

### Enable Debug Logging
```elixir
# config/test.exs
config :logger, level: :debug
```

### Inspect ETS Tables
```elixir
:ets.tab2list(:suppressed_observers)
:ets.tab2list(:collapsed_causal_archive)
```

### Check GenServer State
```elixir
:sys.get_state(Tiannara.Meta.ObserverCollapseGovernor)
:sys.get_state(Tiannara.Meta.ObserverArbitrationLayer)
```

---

## 📊 Expected Results

All tests should pass with output similar to:

```
Finished in 2.5 seconds
60 tests, 0 failures

Randomized with seed 12345
```

---

## ⚠️ Common Issues

### Issue: Tests timeout
**Solution**: Increase timeout in test configuration
```elixir
# config/test.exs
config :ex_unit, timeout: 30_000  # 30 seconds
```

### Issue: ETS table already exists
**Solution**: Tables are recreated in setup block - this is normal

### Issue: NATS connection errors
**Solution**: Tests handle missing NATS gracefully - warnings are expected

---

## 📚 Documentation

- **Full README**: `README_PHASE_5F2_TESTS.md`
- **Test Summary**: `PHASE_5F2_TEST_SUMMARY.md`
- **Phase 5F.2 Spec**: `../../../markdown/5F.md`

---

## ✅ Verification

After running tests, verify:
- [ ] All 60+ tests pass
- [ ] No unexpected warnings
- [ ] Execution time < 10 seconds total
- [ ] Coverage > 85% (if running with coverage)

---

**Quick Reference**: Save this file for fast access to common commands!
