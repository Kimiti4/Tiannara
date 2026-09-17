# MC-001: Mathematical Discovery Readiness Assessment

**Date:** 2026-08-27

## Critical Discovery Question

> Can Tiannara currently discover genuinely novel mathematical structures,
> formulas, conjectures, or laws through a reproducible computational process,
> rather than merely generating plausible mathematical text?

**Answer: NO — infrastructure absent.**

No reproducible mechanism was located in the inspected source for generating,
testing, or integrating novel mathematical claims. The REAL primitives compute
known operations; none of them generate or verify novel mathematical objects.

## Discovery Pipeline Assessment (evidenced)

| Transition | Status | Evidence |
|-----------|--------|----------|
| Observation → Mathematical Problem | UNKNOWN | no structured problem-formation found |
| Problem → Hypothesis Generation | ABSENT | Physics.generate_hypotheses returns {:ok, []} |
| Hypothesis → Candidate Formula/Structure | ABSENT | none found |
| Candidate → Prediction | ABSENT | none found |
| Prediction → Computation | PARTIAL | REAL numerics exist |
| Computation → Counterexample Search | ABSENT | none found |
| Counterexample → Formal/Symbolic Verification | ABSENT | FormalVerification is mock |
| Verification → Independent Validation | ABSENT | none found |
| Validation → Knowledge Integration | PARTIAL | telemetry/ETS exists; dashboard forged |

## LLM Generation vs. Mathematical Discovery

The presence of LLM-based equation generation (if any) does NOT constitute
discovery. Discovery requires reproducible computation, independent
verification, counterexample resistance, provenance, and validated-knowledge
integration. None of these are demonstrated for novel mathematics.

## Physics Domain Discovery Claims Check (inspected)

`Tiannara.Domains.Physics`:
- `discover/1` → returns empty `discoveries: []` (physics.ex:9)
- `generate_hypotheses/1` → returns `{:ok, []}` (physics.ex:22)
- `design_experiments/1` → returns `{:ok, []}` (physics.ex:25)
- `metrics/0` → reports fabricated `discoveries_this_cycle: 4` (physics.ex:37)

**The metrics CLAIM discoveries (4) while the discovery functions return
empty. This is fabricated discovery reporting, not discovery.**

## Discovery Readiness Verdict

**NOT READY.** There is no autonomous-discovery infrastructure. The closest
REAL capability is a bounded set of numerical primitives — useful building
blocks, not a discovery engine. Any claim of "autonomous mathematics,"
"theorem discovery," or "new mathematical laws" in the codebase is not
supported by reproducible evidence at this layer.
