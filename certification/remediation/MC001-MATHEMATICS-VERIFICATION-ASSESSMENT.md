# MC-001: Mathematical Verification Assessment

**Date:** 2026-08-27
**Method:** Inspected source + test survey. A verifier is classified by what it
actually does (PROVES / CHECKS / TESTS / HEURISTICS / PATTERN-MATCH / MOCK).

## Verification Mechanisms Found

| Mechanism | Module | What it does | Truth |
|-----------|--------|--------------|-------|
| Formal invariant verification | Foundations.FormalVerification:4 | returns verified:true + mock:true unconditionally | MOCK — no verification performed |
| Numeric guards | Various REAL modules | guard clauses (e.g., evidence_prob > 0, /0) | CHECK — real, bounded |
| Uncertainty surface | Numerics.error_mode / with_uncertainty | explicit error/CI metadata | CHECK — real, but metadata, not proof |
| Unit tests | (test tree) | see below | varies |

## What Tiannara Can Actually Verify (from inspected source)

| Claim type | Can verify? | Mechanism |
|-----------|-------------|-----------|
| Algebraic identities | NO | no eq/axiom handler found |
| Equivalence of expressions | NO | no AST equality / rewrite |
| Equations / inequalities | PARTIAL | numeric interpolation only; no symbolic solve |
| Numerical claims | YES (bounded) | real arithmetic in Numerics/Probability |
| Symbolic derivations | NO | no derivation engine |
| Proof obligations | NO | FormalVerification is a mock |
| Counterexamples | NO | none produced (mock returns []) |
| Boundary conditions | PARTIAL | guards in Numerics |
| Singularities / assumptions | PARTIAL | error_mode surfaces some; no general checker |

## Classification of Verification Methods

- **PROVES:** none found
- **CHECKS:** numeric guards, error_mode (bounded, real)
- **TESTS:** the unit-test suite (see below)
- **HEURISTICALLY SCORES:** none found as formal
- **PATTERN MATCHES:** none found
- **MOCK:** FormalVerification.verify_invariants (unconditional verified:true)

## Critical Finding: False-Confidence Path

`Tiannara.Domains.Physics.validate/2` (physics.ex:29) calls
`FormalVerification.verify_invariants(experiment.model, [:conservation_of_energy, :thermodynamics])`
which unconditionally returns `{:ok, %{verified: true, counterexamples: []}}`.

This means:
- Physics `validate` always reports "verified" regardless of the model.
- Any analytics/reporting that consumes Physics validate results inherits
  false verification confidence.
- This is a **theatrical verification** defect that must be surfaced, not
  treated as verified.

## Test Survey Summary

The exact test-regression status was not re-executed in this environment
(full `mix test` times out). The following is qualitative:
- Real primitives (Numerics, Probability, Graphs) are the most likely to have
  meaningful unit tests.
- Mock modules (Optimization, Calculus, FormalVerification) — tests over them
  would assert mock output shape only, which would be false confidence if
  mistaken for mathematical verification.

## Verification Verdict (MC-001-A4)

**REAL bounded numeric checking exists; formal verification is entirely mock.**
No PROVES-level capability exists. The formal-verification mock is consumed
by a canonical domain and must be treated as a false-confidence hazard.
