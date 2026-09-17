# EFDI D3 — Invariants

## 1. Core invariants

- **I-D3-1 (Resulting-free quality):** decision quality is a pure function of the
  decision-time snapshot. The observed outcome is never an input. V9.
- **I-D3-2 (Outcome separation):** decision quality and outcome quality are independent
  axes; all four combinations are representable. V10.
- **I-D3-3 (Hindsight isolation):** no outcome recorded at/before decision time is
  admissible (`guard_outcome` → `:hindsight_contamination`); a decision rewritten after the
  fact fails `consistent?/2`. V11.
- **I-D3-4 (Immutability):** decisions and snapshots are immutable; versioning appends
  (`version/2` with lineage), never overwrites.
- **I-D3-5 (Unknown honesty):** `:unknown` probabilities yield `:unknown` EV/variance/risk;
  the engine never fabricates a number.
- **I-D3-6 (Recommendation ≠ authorization):** the engine recommends; only
  `Council.authorize/3` authorizes. The D3 layer never bypasses Council. V15-V17.
- **I-D3-7 (Pre-mortem posture):** irreversible or unknown-distribution alternatives must
  surface a risk posture (`{:require_info, _} | :block`) rather than silent `:proceed`. V13.
- **I-D3-8 (Information-as-research):** value-of-information output is a research priority,
  never a permission-to-act grant. V16.
- **I-D3-9 (Determinism / replay):** identical decision-time inputs reproduce identical
  EV, risk, recommendation, and quality. V18.
- **I-D3-10 (Adversarial robustness):** hindsight smuggling, malformed inputs, and
  duplicate ids are rejected; garbage never crashes the decision path. V19.

## 2. Cross-layer invariants (with D1/D2)

- **I-D1-2 downstream:** forecasts referenced by a decision keep their versioned identity
  (`forecast_refs`); decisions never mutate a `Forecast`.
- **I-D2-2 downstream:** decision outcomes are hindsight-guarded exactly like forecast
  outcomes; the same contamination rule applies one layer up.
- **I-D3-A (no parallel system):** D3 composes `Council`, `Executive.Command`, `AEO`, and
  D2 forecasts; there is no shadow authorization or shadow probability engine.

## 3. Enforcement

Invariants are enforced by unit tests (`decision_*`, `pre_mortem`, `value_of_information`),
adversarial tests (`d3_adversarial_test.exs`), replay tests (`d3_replay_test.exs`), and the
independent verifier V1–V19.