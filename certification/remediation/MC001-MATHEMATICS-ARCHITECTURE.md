# MC-001: Mathematical Substrate Architecture Map

**Date:** 2026-08-27
**Method:** Derived from inspected source under `lib/tiannara/`.

## Current Layering (what exists)

```text
Presentation / Dashboard (THEATRICAL metrics)
        │
Knowledge Integration (telemetry into ETS; dashboard forged)
        │
Numerical Primitives  (Tiannara.Numerics — REAL, substantial)
Probability/Entropy    (Math.Probability, Foundations.InformationTheory)
Statistics             (Math.Statistics — DUPLICATE of Numerics subset)
Graphs                 (Math.Graphs — BFS)
Sparse Math            (Tiannara.Math — cosine)
        │
Optimization (MOCK)    Calculus/ODE (MOCK)    Formal Verification (MOCK)
        │
Canonical Domain Consumers: Tiannara.Domains.Physics
```

## Module Dependency Web (inspected relationships)

| Producer | Consumer |
|----------|----------|
| Math.Probability.bayes_update | Domains.Physics.evaluate (physics.ex:13) |
| Calculus.solve_ode (MOCK) | Domains.Physics.simulate (physics.ex:18) |
| FormalVerification.verify_invariants (MOCK) | Domains.Physics.validate (physics.ex:29) |
| Math.Optimization (MOCK) | none found |
| Math.Statistics | none found (path appears superseded by Numerics) |
| Math.Graphs.shortest_path | not directly inventoried as consumer |
| Observable.Metrics.Mathematics | telemetry attach + ETS insert (real), dashboard (fabricated) |

## Critical Architectural Findings

1. **Substrate is fragmented, not layered.** There is no agreed canonical
   `Tiannara.Math.*` namespace. Equivalent operations live in at least two
   module families (`Tiannara.Math.Statistics` vs `Tiannara.Numerics`) with
   conflicting formulas and return contracts.

2. **A canonical domain (Physics) is coupled to the mock tier.** Physics
   simulation and validation ride on theatrical ODE and formal-verification
   mocks. This couples domain behavior to non-computed capability.

3. **No symbolic/formal tier exists.** Everything readable is numeric.
   There is no expression AST, symbolic simplifier, proof checker, or
   conjecture representation.

4. **The substrate is NOT reusable as designed.** Because the canonical path
   is ambiguous (Math.Statistics vs Numerics), a consumer cannot rely on a
   single correct implementation of variance/stdev/entropy.

## Substrate Contract Gap (MC-001-A3)

A minimal substrate contract must eventually define:

- expression representation (currently absent / ad-hoc)
- mathematical object representation (maps/lists, inconsistent)
- operation interface (inconsistent `{:ok, ...}` vs bare `float()`)
- derivation interface (absent)
- verification interface (currently a mock)
- conjecture interface (absent)
- counterexample interface (absent)
- proof interface (absent)
- provenance (absent)
- uncertainty (partially present in Numerics)
- determinism (deterministic for REAL primitives)
- failure semantics (varies: guards/tuples/raises)
- versioning (absent)

## Suggested Target Layering (future — NOT implemented here)

```text
Mathematical Representation
        ↓
Mathematical Operations
        ↓
Symbolic / Numerical Computation
        ↓
Derivation
        ↓
Verification
        ↓
Proof / Formal Reasoning
        ↓
Conjecture Generation
        ↓
Conjecture Testing
        ↓
Discovery
        ↓
Knowledge Integration
```

The gap between current state and this target is large: only the
"Mathematical Operations" and "Symbolic/Numerical Computation" tiers have
REAL content, and those are fragmented/duplicated.
