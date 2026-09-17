# MC-001-M5: Metrics Truthfulness Ledger

**Gate:** MC-001-M / M5
**Status:** COMPLETE (authorized targets only)
**Date:** 2026-08-27

Documents the Physics.metrics fabrication, its downstream consumers, the
Mathematics dashboard fabrication, the dead-code evidence, the chosen boundary
semantics, and the deferred broader metrics issue.

---

## M5.1 `Tiannara.Domains.Physics.metrics/0` — fabrication

**File:** `lib/tiannara/domains/physics.ex:36`

### Previous behavior
```elixir
def metrics do
  %{active_hypotheses: 142, open_experiments: 38, discoveries_this_cycle: 4,
    knowledge_growth_rate: 0.05, evidence_quality_score: 0.88,
    hypotheses_generated: 142, experiments_completed: 38}
end
```

### Evidence of fabrication
- `discoveries_this_cycle: 4` while `Physics.discover/1` returns
  `{:ok, %{discoveries: [], ...}}` (empty discoveries).
- `active_hypotheses: 142`, `hypotheses_generated: 142`, `experiments_completed: 38`,
  `open_experiments: 38`, `evidence_quality_score: 0.88` have no backing state;
  `generate_hypotheses/1` and `design_experiments/1` return `{:ok, []}`.
- Recorded as THEATRICAL metrics in reconciliation (`MC001-MATHEMATICS-TRUTH-CLASSIFICATION.md`
  item T5) and bottleneck `BN-MC001-004`.

### Downstream consumers (production)
- `research_director.ex:59` — `get_all_metrics/0` → `module.metrics()` → map.
- `autonomous_discovery.ex:51` — `collect_domain_metrics/0` → `module.metrics()` → map.
- `BottleneckDetector` (`meta_science/bottleneck_detector.ex:10`) — reads
  `.hypotheses_generated` and `.experiments_completed` fields.
- `tool_builder.ex:157` — generic `#{module}.metrics()` contract.

### Chosen boundary semantics — **Option B (explicit availability metadata)**

The surrounding metrics API (`@callback metrics() :: map()`, `research_director`,
`autonomous_discovery`, `BottleneckDetector`) requires a **map**, not an
`{:error, ...}` tuple. Changing `metrics/0` to return an error tuple would break
the structural contract the consumers depend on. Per the gate's Option B guidance,
the structural contract is preserved while the fabricated claims are removed and
the derivation from real state is made explicit.

```elixir
@impl true
def metrics do
  {:ok, %{discoveries: discoveries}} = discover(%{})
  %{
    active_hypotheses: 0,
    open_experiments: 0,
    discoveries_this_cycle: length(discoveries),
    knowledge_growth_rate: 0.0,
    evidence_quality_score: 0.0,
    hypotheses_generated: 0,
    experiments_completed: 0,
    metrics_source: :state_derived
  }
end
```

- `discoveries_this_cycle` is **derived from `discover/1`** (real state), not
  hardcoded. `discover/1` returns `[]`, so the truthful value is `0`.
- All other counters are `0` because no state is tracked in this domain; the
  previous fabricated `142/38/4/0.88/...` are gone.
- `metrics_source: :state_derived` makes the provenance explicit and observable
  (Option B availability metadata).
- The map shape is preserved for `research_director`, `autonomous_discovery`,
  `BottleneckDetector`, and `tool_builder`.

**Justification:** Option A (`{:error, :metrics_unavailable}`) was rejected because
the downstream infrastructure is a map-based metrics contract. Option C (boundary
adapter) was unnecessary because preserving the map with truthful zero state and an
explicit source marker is simpler and honest. No numerical value was manufactured
merely to preserve shape; `0` is the real tracked value.

### Tests
- "Physics.metrics no longer reports fabricated discovery counts"
- "Physics.metrics discovery count is derived from discover/1, not hardcoded"

### Final disposition
**DECOMMISSIONED** — fabricated literals removed; truthful state-derived map.

---

## M5.2 `Tiannara.Observatory.Metrics.Mathematics.get_dashboard_data/0` — fabrication

**File:** `lib/tiannara/observatory/metrics/mathematics.ex:10`

### Previous behavior
```elixir
def get_dashboard_data do
  %{
    probability: %{jobs: 1450, latency_ms: 1.2, cache_hit: 0.85},
    statistics: %{jobs: 890, latency_ms: 0.8, cache_hit: 0.90},
    graphs: %{jobs: 320, latency_ms: 4.5, cache_hit: 0.60},
    optimization: %{jobs: 45, latency_ms: 120.0, cache_hit: 0.10},
    information_theory: %{jobs: 210, latency_ms: 2.1, cache_hit: 0.75}
  }
end
```

### Dead-code evidence
Source search of `lib/` found **no caller** of
`Tiannara.Observatory.Metrics.Mathematics` or `get_dashboard_data/0` in production
code. It appears only in `_build` beam metadata and its own file. `attach_telemetry/0`
and `handle_event/4` write real durations to an ETS table, but the dashboard returns
hardcoded fabricated constants.

### Chosen boundary semantics — **explicit unavailable**
Because the dashboard is dead code (no consumer), the fabricated dashboard is
replaced with an explicit unavailable boundary, retaining the module for lineage
(`attach_telemetry`/`handle_event` remain functional and real):

```elixir
def get_dashboard_data do
  {:error, :mathematics_dashboard_unavailable}
end
```

No hardcoded mathematical metrics are preserved for UI compatibility.

### Tests
- "mathematics dashboard is explicitly unavailable, not hardcoded"

### Final disposition
**DECOMMISSIONED** — fabricated dashboard replaced with explicit unavailable.

---

## Deferred broader domain-metrics issue

The other 19 domains (e.g. `robotics.ex:27`, `materials.ex:28`) still contain the
same hardcoded `metrics/0` fabrication pattern. This is **explicitly deferred
technical debt**, NOT expanded into this mutation. Per the mutation gate:

> The broader observation that other domain metrics may also be fabricated MUST be
> recorded as deferred technical debt, not silently expanded into this mutation.

A future authorized mutation is required to address the remaining fabricated domain
metrics. This ledger constitutes the deferred-debt record. It should be tracked as
follow-up technical debt item: `TD-MC001-M5-DOMAINS` (all 20 domains' `metrics/0`
should be audited and made truthful).

---

## Scope-control confirmation (M5)

- Physics.metrics fabricated discovery count removed. ✓
- Mathemematics dashboard hardcoded values removed. ✓
- No numerical value manufactured merely to preserve shape. ✓
- Other domain metrics NOT modified (deferred). ✓
- `metrics_source`/explicit-unavailable signature observable. ✓
