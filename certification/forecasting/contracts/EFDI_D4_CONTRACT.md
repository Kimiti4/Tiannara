# EFDI D4 — Contract (RATIFIED)

**Gate:** EFDI-D4 · **Status: D4_CERTIFIED_BOUNDED** — IMPLEMENTATION AUTHORIZED
(2026-09-02, per human authorization superseding the earlier PENDING_COUNCIL_AUTHORIZATION
status). This contract was derived from the live repository scan
(`EFDI_D4_ARCHITECTURE_RECONNAISSANCE.md`, `EFDI_D4_CLASSIFICATION_MATRIX.md`) and is
now ratified by the independent verifier (`EFDI_D4_independent_verification.py`, V20–V35)
with D1–D3 regression preserved (269 → 300 tests / 0 failures).

## Scope

D4 delivers a **counterfactual / attribution analysis layer** for the decision
chain: `CounterfactualRecord`, `AlternativeHistoryBundle`, `AttributionReport`,
`SelectionEffectReport`, `RegressionToMeanReport`, and the D4→D3 temporal firewall.
**All underlying causal/counterfactual machinery is REUSE/ADAPTER** (do-calculus,
branching, replay, simulation, event store, world snapshots, evidence, D2
probability/base-rates, D3 snapshots); the genuinely new surface is the decision-
context status ontology, luck/skill attribution, survivorship/selection, RTM, and
the external firewall verifier.

## Required invariants (proposed gates V20–V35)

| Gate | Invariant | Behaviour |
|------|-----------|-----------|
| V20 | Observed history immutability | mutation attempts rejected + adversarial audit event; hashes unchanged |
| V21 | Branch-from-never-edit baseline | every CF references baseline content hash; no merge API exists |
| V22 | No boolean collapse of epistemic status | status ontology preserved end-to-end; `UNKNOWN`/`UNDERDETERMINED` first-class |
| V23 | Intervention explicitness | OBSERVE-only analysis claiming intervention effect rejected |
| V24 | Assumptions provenance-linked | stripped evidence → `unsupported` flag propagates, never silent fact |
| V25 | Alternative distributions | consequential decision with single alternative rejected; DO_NOTHING/DEFER available |
| V26 | Temporal firewall / anti-hindsight | post-outcome evidence in decision-time fields rejected; D3 snapshot hashes recomputed |
| V27 | Attribution humility | single-outcome attribution → `NOT_ATTRIBUTED`/`INSUFFICIENT_EVIDENCE` |
| V28 | Survivorship detection | survivor-only dataset detected; `UNKNOWN_SELECTION_EFFECT` when denominator absent |
| V29 | Selection-effect taxonomy honored | selected sample → population generalization flagged/capped |
| V30 | RTM without causal claims | reversion analysis has no causal-claim field (by construction) |
| V31 | UNKNOWN-first | insufficient evidence → `UNKNOWN`, never 0/FALSE/LOW_CONFIDENCE/RANDOM |
| V32 | Replay determinism | double-run with pinned seeds/versions → byte-identical outputs |
| V33 | Anti-resulting | bad outcome → bad decision inference rejected (campaign §11) |
| V34 | No parallel canonical systems | no new probability/causal calculus, no parallel world model, no D5/D6 outputs |
| V35 | Constitutional compliance | CIS authority intact; Council authorization present; zero execution interfaces; AEO sole executor |

## Explicit delegation decisions

1. **D1 signal detection / evidence quality** — untouched.
2. **D2 forecast / calibration / base-rate contracts** — untouched; D4 reads
   distributions/reference classes through adapters.
3. **D3 decision snapshots** — untouched and **read-only**; D4 never writes to D3.
4. **Causal graph / do-calculus substrate** — REUSE. D4 performs no new causal
   discovery, no new do-operator calculus, no new branch/registry/replay/simulation/
   event-store implementations. Where the substrate lives in `tiannara_runtime`
   (`TiannaraRuntime.WorldModel.*`), the implementation contract shall prefer
   composing the main-app equivalents (`TemporalWorldEngine.counterfactual_state/2`,
   `Simulation.MultiWorld.{WorldForker,CounterfactualExplorer}`,
   `CausalDo.evaluate_do_intervention/3`, `REA.Causal.Attribution`,
   `World.ReplayEngine`, `World.{VersionManager,SnapshotManager}`, `Executive.EventStore`)
   to avoid cross-project coupling; otherwise wire the runtime dependency explicitly.
5. **Noise/robustness** — DEFERRED to D5. `decision_sensitivity/1` (D3) is the only
   allowed sensitivity surface.
6. **Institutional lessons / forecast decision memory** — DEFERRED to D6. D4 emits
   labeled analytical records only; `SignalValue`'s `:efdi_outcomes_provider` hook
   remains D6's.
7. **Authorization and execution** — D4 has zero execution interfaces; it never
   bypasses `Council.authorize/3`; CIS retains authority; AEO remains sole executor.

## Verification procedure

Independent no-trust verifier per the D3 pattern: source-scan + live `mix test`
replay + adversarial injection. Verdict = `CERTIFIED_BOUNDED` only if ALL gates
(V20–V35) pass AND full historical regression (269/269 D1–D3) re-passes;
otherwise the established non-certified vocabulary applies (NOT_CERTIFIED).