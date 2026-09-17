# MC-004-M Certification — Domain-Physics Pilot Mutation (BOUNDED)

**Gate:** MC-004-M
**Campaign:** Tiannara Remediation + Substrate Integration
**Verdict:** CERTIFIED_BOUNDED
**Authorization:** GRANTED — operator `c14_ac` (ASC-MC-004-M-DOMAIN-PHYSICS-MUTATION.human.yaml)
**Date:** 2026-08-31

## Certification basis

This gate certifies the MU-1..MU-4 domain-physics pilot mutation to the bounded
boundary defined in the mutation contract: source-level truthfulness and real
(computed-by-RK4) simulation capability are certified; **no pilot was executed**.

1. **Design choice (MC-004 constraints):** replace the placeholder physics (a
   stub integrator, `validate/1` that could never affirm even a real result,
   theatrical subsystem client APIs that fabricated plausible numbers, and a
   placeholder ASC candidate) with a genuine, bounded, pure-Elixir RK4
   integrator + honest wiring. Computed trajectories carry `:simulation`
   provenance + evidence hashes; everything not computed reports explicit
   unavailability.

2. **Independent static verification (verifier, own scan):** PASS.
   `priv/tiannara/remediation/verifiers/MC004_M_domain_physics_mutation.py`
   scans the live repository (not the certification record): integrator bounds,
   error paths and MC-001 pin, Physics simulate/validate/provenance wiring,
   pilot spec, quarantine surfaces (OPC/NDE/IRD/TWP), zero `:rand.uniform`
   under `lib/tiannara/physics`, ASC-004 placeholder replacement, the Phase-4
   bridge, and result-JSON truthfulness flags.

3. **Compile:** `mix compile` succeeds (pre-existing warnings unchanged).

4. **Regression evidence:** `test/tiannara/math` + `test/tiannara/domains` +
   `test/tiannara/physics` = **73 tests, 0 failures** (full output captured in
   `priv/tiannara/remediation/results/MC004_M_suite_output.txt`). Includes the
   MC-001 truthfulness pins, the canonical registry physics binding, and all
   three new MC-004-M test files. Corpus-wide pre-existing failures (rec. MC-003-M
   matrix) untouched by this gate; full one-shot `mix test` is not runnable on
   this machine (>30 min — environmental).

5. **Analytic correctness:** RK4 harmonic-oscillator output matches the analytic
   solution within tolerance; the damped-oscillator pilot decays to t=10 within
   the envelope e^(-c·t/2m) (last amplitude ≈ 0.053 < 0.1) — the integrator
   computes, it does not improvise.

6. **Truthfulness invariants upheld:** no fabricated trajectory; `:simulation`
   provenance only (never `:real_execution`); formal verification remains
   unavailable (MC-001 pin); `:real_execution_enabled` stays false;
   `pilot_executed = false`; zero `:rand.uniform` in the physics tree.

## BOUNDED verdict — what is and is not certified

| Claim | Status |
| --- | --- |
| MU-1 `Calculus.solve_ode` performs real bounded RK4 for `:first_order_system` specs | CERTIFIED (code + analytic tests) |
| MU-2 `Physics.simulate` returns real trajectories with `:simulation` provenance + evidence hash | CERTIFIED (tests) |
| MU-2 `Physics.validate` does structural checks on real results / returns `:formal_verification_unavailable` | CERTIFIED |
| MU-3 OPC/NDE/IRD/TWP client surfaces are honest (`:physics_substrate_unavailable`), deterministic, rand-free, boot-neutral | CERTIFIED (tests + grep) |
| MU-4 Phase-4 bridge + ASC candidate use the real pilot / gated gateway | CERTIFIED (code wiring + flag-off test) |
| Integrator is *formally* verified (error-bound certificate beyond analytic pins) | **NOT CERTIFIED** — TD-MC004-M-FORMAL_VERIFICATION |
| The pilot was actually executed as a live experiment | **NOT CERTIFIED — PENDING** (requires fresh MC-004-P human authorization + flag flip; `:real_execution_enabled` false) |
| OPC/NDE/IRD/TWP engine submodules (16) were decommissioned, not just quarantined | NOT CERTIFIED — deferred debt (TD-MC004-M-SUBSYSTEM_ENGINES) |

## Final architectural question

> Did this mutation increase the ability to distinguish *computed facts* from
> *claimed facts*?

**Yes.** Before this gate the physics domain could only claim: `simulate/2`
produced no real numbers, `validate/1` could not bless even a real result, and
the OPC/NDE/IRD/TWP APIs emitted plausible-but-uncomputed numbers. After this
gate every audited physics surface is either genuinely computed (RK4 trajectory,
sha256-backed provenance, structural checks), explicitly unavailable
(`:physics_substrate_unavailable` / `:formal_verification_unavailable`), or
deterministically honest. No surface on the physics tree can fabricate a
plausible number; every number carries or withholds its evidence.

## Certificate close-out
- Certification boundary honored: **NO pilot executed** — `:real_execution_enabled` false; MC-004-P requires fresh human authorization.
- Result JSON finalized: `priv/tiannara/remediation/results/MC004_M_result.json` — verdict `CERTIFIED_BOUNDED`, `mutation_executed: true`, `pilot_executed: false`, `real_execution_enabled_flag: false`.
- Independent verifier: PASS.
- Forward path to MC-004-P: obtain new human grant (operator `c14_ac`); keep `mutation_executed = true`; flip `:real_execution_enabled` only under that grant; execute `pilot_experiment/0` routed through the Phase-4 gateway; record real-execution ledger + provenance; run MC-004-P gate.