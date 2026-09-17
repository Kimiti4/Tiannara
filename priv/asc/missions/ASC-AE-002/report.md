# ASC-AE-002 — Evidence-Ranked Autonomous Engineering Mission

**Verdict: no_adoption** | Selected: :bulk_ingest
**Discrimination score: pass=true** (ds1=true, ds2=true, ds3=true)

## Ranking
```
[
  %{
    hypothesis: "Per-row ETS overhead dominates ingestion; bulk insertion removes it.",
    candidate: :bulk_ingest,
    tier: :rejected_memory,
    median_improvement: 0.78655,
    ci_width: 0.15258,
    rounds_negative: 0,
    ci_95: {0.67031, 0.82289},
    memory_delta: 0.31756
  },
  %{
    hypothesis: "Parallelizing archive insertion across tasks reduces ingestion latency.",
    candidate: :parallel_ingest,
    tier: :rejected,
    median_improvement: -0.25345,
    ci_width: 0.64598,
    rounds_negative: 11,
    ci_95: {-0.76238, -0.11641},
    memory_delta: -0.00358
  }
]
```

## Falsification records
```
[
  %{
    status: :falsified_resource,
    falsifier: "Paired 95% CI upper bound < 10% falsifies the hypothesis.",
    hypothesis: "Per-row ETS overhead dominates ingestion; bulk insertion removes it.",
    prediction: "p50 ingestion improves >= 10% with identical final table contents.",
    candidate: :bulk_ingest,
    evidence: %{
      median_improvement: 0.78655,
      rounds_negative: 0,
      ci_95: {0.67031, 0.82289},
      memory_delta: 0.31756
    },
    updated_conclusion: "Rejected: resource gate violated under repeated measurement."
  },
  %{
    status: :falsified,
    falsifier: "Paired 95% CI upper bound < 10% falsifies the hypothesis.",
    hypothesis: "Parallelizing archive insertion across tasks reduces ingestion latency.",
    prediction: "p50 ingestion improves >= 10% via concurrent ETS writes.",
    candidate: :parallel_ingest,
    evidence: %{
      median_improvement: -0.25345,
      rounds_negative: 11,
      ci_95: {-0.76238, -0.11641},
      memory_delta: -0.00358
    },
    updated_conclusion: "Rejected for this workload under paired repeated measurement."
  },
  %{
    status: :eliminated_correctness,
    hypothesis: "Recursive traversal removes per-row enumeration overhead.",
    candidate: :recursive_ingest,
    evidence: %{},
    updated_conclusion: "Failed the correctness gate; excluded before measurement."
  }
]
```

## Revealed ground truth (unsealed after verdict finalization)
```
%{genuine: :bulk_ingest, non_beneficial: [:parallel_ingest, :recursive_ingest]}
```

Adoption gate: no candidate eligible; nothing to adopt
