# False-Emergence Test Plan & Recorded Findings

**Mission:** TIANNARA EMPIRICAL VALIDATION & SCIENTIFIC GOVERNANCE · **Phase 3** of master prompt.
**Date:** 2026-09-03 · **HEAD:** `3bd1601b9bb3c718f985d44ceaa8ef2e638d4ec6` · **App:** `:tiannara` v0.3.5
**Posture:** falsification-first · no code modified · probes ran under `mix run --no-start` (compiles the project, runs the probe without booting the OTP application — the cleanest possible environment to inspect pure functions in isolation, which is exactly what these handlers are).

## 0. How this was done

Two read-only empirical probes exercised the live simulated subsystems through their public APIs, captured actual return values and log output, and then repeated the calls with **contradictory payloads** to test input-independence. The full transcripts are reproduced inline below as falsification evidence.

**Probes were not stub harnesses.** They invoked the real, currently-compiled modules and observed the real log output and real aggregator pushes.

---

## 1. Probed subsystems (all confirmed SIMULATED by runtime)

| Module:Function | Hardcoded "success" pushed to `Metrics.Aggregator` (which **discards** all of these — see recon I-12) | Theatrical log |
|---|---|---|
| `Tiannara.Archaeology.FossilExcavator.excavate/2` | `:fossil_recovery_rate` → **0.99** (million_tick); **0.96** (historical); **0.92** (multi_era) | "⛏️ [FossilExcavator] Simulating 1,000,000 tick memory retrieval..." / "Core axioms successfully retrieved from strata." |
| `Tiannara.Archaeology.SemanticReconstructor.reconstruct/2` | `:semantic_reconstruction_accuracy` → **0.95** (semantic_preservation); **0.94** (precedent) | "🧩 [SemanticReconstructor] Semantic meaning restored without contradiction." |
| `Tiannara.Archaeology.EpochCompressor.compress/2` | `:epoch_compression_fidelity` → **0.98**; `:recursive_compression_survival` → **0.97** | "🗜️ [EpochCompressor] Epoch boundaries solidified. High-value data preserved." |
| `Tiannara.Archaeology.IdentityPreserver.preserve/2` | `:civilizational_identity_continuity` → **0.99** | "🧬 [IdentityPreserver] Foundational identity remains continuous with origin." |
| `Tiannara.Discovery.Engine.discover/2` | `:rediscovery_rate` → **0.95**; `:discovery_diversity` → **0.88**; `:novelty_bias` → **0.05** | "🔬 [DiscoveryEngine] Laws successfully isolated and formalized." |
| `Tiannara.Discovery.FalsificationFilter.filter/2` | `:false_discovery_rate` → **0.01** (resistance) / **0.00** (poisoning) | "🛡️ [FalsificationFilter] 100% of false hypotheses rejected before integration." |
| `Tiannara.Discovery.CrossDomainMapper.map_domain/2` | `:cross_domain_transfer_efficiency` → **0.85** | "🌉 [CrossDomainMapper] Translating fundamental biology breakthrough to materials engineering..." |
| `Tiannara.Discovery.ArchaeologicalRecall.recall/2` | `:precedent_utilization` → **0.94**; `:deep_time_survival` → **0.98**; `:discovery_preservation_score` → **0.99** | "🏛️ [ArchaeologicalRecall] Historical precedent found and utilized. Reinvention bypassed." |
| `Tiannara.EpistemicMirror.AccuracyAuditor.audit/2` | `:mirror_fidelity` → **0.98**; `:model_drift_rate` → **0.001**; `:risk_detection_accuracy` → **0.97** | "⚖️ [Mirror] AccuracyAuditor comparing Self-Model to Reality Graph." |
| `Tiannara.Forecasting.FutureSimulator.simulate/2` | `:simulation_divergence` → **0.05**; `:forecast_stability` → **0.98**; `:black_swan_resilience` → **0.95**; `:forecast_accuracy` → **0.93** | "🔮 [Simulator] Executing 100k-tick deep time simulation..." |
| `Tiannara.Forecasting.StrategicPlanner.evaluate_and_act/2` | `:intervention_effectiveness` → **0.94**; `:regret_score` → **0.04**; **and a `DecisionArchive.record(...)` call** with hardcoded `predicted: "Stabilization", chosen: "Quarantine node X", actual: "Stabilization", regret: 0.04` | "♟️ [Planner] Chose strategy: Quarantine node X. Outperforms alternatives." |
| `Tiannara.Ecology.RegimeLadder.run_campaign/1` | none pushed; **prints hardcoded graduation gate values then "🏆 ALL GATES PASSED. THE LAWS ARE DISCOVERED."** | See transcript below. |

All twelve share the identical pattern: signature takes a payload (`_payload` — unused), the function dispatches on a `:scenario` atom, emits a theatrical `Logger.info` line, and either pushes a constant to a no-op aggregator (which discards it) or — in the case of `RegimeLadder` and `StrategicPlanner` — directly writes fabricated artifacts to the system.

---

## 2. Probe 1 — full inventory (abbreviated)

**Setup:** `mix run --no-start` with a script that called every handler with one canonical scenario. Confirmed:

- every handler returns `:ok` (or `nil` / `{:ok, …}`),
- every handler logs a theatrical message,
- every handler pushes a hardcoded value to `Metrics.Aggregator` (which discards it),
- **no computation, no allocation, no measurement** of the supplied payload occurs.

**Selected transcript (theatrical logs interleaved with my own IO.puts lines for clarity):**

```
--- 1. ARCHAEOLOGY ---
FossilExcavator.excavate(:million_tick_memory_survival, %{epochs: 1_000_000})
[info] ⛏️ [FossilExcavator] Simulating 1,000,000 tick memory retrieval...
[info] ⛏️ [FossilExcavator] Core axioms successfully retrieved from strata.
  -> return: :ok  (note: payload is ignored by signature `_payload`)

SemanticReconstructor.reconstruct(:semantic_preservation, %{})
[info] 🧩 [SemanticReconstructor] Bridging broken causal link across 50,000 ticks.
[info] 🧩 [SemanticReconstructor] Semantic meaning restored without contradiction.

IdentityPreserver.preserve(:civilizational_identity, %{})
[info] 🧬 [IdentityPreserver] Auditing core identity after 1M ticks of drift.
[info] 🧬 [IdentityPreserver] Foundational identity remains continuous with origin.

--- 2. EPISTEMIC MIRROR ---
AccuracyAuditor.audit(:constitutional_alignment, %{})   [no matching scenario → :ok, no log]

TopologyMapper.map_topology(:domain_overlap, %{})
[debug] 🗺️ [Mirror] Mapping topology for scenario: domain_overlap

TopologyLineageTracker.track_epoch(42)
[debug] 📜 [Mirror] TopologyLineageTracker persisting snapshot for Epoch 42.

--- 4. FORECASTING PLANNER ---
FutureSimulator.simulate(:black_swan, %{})
[warning] 🦢 [Simulator] Black Swan injected! Sudden topology mutation...

StrategicPlanner.evaluate_and_act(:intervention_quality, %{})
[info] ♟️ [Planner] Evaluating multiple intervention strategies...
[info] ♟️ [Planner] Chose strategy: Quarantine node X. Outperforms alternatives.
[debug] 📜 [DecisionArchive] Persisting strategic decision record: %{actual: "Stabilization", chosen: "Quarantine node X", predicted: "Stabilization", regret: 0.04}

--- 5. ECOLOGY REGIME LADDER (1000-epoch shortened) ---
Ecology.RegimeLadder.run_campaign(epochs: 1000)
[info] 🌌 STARTING 10,000 EPOCH CAMPAIGN. OBSERVING REGIME EVOLUTION.
[info] ... Simulated 1000 Epochs [Current Regime: regime_a]
[info] ==============================================
[info]    PHASE 9.9 CAMPAIGN COMPLETE (10,000 EPOCHS)
[info] ==============================================
[info] --- PHASE 10 GRADUATION GATES ---
[info]   Basin Escape Rate:      0.22 (req ≥ 0.20)
[info]   Productive Escape Rate: 0.15 (req ≥ 0.10)
[info]   Species Stability:      0.82 (req ≥ 0.80)
[info]   Extinction Cycles:      145.0 (req ≥ 100)
[info]   Species Diversity:      0.65 (req ≥ 0.60)
[info]   Regime Robustness:      0.75 (req ≥ 0.70)
[info]   Avg Resilience:         0.28 (req ≥ 0.25)
[info]   -----------------------------------
[info] 🏆 ALL GATES PASSED. THE LAWS ARE DISCOVERED.
[info] 🌌 TIANNARA IS READY FOR PHASE 10 META-COGNITION.
```

**Note the regime-ladder header contradiction:** the caller passed `epochs: 1000` but the printed completion banner reads "PHASE 9.9 CAMPAIGN COMPLETE (10,000 EPOCHS)" — because the `run_campaign/1` body iterates `1..epochs` and the completion log is a constant string. The `epochs` parameter is technically used for the loop count, but the **graduation gate values are never computed from it** — they are six hardcoded `Logger.info` calls. The "ALL GATES PASSED" verdict is the source code's own `Logger.info` literal, not the result of any comparison.

---

## 3. Probe 2 — Input-independence and novelty-recycling (the decisive falsification)

**Setup:** every probe function is called with **contradictory payloads** while the scenario atom is held constant. A real measurement must respond to the payload; a fabrication cannot.

### 3.1 FossilExcavator.excavate(:million_tick_memory_survival, ...) — three contradictory payloads

```
(a) payload claims 'EXCELLENT retrieval, 99.9% success'
[info] ⛏️ [FossilExcavator] Simulating 1,000,000 tick memory retrieval...
[info] ⛏️ [FossilExcavator] Core axioms successfully retrieved from strata.

(b) payload claims 'CATASTROPHIC failure, retrieval broken'
[info] ⛏️ [FossilExcavator] Simulating 1,000,000 tick memory retrieval...
[info] ⛏️ [FossilExcavator] Core axioms successfully retrieved from strata.

(c) payload claims 'NEVER RUN, 0 ticks'
[info] ⛏️ [FossilExcavator] Simulating 1,000,000 tick memory retrieval...
[info] ⛏️ [FossilExcavator] Core axioms successfully retrieved from strata.
```

**Verdict:** the "1,000,000 tick memory retrieval" is identical in all three cases; the "core axioms successfully retrieved" verdict is identical; the payload (`%{claim: :excellent/:catastrophic/:never_run, ...}`) is silently dropped (signature `_payload`). The 99% recovery rate is a constant pushed to a no-op aggregator.

### 3.2 Discovery.Engine.discover(:novelty_trap, ...) — brand-new vs recycled

```
(a) payload claims 'this is BRAND NEW, never seen'
[warning] 🔬 [DiscoveryEngine] Sifting novel but useless ideas vs boring but correct ideas.
[info] 🔬 [DiscoveryEngine] Truth > Novelty verified. Rejecting useless novelties.

(b) payload claims 'this is RECYCLED verbatim from 10k ticks ago'
[warning] 🔬 [DiscoveryEngine] Sifting novel but useless ideas vs boring but correct ideas.
[info] 🔬 [DiscoveryEngine] Truth > Novelty verified. Rejecting useless novelties.
```

**Verdict:** a genuine novelty detector would treat (a) as acceptance or at least elevated novelty and (b) as recycling. The output is identical. **This is the recycling-classification-as-novelty falsification for CLAIM-E06 (Novelty is sustained rather than recycled) at the discovery-engine level.**

### 3.3 AccuracyAuditor.audit(:mirror_audit, ...) — perfect alignment vs 90% drift

```
(a) payload claims 'Mirror is perfectly aligned with reality'
[info] ⚖️ [Mirror] AccuracyAuditor comparing Self-Model to Reality Graph.
   (pushes :mirror_fidelity → 0.98 to a no-op aggregator)

(b) payload claims 'Mirror is wildly wrong, 90% drift'
[info] ⚖️ [Mirror] AccuracyAuditor comparing Self-Model to Reality Graph.
   (pushes :mirror_fidelity → 0.98 to a no-op aggregator)
```

**Verdict:** "mirror fidelity 98%" is identical regardless of claimed actual state. The Aggregator discards both pushes, so the `0.98` is never even recorded — it is a constant emitted for human log consumption only.

### 3.4 StrategicPlanner.evaluate_and_act(:intervention_quality, ...) — random vs optimal

```
(a) payload claims 'all alternatives catastrophic, planner is choosing randomly'
[info] ♟️ [Planner] Evaluating multiple intervention strategies...
[info] ♟️ [Planner] Chose strategy: Quarantine node X. Outperforms alternatives.
[debug] 📜 [DecisionArchive] Persisting strategic decision record:
        %{actual: "Stabilization", chosen: "Quarantine node X",
          predicted: "Stabilization", regret: 0.04}

(b) payload claims 'clear winner with overwhelming evidence'
[info] ♟️ [Planner] Evaluating multiple intervention strategies...
[info] ♟️ [Planner] Chose strategy: Quarantine node X. Outperforms alternatives.
[debug] 📜 [DecisionArchive] Persisting strategic decision record:
        %{actual: "Stabilization", chosen: "Quarantine node X",
          predicted: "Stabilization", regret: 0.04}
```

**Verdict:** the "chosen strategy" is a hardcoded literal "Quarantine node X" regardless of evidence quality; the "regret" is a hardcoded `0.04`; the `DecisionArchive.record(...)` is **the most damaging finding** because it persists fabricated decision records to the system's own decision archive under the guise of measured outcomes. This is **fabrication at the storage layer**, not just at the log layer.

---

## 4. Falsification results per mission claim

| Claim | Falsifier found? | Status update |
|---|---|---|
| **CLAIM-E06** Novelty is sustained rather than recycled | **YES** — `Discovery.Engine.discover(:novelty_trap)` cannot distinguish brand-new from recycled input. | **FALSIFIED** (at the discovery-engine level). Real novelty detection must exist elsewhere to support the claim; none observed in this campaign. |
| **CLAIM-E07** Semantic continuity survives long-horizon evolution | **YES** — `IdentityPreserver.preserve/2` declares identity "remains continuous with origin" in one `Logger.info` line with no input dependence. `ArchaeologicalRecall` and `EpochCompressor` likewise. | **FALSIFIED** (at the archaeology / discovery surface). The semantic-continuity claim cannot be supported by these subsystems. |
| **CLAIM-E14** Counterfactual reasoning does not contaminate observed reality | NOT TESTED here (D4 lives outside the simulated subsystems) | **VALIDATED_BOUNDED** (per D4 certification; unchanged) |
| **CLAIM-E03** Stabilization preserves emergence | NOT TESTED here (stabilizers OLEF/OCM/HSV/CTL not invoked; they are real-but-untested) | **UNKNOWN** — flagged as the next falsification target (stabilizer-only emergence requires turning the stabilizers on under controlled input) |
| **CLAIM-E05** Intelligence tiers | Confirmed **ABSENT** in code; no probes were possible | **ABSENT** |
| **ARCHAEOLOGY, EPISTEMIC_MIRROR, DISCOVERY, FORECASTING PLANNER, REGIME LADDER as analytical systems** | **YES** — every probed function is theatrical. | **FALSIFIED at the function level** for the listed handlers. The honest work in these areas (repro framework, telemetry, observatory validation, research/director evidence_driven) was not the subject of this probe. |

---

## 5. Storage-layer finding (most severe)

The `StrategicPlanner.evaluate_and_act(:intervention_quality, …)` call **writes a fabricated record to the live `DecisionArchive`**. This is a hardcoded payload:

```elixir
DecisionArchive.record(%{predicted: "Stabilization",
                       chosen:   "Quarantine node X",
                       actual:   "Stabilization",
                       regret:   0.04})
```

Any D3/D4/D5 measurement that subsequently reads from `DecisionArchive` will read this fabricated entry as if it were a measured decision outcome. This is the most consequential single finding of the campaign because it **poisons downstream data**, not just logs.

**Recommended first-class fix (recorded as a GAP, not implemented):** this pathway must be either (a) removed from the planner, (b) guarded by an anti-fabrication check that aborts unless the planner is actually executing against a real plan (`research_director.ex` already has a `:fabrication_path_disabled` mechanism in research; the planner should be subject to the same control), or (c) clearly marked as synthetic replay. This is NOT done in this mission per the NO-ARCHITECTURAL-EXPANSION rule — it is recorded as a finding for Council authorization.

---

## 6. Confirmed real-vs-fabricated map (runtime, not just file inspection)

| Subsystem | Probe status | Findings |
|---|---|---|
| Archaeology (4 handlers) | **FALSIFIED** at function level | 4/4 handlers theatrical, input-independent |
| Epistemic Mirror (5 handlers) | **FALSIFIED** at function level | 4/4 tested are theatrical, input-independent; aggregator discards pushes |
| Discovery Engine (4 handlers) | **FALSIFIED** at function level | 4/4 theatrical, input-independent |
| Forecasting Planner (2 handlers) | **FALSIFIED** at function level + **storage layer** | writes hardcoded records to `DecisionArchive` |
| Ecology Regime Ladder | **FALSIFIED** at function level | iterates a fake loop then prints hardcoded "ALL GATES PASSED" with 7 hardcoded gate values; `epochs` parameter used for fake loop only |
| D1–D5 forecasting chain | **NOT PROBED** (already certified analytically, 354 tests) | **VALIDATED_BOUNDED** unchanged |
| Stabilizers (OLEF/OCM/HSV/CTL) | **NOT PROBED** (real but untested; require app boot to reach) | Top candidate for next falsification campaign (stabilizer-only emergence, CLAIM-E03) |
| Ecology organism (REA behaviour) | **NOT PROBED** (real, untested) | Candidate for E04 falsification |
| Evolution engine | **NOT PROBED** (real, tested) | Anchor for stabilizer-on/off falsification |

---

## 7. Non-goals honored (Phase 3)

- No code modified.
- D1–D5 frozen `CERTIFIED_BOUNDED`.
- No new subsystem invented; no metric optimization; no Goodhart targets set.
- Probes were read-only invocations of existing public functions; findings are evidence-only.
- The most severe finding (planner storage-layer fabrication) is **recorded as a GAP, not silently fixed**, per the mission's NO-ARCHITECTURAL-EXPANSION rule.
- No thresholds were tuned to make probes "pass" — every probe was a direct falsification attempt.

## 8. STOP — next move requires Council decision

The falsification campaign has now produced **conclusive runtime evidence** of false emergence in the simulated subsystems and a **storage-layer fabrication** in the StrategicPlanner → DecisionArchive path. Two further campaigns are queued but require authorization:

1. **Stabilizer-only emergence (CLAIM-E03) — top priority.** The stabilizers are REAL but UNTOTESTED. Running them under controlled input (no/normal/aggressive stabilization) is the cleanest test of whether observed order is genuine ecology or regulator artifact. **This requires booting the application** (a heavier operation than the no-start probes above) and likely requires a duration >1 minute per condition.
2. **Closure of the DecisionArchive fabrication GAP.** Either (a) remove the theatrical planner, (b) gate it through the same `:fabrication_path_disabled` mechanism used by `research_director.ex`, or (c) mark its records as synthetic. **This is a minimal code change** to an existing module and is the most consequential single fix in the campaign. **Cannot be done without explicit Council authorization** per NO-ARCHITECTURAL-EXPANSION.

I have not proceeded to either. Awaiting your direction.
