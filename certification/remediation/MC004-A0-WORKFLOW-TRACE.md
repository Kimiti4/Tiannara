# MC-004-A0 — Workflow Trace

**Gate:** MC-004-A0 (Reconciliation) — **Date:** 2026-08-31 — **Mode:** READ-ONLY

The intended scientific workflow a physics investigation must traverse:

```
Question → Hypothesis → Math/Model → Simulation → Execution → Observation
        → Verification → Evidence(Provenance) → Integration → Learning
```

## Trace table

| Step | Required | Reality | File:line | Status |
|---|---|---|---|---|
| 1. Question | posed by an investigator | No physics question is ever posed by any live path | ADE dead (`autonomous_discovery.ex:15`) | **MISSING** |
| 2. Hypothesis | generated | `generate_hypotheses/1` returns `{:ok, []}`; ADE hardcodes a gravity/time_dilation placeholder instead of generating | physics.ex:21-22; autonomous_discovery.ex:68 | **STUB/PLACEHOLDER** |
| 3. Mathematics / model | equations → solver | No real ODE solver exists; `simulate` forwards to `{:error, :ode_solver_unavailable}` | calculus.ex:5; physics.ex:17-18 | **MISSING (UNAVAILABLE)** |
| 4. Simulation | numeric integration | No integrator (no RK4/ODE step anywhere in `lib/`); `Tiannara.Numerics` provides only error-mode/interpolation helpers | numerics.ex:33-60 | **MISSING** |
| 5. Execution | side-effect / real runtime | Physics disconnected from `RealExecution`/`Phase4`; zero references | (verifier scan) | **MISSING (DISCONNECTED)** |
| 6. Observation | measurement captured | Physics subsystem "observers" output `:rand.uniform()` coin flips (opc.ex:472-475); no measurement with provenance | opc.ex:472-475 | **THEATRICAL** |
| 7. Verification | independent check | `validate` → `{:error, :formal_verification_unavailable}`; subsystem validators discard `_issues`/`_risks` | formal_verification.ex:5; physics.ex:28-29 | **MISSING / SELF-REFERENTIAL** |
| 8. Evidence / provenance | result carries provenance | No physics module references `Evidence.Provenance` | (verifier scan) | **MISSING** |
| 9. Integration | knowledge fused | `KnowledgeRepresentation.assert_fact` only reachable behind dead ADE + failing simulate/validate | autonomous_discovery.ex:39 | **DEAD** |
| 10. Learning | metrics inform adaptation | `metrics/0` truthful-zero; no live consumer | physics.ex:37-49 | **TRUTHFUL-ZERO, UNUSED** |

## Envelope findings

- The **primary chain is MISSING and its only engine (`run_discovery_cycle`) is dead code** with zero callers in `lib/`.
- The `canonical:physics` module itself is honest at every step (empty or unavailable) — the LACK of a workflow is a capability gap, not a lie.
- The `Tiannara.Physics.*` subsystem provides a *parallel theatrical workflow* (OPC/NDE/IRD/TWP state machines) with fabricated observation/verification steps; it is **not** connected to the domain module or ADE.
- A single truthful step exists end-to-end: the Bayes `evaluate` on evidence (physics.ex:12-14 over REAL probability), but that is conditional inference on supplied evidence, not a complete physics investigation.

## Verdict

**WORKFLOW: MISSING (capability gap) at steps 1,3,4,5,6,7,8; STUB at step 2; THEATRICAL at steps 6-7 within the disconnected subsystem; REAL/TRUTHFUL-ZERO only at step 10 with no consumer.**

No physics investigation can currently proceed past hypothesis into a truthful simulation/verification — consistent with the constitutional answer **NO**.