# Phase 5F.3 — OMRL Quick Start Guide

## 🚀 Get Started in 5 Minutes

### 1. Run Tests

```bash
cd tiannara_runtime
mix test test/tiannara/meta/observer_memory_reconciliation_test.exs
```

**Expected Output:**
```
....................................

Finished in 2.5 seconds
30 tests, 0 failures
```

---

### 2. Basic Usage Example

```elixir
alias Tiannara.Meta.ObserverMemoryReconciliation, as: OMRL

# Step 1: Ingest memories from multiple observers
mem_a = %{
  id: "event_x",
  event: "Event X occurred at t=100",
  weight: 0.9,
  msf: 0.85,
  oss: 0.80,
  coherence: 0.90
}

mem_b = %{
  id: "event_x",
  event: "Event X never happened",
  weight: 0.8,
  msf: 0.75,
  oss: 0.70,
  coherence: 0.85
}

OMRL.ingest_memory("observer_a", mem_a)
OMRL.ingest_memory("observer_b", mem_b)

# Step 2: Reconcile (automatically selects mode)
{:ok, result} = OMRL.reconcile("event_x")

IO.inspect(result.mode)           # :blended, :layered, or :split
IO.inspect(result.reconciled_value)  # Weighted memory value
IO.inspect(result.contributors)   # ["observer_a", "observer_b"]

# Step 3: Analyze contradiction
{:ok, analysis} = OMRL.analyze_contradiction(mem_a, mem_b)
IO.inspect(analysis.mode)              # Selected resolution mode
IO.inspect(analysis.contradiction_score)  # 0.0 - 1.0
IO.inspect(analysis.recommendation)     # Human-readable explanation
```

---

### 3. Monitor System Health

```elixir
{:ok, stats} = OMRL.stats()

IO.inspect(stats.total_unique_memories)       # Total memories tracked
IO.inspect(stats.multi_observer_memories)     # Memories with conflicts
IO.inspect(stats.mode_distribution)           # %{blended: n, layered: n, split: n}
IO.inspect(stats.total_reconciled)            # Total reconciliations performed
```

---

## 🎯 Common Scenarios

### Scenario 1: Two Observers Agree

```elixir
mem_a = %{id: "agree", event: "Same story", msf: 0.9, oss: 0.85}
mem_b = %{id: "agree", event: "Same story", msf: 0.85, oss: 0.80}

OMRL.ingest_memory("obs_a", mem_a)
OMRL.ingest_memory("obs_b", mem_b)

{:ok, result} = OMRL.reconcile("agree")
# result.mode == :blended (identical events, high stability)
```

---

### Scenario 2: High Interference Causes Split

```elixir
mem_a = %{id: "fork", event: "Timeline A", interference: 0.9}
mem_b = %{id: "fork", event: "Timeline B", interference: 0.85}

OMRL.ingest_memory("obs_a", mem_a)
OMRL.ingest_memory("obs_b", mem_b)

{:ok, result} = OMRL.reconcile("fork")
# result.mode == :split (high interference forces causal fork)
```

---

### Scenario 3: Batch Reconciliation

```elixir
# Ingest many memories
for i <- 1..100 do
  mem = %{id: "batch_#{i}", event: "Event #{i}", msf: 0.8, oss: 0.75}
  OMRL.ingest_memory("observer", mem)
end

# Reconcile all at once
OMRL.full_sweep()
# Background task processes all multi-observer memories
```

---

## 🔧 Configuration

### Default Thresholds

Located in `observer_memory_reconciliation.ex`:

```elixir
@low_contradiction_threshold 0.3      # Below this → blended
@high_interference_threshold 0.75     # Above this → split
@blended_msf_threshold 0.6            # MSF must be > this for blended
@blended_oss_threshold 0.6            # OSS must be > this for blended
@default_msf 0.5                      # Fallback MSF if not provided
@default_oss 0.5                      # Fallback OSS if not provided
@epsilon 0.001                        # Prevents division by zero
```

---

## 🐛 Debugging Tips

### Check Why a Specific Mode Was Selected

```elixir
{:ok, analysis} = OMRL.analyze_contradiction(mem_a, mem_b)

IO.puts("Mode: #{analysis.mode}")
IO.puts("Contradiction: #{analysis.contradiction_score}")
IO.puts("Recommendation: #{analysis.recommendation}")
```

### Inspect Stored OMSVs

```elixir
{:ok, memories} = OMRL.get_observer_memories("observer_id")

Enum.each(memories, fn omsv ->
  IO.inspect(omsv.event)
  IO.inspect(omsv.reconciliation_weight)  # R = MSF × OSS × coherence
end)
```

### Clear Cache and Force Re-reconciliation

```elixir
:ok = OMRL.invalidate_cache("memory_id")
{:ok, fresh_result} = OMRL.reconcile("memory_id")
```

---

## 📊 Performance Tuning

### For High Throughput

1. **Enable async ingestion** (already default):
   ```elixir
   OMRL.ingest_memory(observer_id, event)  # Returns immediately
   Process.sleep(50)  # Allow processing
   ```

2. **Use batch reconciliation**:
   ```elixir
   OMRL.full_sweep()  # More efficient than individual reconciles
   ```

3. **Monitor cache hit rate**:
   ```elixir
   {:ok, stats} = OMRL.stats()
   # High cache hits = good performance
   ```

### For Low Latency

1. **Pre-warm cache** after observer changes:
   ```elixir
   # After OCAL merge/suppress/collapse
   OMRL.reconcile(affected_memory_id)
   ```

2. **Reduce ETS contention** (already configured):
   ```elixir
   # ETS tables created with read_concurrency: true
   :ets.new(:omrl_memory_store, [:set, :named_table, :public, read_concurrency: true])
   ```

---

## 🚨 Common Errors

### Error: `{:error, :no_observers}`

**Cause:** Trying to reconcile a memory ID that doesn't exist.

**Fix:**
```elixir
# Check if memory exists first
{:ok, memories} = OMRL.get_observer_memories("observer_id")
if length(memories) > 0 do
  OMRL.reconcile(memory_id)
end
```

---

### Error: Reconciliation returns unexpected mode

**Cause:** Thresholds may need tuning for your use case.

**Debug:**
```elixir
{:ok, analysis} = OMRL.analyze_contradiction(mem_a, mem_b)
IO.inspect(analysis)

# Check individual metrics
IO.inspect(mem_a.interference)  # If > 0.75 → always split
IO.inspect(mem_a.msf)           # If < 0.6 → unlikely to blend
```

---

### Error: Slow reconciliation with many observers

**Cause:** Linear scaling O(n) where n = number of observers.

**Optimization:**
```elixir
# Use full sweep for batch processing
OMRL.full_sweep()

# Or limit concurrent reconciliations
Task.async_stream(many_memory_ids, fn mem_id ->
  OMRL.reconcile(mem_id)
end, max_concurrency: 10)
```

---

## 📚 Next Steps

1. **Read full documentation:** [README_PHASE_5F3_OMRL.md](./README_PHASE_5F3_OMRL.md)
2. **Review implementation summary:** [PHASE_5F3_IMPLEMENTATION_SUMMARY.md](./PHASE_5F3_IMPLEMENTATION_SUMMARY.md)
3. **Explore test cases:** [observer_memory_reconciliation_test.exs](./observer_memory_reconciliation_test.exs)
4. **Plan Phase 5F.4:** Causal Memory Compiler (CMC)

---

## 💡 Pro Tips

- **Auto-hydration works:** If you don't provide `msf` or `oss`, OMRL will fetch them from MSCL/OCG automatically.
- **Cache is your friend:** Repeated reconciliations are cached. Invalidate only when underlying stabilities change.
- **Modes are suggestions:** The system chooses the best mode based on thresholds, but you can override by adjusting interference/coherence values.
- **Monitor split rate:** High split rates indicate systemic instability or excessive CTN interference.

---

**Need Help?** Check the troubleshooting section in [README_PHASE_5F3_OMRL.md](./README_PHASE_5F3_OMRL.md).
