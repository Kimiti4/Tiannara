# EFDI Invariants

**Phase:** D1 — Signal Intelligence

These invariants are enforced by unit tests and are the certification surface
for D1.

## 1. Epistemic category separation

- A `Signal` has **no** `probability`, `decision`, or resolved outcome field.
- `observation ≠ signal ≠ evidence ≠ hypothesis ≠ forecast ≠ decision`.
- `Signal` never silently promotes itself to a forecast/decision.

## 2. `UNKNOWN` is valid and distinct from `0.0`

- Unmeasured fields evaluate to `:unknown`, not `0.0`.
- `0.0` means measured-and-low. `:unknown` means insufficient data.
- Quality/recency/value never fabricate a number where there is no input.
→ Proven by: adversarial test "an expired signal is flagged invalid (validity 0)",
  "a signal with all nil quality fields evaluates to mostly unknown".

## 3. Determinism & reproducibility

- `Signal.dedup_key/1` is a deterministic function of `source + observation`.
- `Provenance.content_hash/1` is deterministic.
- Re-registering an equivalent signal is idempotent.
→ Proven by: `replay_test.exs`, `provenance_test.exs`.

## 4. Historical immutability

- Correcting a signal creates a new version; the original is preserved verbatim.
- No path overwrites an existing record's observation.
→ Proven by: `replay_test.exs` "provenance lineage is preserved through versions".

## 5. Dedup single-counting

- Two signals with the same `dedup_key` are counted once.
- `register(s1).id == register(s2).id` when `dedup_key(s1) == dedup_key(s2)`.
- `stats().count == 1` after registering both.
→ Proven by: `signal_registry_test.exs` "does not double-count an identical
  observation", `replay_test.exs`.

## 6. No fabrication

- Predictive value / information gain against outcomes are `:unknown` in D1
  (no outcomes exist).
- Redundancy against an empty set is `:unknown`.
- Missing provenance does not falsely assert integrity.
→ Proven by: `adversarial_signal_test.exs`.

## 7. Graceful degradation

- The registry degrades to its in-memory ETS index if ExecutiveMemory/EventStore
  are unavailable; it reports degradation in `health/0` and never fails hard.
→ `health/0` exposes `ets_available`, `memory_degraded`,
  `eventstore_degraded`.

## 8. D1 scope boundary

- D1 implements Signal Intelligence only. Forecasting, calibration, decision,
  counterfactual, noise, and forecast memory are **not** implemented; only their
  contracts (`Contracts`) and integration boundaries (`Adapters`) are declared.
