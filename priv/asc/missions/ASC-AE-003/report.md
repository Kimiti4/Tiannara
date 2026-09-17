# ASC-AE-003 — Tradeoff-Aware Engineering Mission (contract K-AE003)

**Verdict: accept_eligible** | Front: [:bulk_gc_ingest]
**Contract fidelity (sealed oracle): pass=true**
(oracle_verdict=:accept_eligible, oracle_front=[:bulk_gc_ingest])

## Pre-declared contract (K-AE003)
```
%{
  latency_adoption_floor: 0.25,
  latency_no_effect_ceiling: 0.25,
  peak_ceiling: 0.25,
  retained_ceiling: 0.05,
  retained_reject_floor: 0.15,
  review_band_latency_min: 0.6,
  review_band_retained_max: 0.15
}
```

## Candidate statuses
```
[bulk_gc_ingest: :eligible]
```

## Statistics (paired, per-round medians + bootstrap 95% CIs)
```
[
  %{
    hypothesis: "The AE-002 memory delta is a transient peak in the library process heap; one forced GC at the end of init reclaims it without losing the latency win.",
    candidate: :bulk_gc_ingest,
    rounds_negative: 0,
    ci_95: {0.81457, 0.9011},
    ci_width: 0.08653,
    median_improvement: 0.84996,
    peak_ci: {-7.1e-4, -6.2e-4},
    peak_delta: -6.5e-4,
    retained_ci: {2.3e-4, 2.8e-4},
    retained_delta: 2.6e-4
  }
]
```

## Hard correctness (real-archive boot: count == baseline, integrity)
```
%{
  bulk_gc_ingest: %{
    count: 6000,
    status: :pass,
    integrity: true,
    reference_count: 6000
  },
  bulk_ingest: %{
    count: 6000,
    status: :pass,
    integrity: true,
    reference_count: 6000
  },
  chunked_bulk_ingest: %{
    count: 6000,
    status: :pass,
    integrity: true,
    reference_count: 6000
  },
  baseline: %{
    count: 6000,
    status: :pass,
    integrity: true,
    reference_count: 6000
  }
}
```

## Falsification records
```
[
  %{
    status: :eliminated_correctness,
    hypothesis: "AE-002 lineage, unchanged: per-row ETS overhead removed by bulk insertion.",
    candidate: :bulk_ingest,
    evidence: %{},
    updated_conclusion: "Failed a correctness gate (unit suite or real-archive boot); excluded before measurement."
  },
  %{
    status: :eliminated_correctness,
    hypothesis: "Chunking the bulk load bounds the transient peak (chunk-local maps) while retaining most of the latency win: a middle path in the tradeoff space.",
    candidate: :chunked_bulk_ingest,
    evidence: %{},
    updated_conclusion: "Failed a correctness gate (unit suite or real-archive boot); excluded before measurement."
  }
]
```

Adoption gate: HUMAN AUTHORIZATION REQUIRED (REVIEW never adopts)
