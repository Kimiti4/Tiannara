# MC-004-A0 — Verification & Provenance

**Gate:** MC-004-A0 (Reconciliation) — **Date:** 2026-08-31 — **Mode:** READ-ONLY

## 1. Verification inventory (who/what verifies physics results)

| Path | Reality | File:line | Classification |
|---|---|---|---|
| Domain `validate/1` | `FormalVerification.verify_invariants/2` → `{:error, :formal_verification_unavailable}` | physics.ex:28-29; formal_verification.ex:4-5 | **UNAVAILABLE** |
| Subsystem validators | OPC validator operates on canned 0.98 scores; IRD/TWP thresholds on `:rand.uniform` inputs; `_issues`/`_risks` are computed then discarded | opc.ex:576-577,652; ird.ex:103,483,595; twp.ex:411,452 | **THEATRICAL/SELF-REFERENTIAL** (verifier input is fabricated) |
| Formal invariant checking | Decommissioned at MC-001-M; module is a truthful stub | formal_verification.ex:4-5 | **UNAVAILABLE** |
| SMT / theorem proving | Never existed in `lib/` | (search) | **NO** |

There is **no independent verification layer** for any physics computation. The `verify_invariants` contract (physics.ex:28) references conservation-of-energy and thermodynamics invariants — with no solver and no verifier, both are unreachable.

## 2. Provenance inventory (who records provenance for physics)

| Path | Reality | File:line | Classification |
|---|---|---|---|
| Physics results → provenance | No physics module references `Tiannara.Evidence.Provenance` | (verifier scan: zero refs across `lib/tiannara/physics/**` and `lib/tiannara/domains/**`) | **DISCONNECTED / NO** |
| `Evidence.Provenance` substrate | Real, substantial, exercised by evidence/phase4 code | evidence/provenance.ex | **REAL but unrelated to physics** |
| Reproducibility anchor | No run id, no seed, no config hash attached to any physics output | — | **NO** |
| Subsystem state traces | ETS records exist (`nde.ex:82-102`) but originate from theatrical values and carry no provenance | nde.ex:82-102,336-345 | **STATE-TRACE REAL, VALUES UNTRUSTED** |

## 3. Reproducibility assessment

- A physics result cannot be reproduced **at all** today because the domain returns `{:error, :ode_solver_unavailable}` / `{:error, :formal_verification_unavailable}` — there is no result to reproduce. (Truthful unavailability is the correct current behavior and is reproducible: same error every call.)
- The theatrical subsystem's `:rand.uniform` outputs are nondeterministic (opc.ex:472-475; ird.ex:483; ird.ex:595); were they surfaced, they would be **irreproducible**.

## 4. Verification-provenance gap statement

The **Verification × Provenance chain is absent** for physics:
- no arithmetic verification of a computed result,
- no analytic-reference check,
- no provenance record of parameters/config/seed/kind,
- no independent re-derivation evidence.

This satisfies the reconciliation requirement to distinguish *claimed* from *actual* verification: for physics, verification is **claimed by contract** (`physics.ex:28`) and **absent in reality**.

## 5. MC-004-M prerequisites (recommendations only)

For the pilot (see PILOT-DEFINITION), before any execution, MC-004-M must add — as REAL, tested capabilities:
1. Energy/boundedness verification of simulation output (E(t) ≤ E(0) + tolerance) — a structural check, not SMT.
2. Analytic-reference comparison for the pilot model (underdamped closed-form solution).
3. Provenance attachment for every pilot result (kind `:computed` / `:real_execution`, config, seed, step size, derivation identity).
4. Deterministic reproducibility (fixed seed/step/params, recorded and re-run in tests).

The formal-verification substrate (**NO**) must remain NO unless separately authorized; the pilot must NOT depend on it.