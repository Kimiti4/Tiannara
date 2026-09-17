# AE-005 Phase C: Epistemic Verification Protocol

## Objective
Prove that `CollapsePredictor.assess_risk/1` is a deterministic, evidence-based function rather than a stochastic number generator.

## Test 1: Determinism (The Variance Check)
**Action:** Pass the exact same telemetry map `T_1` to the predictor 100 times.
**Baseline Behavior:** Returns varying floats (e.g., 0.249, 0.812, 0.110).
**Candidate Requirement:** Must return the exact same float (or exact same tuple) 100 times. 
*Failure Condition:* Any variance fails the test.

## Test 2: Sensitivity (The Causal Link Check)
**Action:** 
1. Pass healthy telemetry `T_healthy`. Record score `S_1` and provenance `P_1`.
2. Pass degraded telemetry `T_degraded` (e.g., inject `memory_pressure: 0.95`, `dets_health: false`). Record score `S_2` and provenance `P_2`.
**Candidate Requirement:** 
- `S_2` must be materially higher than `S_1`.
- `P_2` must explicitly cite `memory_pressure` or `dets_health` as the contributing factors to the delta.
*Failure Condition:* If `S_2 == S_1`, or if the predictor cannot explain *why* the risk increased, the test fails.

## Test 3: Grounding (The Provenance Check)
**Action:** Pass standard telemetry `T_std`.
**Candidate Requirement:** The output must be a structured map, not a bare float:
```elixir
%{
  risk_score: 0.15,
  evidence_count: 14,
  contributing_factors: [
    {:event_store_latency_ms, 45, weight: 0.2},
    {:executive_memory_health, :healthy, weight: 0.8}
  ]
}
```
*Failure Condition:* Returning a bare float without an evidence trail fails the test.

## Test 4: Bounded Uncertainty (The Negative Case)
**Action:** Pass incomplete, stale, or `nil` telemetry (e.g., `%{event_store: nil, memory: :stale}`).
**Baseline Behavior:** Returns a random float (e.g., 0.249) by falling back to a default seed.
**Candidate Requirement:** MUST return `{:unknown, :insufficient_evidence, missing_fields: [...]}`.
*Failure Condition:* Returning *any* numerical probability when evidence is missing is a critical constitutional violation ("Uncertainty should never be hidden").
