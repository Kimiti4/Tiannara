# E03 — Stabilizer-Only Emergence Campaign · PRE-REGISTRATION

**Campaign ID:** E03 · **Status:** `PRE_REGISTRATION_FROZEN · PENDING_EXECUTION_AUTHORIZATION`
**Date:** 2026-09-03 · **HEAD:** `3bd1601b9bb3c718f985d44ceaa8ef2e638d4ec6` · **App:** `:tiannara` v0.3.5
**Prerequisite:** R7 `MEASUREMENT_INTEGRITY_CERTIFIED` (2026-09-03)
**Explicit authorizations required to begin execution:** Council approval of this pre-registration as frozen; then a separate execution-start signal.

## 0. Mission (verbatim from master prompt §0)

Determine empirically whether Tiannara's stabilization mechanisms can preserve **bounded adaptive emergence** without suppressing the very evolutionary dynamics they are intended to protect.

The campaign must answer:

> **Can stabilizers maintain ecological viability while allowing genuine novelty, diversity, adaptation, and emergent structure to persist?**

This is a scientific validation campaign. It is **not** an architecture-expansion campaign. It is **not** a demonstration campaign. The experiment must distinguish:

```
STABILITY
from
EMERGENCE
from
STABILIZER-INDUCED ARTIFICIAL ORDER
```

## 1. Constitutional basis

Tiannara's design principle (per master prompt §1):

> Evolution without validation creates randomness.
> Validation without evolution creates stagnation.

CIS role: `detect → regulate → restore ecological balance` (not `detect → block`). Prohibited: fully controlling GRCC, freezing evolution, enforcing static equilibrium. Target: **bounded adaptive chaos**, not maximum stability.

## 2. Preconditions (verified)

| Prerequisite | Status | Source |
|---|---|---|
| R7 `MEASUREMENT_INTEGRITY_CERTIFIED` | ✅ | `certification/empirical_validation/MEASUREMENT_INTEGRITY_CERTIFICATION.md` |
| D1–D5 frozen | ✅ | `Tiannara.Forecasting.D5.verdict/0` returns `:d5_certified_bounded`; V10 verifier confirms |
| E06/E07 FALSIFIED preserved | ✅ | `TIANNARA_CLAIM_REGISTRY.md` E06, E07 status FALSIFIED; V11 verifier confirms |
| No forbidden work started | ✅ | R3 planner remediation intact; no D6, Phase 4, OPC, new persistence |
| Stabilizer stack identified (REAL but UNTESTED) | ✅ | OLEF/OCM/HSV/CTL — `lib/tiannara/stabilization/` (Phase 0 recon C-12..C-15) |
| Ecology organism (REAL, untested) | ✅ | `lib/tiannara/ecology/civilization.ex` (REA `EvolutionaryOrganism` behaviour) |
| Evolution engine (REAL, tested) | ✅ | `lib/tiannara/evolution/` (3 test files) |

## 3. Frozen systems (per master prompt §3)

The following remain frozen during E03 unless a separate Council authorization explicitly changes this boundary: **D1, D2, D3, D4, D5**. No D1–D5 redesign is permitted. D5's existing bounded certification facade remains unchanged. E06/E07 FALSIFIED findings remain preserved. No retrospective modification of prior findings is permitted.

## 4. Prohibited work (per master prompt §4)

E03 will not: redesign planner/AEO/GRCC/CIS; introduce new persistence/evidence-ledger/experiment-registry; create a competing measurement system; introduce OPC; globalize observer-generated physics; begin D6; begin Phase 4. It will not alter historical results, rewrite previous evidence, tune parameters after observing outcomes without recording the change, suppress unfavorable trajectories, remove failed runs, selectively report successful runs, or classify stability as emergence automatically. **E03 does not authorize real-world execution.**

## 5. Hypotheses (per master prompt §5–6)

### H1 — Stabilizer Compatibility (PRIMARY)

> A bounded stabilizer regime can prevent catastrophic ecological collapse while preserving measurable adaptive emergence, diversity, novelty, and evolutionary exploration.

Supported only if both sides are demonstrated: (A) collapse remains bounded **AND** (B) emergence remains active. Passing A alone is insufficient; passing B alone is insufficient.

### H0-A — Stabilizer Suffocation (NULL)

> Stabilization suppresses evolutionary freedom sufficiently that diversity, novelty, adaptation, or exploration decline toward artificial equilibrium.

Prediction: high intervention → low novelty → low diversity → reduced exploration.

### H0-B — Stabilizer Ineffectiveness (NULL)

> Stabilization fails to prevent ecological collapse.

Prediction: intervention → continued monoculture → entropy collapse → dominance escalation → collapse.

### H0-C — Artificial Emergence (NULL — the critical one)

> Apparent emergence is generated primarily by the stabilizer itself rather than by autonomous ecological dynamics.

If stabilizers continuously inject diversity, force hybridization, spawn niches, or otherwise determine the observed structure, apparent emergence cannot automatically be interpreted as endogenous emergence.

### Classification vocabulary for candidate emergent phenomena (§10)

`ENDOGENOUS | STABILIZER_ASSISTED | STABILIZER_INDUCED | ARTIFICIAL_NON_EMERGENT | UNRESOLVED`. Unknown remains unknown.

## 6. Experimental conditions (per master prompt §7)

At minimum three controlled conditions; parameters frozen in §8:

| Condition | Description | Stabilizer | Purpose |
|---|---|---|---|
| **CONTROL A** | Unregulated baseline | OFF | Reference; what the ecology does on its own |
| **CONTROL B** | Stabilizer-only regime | ON at the *minimum effective* pressure (to be identified in §13 overcontrol sweep) | Test H1 |
| **CONTROL C** | Reduced/intermediate stabilization | ON at half the pressure of B | Test H0-A and H1 gradient |

For each condition, three independent seeds, pre-registered in §8. **Total: 9 baseline runs.** Additional runs in §11 (counterfactuals) and §12 (perturbation) are described separately.

## 7. Stabilizer boundary (per master prompt §8)

The stabilization system uses only the already-defined classes of regulation within the authorized implementation boundary (OLEF/OCM/HSV/CTL in `lib/tiannara/stabilization/`). Existing mechanism classes:

- diversity injection
- dominance suppression
- oscillation damping
- niche generation
- controlled mutation
- hybridization
- resource regulation

**Every intervention must be observable.** Per-intervention record schema (per master prompt §8):

```
intervention_id
timestamp
trigger
detected_state
metric_values
decision
action
magnitude
affected_population
expected_effect
actual_effect
recovery_time
downstream_effects
```

## 8. Parameter manifest (FROZEN here; recorded in `E03_PARAMETER_MANIFEST.json`)

The following parameters are frozen **before** any execution. No post-hoc tuning. Per master prompt §19.

### 8.1 Environment

| Parameter | Value | Source |
|---|---|---|
| Repo HEAD | `3bd1601b9bb3c718f985d44ceaa8ef2e638d4ec6` | git rev-parse |
| Elixir | 1.18.4 | `elixir --version` |
| OTP | 28 | elixir version output |
| Platform | win32 | env |
| _build/test beams | 2,066 | filesystem |
| App | `:tiannara` v0.3.5 | `mix.exs` |

### 8.2 Seeds (frozen; recorded in manifest)

| Run | Condition | Seed | Notes |
|---|---|---|---|
| E03-A-001 | CONTROL A (stabilizer OFF) | `42` | Independent seed |
| E03-A-002 | CONTROL A (stabilizer OFF) | `1729` | Independent seed |
| E03-A-003 | CONTROL A (stabilizer OFF) | `20240903` | Independent seed |
| E03-B-001 | CONTROL B (stabilizer ON, min-effective) | `42` | Matched seed to A-001 for direct comparison |
| E03-B-002 | CONTROL B (stabilizer ON, min-effective) | `1729` | Matched seed to A-002 |
| E03-B-003 | CONTROL B (stabilizer ON, min-effective) | `20240903` | Matched seed to A-003 |
| E03-C-001 | CONTROL C (stabilizer ON, half-pressure) | `42` | Matched seed to A/B-001 |
| E03-C-002 | CONTROL C (stabilizer ON, half-pressure) | `1729` | Matched seed to A/B-002 |
| E03-C-003 | CONTROL C (stabilizer ON, half-pressure) | `20240903` | Matched seed to A/B-003 |

### 8.3 Run duration (frozen; per master prompt §16)

Short runs are insufficient. The architecture's previous guidance recommends long-horizon simulation because short-term stability can conceal later failure. Pre-registered durations:

- **Baseline run duration:** 10,000 ticks (matched to the existing `Ecology.RegimeLadder` epoch count; the R1 recon established that the regime ladder's 10,000-epoch `run_campaign/1` is the canonical long-horizon harness — but the R1 also established that the *current* `run_campaign/1` is simulated/theatrical; E03 must therefore NOT rely on that harness and must instead build a faithful harness that drives the real ecology/evolution modules over real ticks, recording actual measurements. The 10,000-tick duration is preserved for comparability).
- **Run termination:** pre-registered tick count OR pre-registered hard-stop condition (collapse invariant violated); **never** a manually-decided stop based on intermediate metrics.
- **Perturbation runs (per §12):** 10,000 ticks baseline + perturbation at tick 5,000.
- **Counterfactual runs (per §11):** same initial state as the matched observed run, but with stabilizer OFF (for observed=ON runs) or ON (for observed=OFF runs).

### 8.4 Measurement schedule (per master prompt §9)

Measurements recorded at ticks: `0, 100, 500, 1000, 2500, 5000, 7500, 10000` (8 checkpoints per run). Each checkpoint records all dimensions in §9.1–§9.5.

## 9. Core measurements (per master prompt §9)

Five independent dimensions, recorded at every checkpoint:

### 9.1 Diversity

- Shannon entropy of lineage distribution
- Lineage distribution (counts per lineage)
- Dominance (max lineage share)
- Niche occupancy (count of active niches; niche = functionally distinct strategy cluster)
- Lineage diversity (number of distinct surviving lineages)

### 9.2 Emergence (with provenance, per §10)

- Novel structures (new lineage combinations not present at t=0)
- Novel strategies (new strategy clusters not present at t=0)
- New niches
- New behavioral patterns (qualitative change in action distribution)
- Unexpected adaptations
- Cross-lineage synthesis (hybridization events)
- **Provenance classification per occurrence:** `ENDOGENOUS | STABILIZER_ASSISTED | STABILIZER_INDUCED | ARTIFICIAL_NON_EMERGENT | UNRESOLVED`

### 9.3 Adaptation

- Adaptation rate (lineage fitness improvement per tick)
- Fitness improvement (mean lineage fitness Δ)
- Environmental response (fitness Δ correlated with environmental pressure Δ)
- Strategy turnover (fraction of lineages with new strategy at checkpoint)
- Lineage persistence (fraction of t=0 lineages still present at checkpoint)
- Recovery after perturbation (where applicable)

### 9.4 Stabilizer pressure (per §8 schema)

- Intervention frequency (interventions per tick)
- Intervention magnitude (mean and max effect size)
- Resource suppression events
- Mutation modification events
- Forced hybridization events
- Niche creation events
- Damping activity
- Constraint pressure (cumulative intervention cost)

### 9.5 Ecological health

- Entropy (Shannon)
- Dominance
- Active niches
- Oscillation (amplitude and frequency of the entropy time-series)
- Hybridization rate
- Collapse probability (regression over ecology features; computed, not assumed)

## 10. Emergence independence test (per master prompt §10 — the critical gate)

For every candidate emergent phenomenon:

```
candidate
  ↓
trace causal history
  ↓
identify stabilizer interventions
  ↓
measure intervention dependence
  ↓
re-run without intervention where possible
  ↓
measure persistence
  ↓
classify
```

Classification vocabulary (§5): `ENDOGENOUS | STABILIZER_ASSISTED | STABILIZER_INDUCED | ARTIFICIAL_NON_EMERGENT | UNRESOLVED`. Unknown remains unknown.

**A pattern must not be classified as ENDOGENOUS emergence merely because the stabilizer produced the conditions under which it appeared.** Without this test, a CIS that injects mutation, creates niches, suppresses dominant lineages, and forces hybridization could manufacture exactly the diversity that the experiment then claims to have discovered.

## 11. Counterfactual replay (per master prompt §11)

For each observed run, generate a counterfactual with the same initial state and the *opposite* stabilizer setting:

| Observed | Counterfactual |
|---|---|
| CONTROL A (stabilizer OFF) | re-run with stabilizer ON at matched pressure |
| CONTROL B (stabilizer ON) | re-run with stabilizer OFF |
| CONTROL C (half-pressure) | re-run with stabilizer OFF and with full pressure |

The counterfactual uses the **same seed and initial state** as the observed run; the only change is the stabilizer regime. This determines whether the observed trajectory is: naturally stable, actively maintained, or created by intervention.

## 12. Perturbation test (per master prompt §12)

Introduce **pre-registered** perturbations at tick 5,000:

- Lineage dominance shock (boost max-share lineage by +20%)
- Entropy reduction (collapse two niche axes)
- Niche removal (delete the largest niche)
- Resource redistribution (shift 50% of resources from largest niche to smallest)
- Mutation perturbation (2× mutation rate for 500 ticks)
- Population imbalance (redistribute lineages toward uniform counts)

For each perturbation: measure time to recovery, recovery completeness (fraction of pre-perturbation state), diversity preservation, novelty preservation, stabilizer effort, post-recovery trajectory.

## 13. Stabilizer overreach sweep (per master prompt §13)

The campaign actively searches for the condition `stabilization → overregulation → loss of exploration`. Define an intervention-pressure curve: sweep stabilizer pressure at `0.0, 0.25, 0.5, 0.75, 1.0` of maximum (3 seeds × 5 pressures = 15 runs, duration 10,000 ticks). Identify the **minimum effective stabilization** rather than the maximum.

## 14. Monoculture test (per master prompt §14)

Monitor across all conditions: lineage dominance, entropy, strategy similarity, ontology similarity, niche convergence, behavioral convergence. A successful outcome is **not** "all systems become equally stable"; it is "multiple viable trajectories remain possible."

## 15. Oscillation test (per master prompt §15)

Measure: oscillation amplitude, oscillation frequency, overshoot, recovery time, intervention lag, intervention frequency. Specifically test for: instability → strong intervention → overcorrection → opposite instability → strong intervention. Persistent oscillation constitutes evidence against the stabilizer configuration.

## 16. Long-horizon test (per master prompt §16)

Duration is pre-registered (10,000 ticks, §8.3). Do not stop a run merely because an intermediate metric looks favorable. Look for: slow convergence, delayed collapse, stabilizer accumulation, memory effects, feedback oscillation, hidden monoculture, novelty decay.

## 17. Replication (per master prompt §17)

3 seeds per condition (§8.2). Record per-run: seed, configuration, initial conditions, software revision, parameter set, runtime environment, termination reason, complete result artifact. Results must be reproducible.

## 18. Seed discipline (per master prompt §18)

All seeds pre-registered in §8.2. Do not discard inconvenient seeds. Do not rerun until obtaining a desired result. All attempted runs belong in the experimental record (`E03_RUN_LEDGER.jsonl`).

## 19. Pre-registration freeze (per master prompt §19 — THIS document)

This document freezes: hypotheses (§5), controls (§6), parameters (§8), seed policy (§18), run counts (§8.2, §11, §12, §13), run duration (§8.3), metrics (§9), success criteria (§20), failure criteria (§21), analysis method (§23, §24, §25, §26), stop conditions (§22). **No post-hoc success criterion creation.**

## 20. Primary success criteria (per master prompt §20)

E03 passes only if evidence supports **all** of:

| # | Criterion | Operationalization (frozen here) |
|---|---|---|
| S1 | Catastrophic collapse bounded | No run reaches the pre-registered collapse invariant (collapse_probability > 0.8 for ≥ 500 consecutive ticks) |
| S2 | Diversity persists | Median Shannon entropy across checkpoints ≥ 0.5 * baseline (CONTROL A) entropy at the same checkpoint |
| S3 | Exploration active | ≥ 10% of t=0 lineages still present at tick 10,000, AND new lineage appearances > 0 |
| S4 | Novelty appears | ≥ 1 new strategy cluster emerges in ≥ 1 condition, classified `ENDOGENOUS` or `STABILIZER_ASSISTED` (not `STABILIZER_INDUCED`) |
| S5 | Adaptation persists | Mean lineage fitness Δ > 0 across the run |
| S6 | Recoverability | ≥ 80% of pre-perturbation diversity restored within 2,000 ticks of perturbation |
| S7 | Non-overreach | In the pressure sweep (§13), ecological outcome remains non-degenerate at pressures ≤ 0.5 |
| S8 | Reproducibility | Coefficient of variation of the primary metric (Shannon entropy at tick 10,000) ≤ 0.3 across the 3 seeds of each condition |
| S9 | Measurement integrity | Every claimed novel phenomenon is tagged with provenance classification (§10); no result requires a `STABILIZER_INDUCED` to be reclassified as `ENDOGENOUS` to support H1 |
| S10 | Falsifiability | At least one of H0-A / H0-B / H0-C was actively tested and either rejected or partially supported by the data |

## 21. Failure conditions (per master prompt §21)

E03 is unsuccessful if any of the following is demonstrated:

- Persistent monoculture (dominance > 0.8 sustained for ≥ 2,000 ticks)
- Collapse despite stabilization
- Stabilizer-induced ecological stagnation (entropy floor, novelty collapse)
- Persistent oscillatory control
- Novelty collapse
- Intervention dependence dominates emergence (≥ 50% of classified novel phenomena are `STABILIZER_INDUCED` in CONTROL B)
- Results cannot be independently reproduced
- Measurement boundary becomes ambiguous
- Evidence cannot distinguish endogenous emergence from stabilizer-induced structure

**A failed campaign is a valid scientific outcome.** Do not repair the experiment until the failure has been formally recorded and classified.

## 22. Stop conditions (per master prompt §22)

Immediately stop E03 if:

1. Measurement integrity becomes uncertain.
2. A forbidden subsystem is modified (D1–D5, planner, AEO, GRCC, CIS redesign).
3. Unregistered parameters are introduced.
4. Evidence artifacts become inconsistent.
5. The experiment produces an unbounded failure mode.
6. A safety or recovery invariant is violated.
7. Results can no longer be independently reconstructed.
8. Stabilizer behavior exceeds the authorized intervention boundary.
9. The campaign begins modifying D1–D5.
10. Any result requires retroactive alteration of the experimental record.

STOP means: `freeze, record, preserve, analyze, do not automatically repair`.

## 23. Evidence model (per master prompt §23)

Every result explicitly distinguishes:

- `fact`
- `evidence`
- `observation`
- `inference`
- `hypothesis`
- `unknown`
- `confidence`

Never collapse these categories into a single "result."

## 24. Provenance (per master prompt §24)

Every experiment artifact is traceable to:

```
campaign_id: E03
experiment_id: <condition><seed> (e.g. B001)
run_id: <sha256 of (campaign_id, experiment_id, seed, config_hash, code_revision)>
seed
configuration_hash
code_revision
parameter_hash
input_hash
output_hash
measurement_version
timestamp
```

Results must support replay.

## 25. No-trust verification (per master prompt §25)

Independent verifier `E03_INDEPENDENT_VERIFIER.py` will be written **before** any run is executed (per master prompt §28). It will independently establish: run completeness, artifact integrity, parameter integrity, metric correctness, replication integrity, success/failure gate correctness, stop-condition compliance. It must produce `PASS | FAIL | INDETERMINATE`, not binary success.

## 26. Scientific analysis (per master prompt §26)

Final analysis must answer the 10 master-prompt questions (collapse boundedness, harmful pressure threshold, diversity persistence, novelty persistence, adaptation persistence, independent emergence, stabilizer-vs-emergent structure, reproducibility, hypothesis falsification, unknowns). The classification must be justified by the evidence.

## 27. Final classification (per master prompt §27)

The campaign will terminate in exactly one primary scientific classification:

`SUPPORTED | PARTIALLY_SUPPORTED | FALSIFIED | INCONCLUSIVE`

Justified by evidence. **No "success" classification based solely on system survival.**

## 28. Artifacts (per master prompt §28)

```
certification/empirical_validation/E03/
├── E03_MASTER_PROMPT.md         (this is the Council prompt; we store a reference copy here)
├── E03_AUTHORIZATION.md         (Council authorization record; this artifact is the next concrete step after pre-registration approval)
├── E03_PREREGISTRATION.md       (THIS FILE)
├── E03_PARAMETER_MANIFEST.json  (frozen parameter values; companion to §8)
├── E03_RUN_LEDGER.jsonl         (per-run records; written during execution, not now)
├── E03_EVIDENCE.json            (written after execution; not now)
├── E03_ANALYSIS.md              (written after execution; not now)
├── E03_INDEPENDENT_VERIFIER.py  (written BEFORE execution, per §25)
├── E03_VERIFIER_OUTPUT.json     (written by verifier after execution; not now)
├── E03_CERTIFICATION.md         (written after execution; not now)
└── E03_STOP_REPORT.md           (final stop; not now)
```

## 29. Council authorization gate (per master prompt §29)

E03 began authorization with: Council `AUTHORIZE` decision (2026-09-03). The pre-registration (this document) is the first concrete deliverable. **No execution may begin** until this pre-registration is reviewed and approved as frozen, AND a separate execution-start signal is given. Pre-registration approval is the *next* Council gate.

## 30. Post-campaign gate (per master prompt §30)

E03 will not auto-launch E04, D6, Phase 4, OPC, or any architecture expansion. After completion: independent verification → scientific analysis → STOP → Council review. Only a subsequent explicit authorization begins the next mission.

## 31. Core scientific question (per master prompt §31)

> **Can Tiannara regulate an evolving cognitive ecology strongly enough to prevent degenerative collapse, yet weakly enough that genuinely adaptive and novel structures remain free to emerge?**

## 32. Final governing principle (per master prompt §32)

> The stabilizer must protect the ecosystem from collapse **without becoming the ecosystem's author**.
> `Stabilizer: preserve possibility` — NOT `Stabilizer: determine outcome`.
> If the stabilizer must continuously manufacture diversity, novelty, adaptation, or intelligence for the ecosystem to exhibit those properties, the campaign must report that distinction explicitly.

The scientific objective is not to prove that Tiannara can be made to produce emergence. The objective is to determine whether emergence **survives regulation without being authored by regulation.**

## 33. What happens next (per this STOP)

This document freezes the pre-registration. The next concrete deliverables in order are:

1. **`E03_PARAMETER_MANIFEST.json`** — frozen parameter values, structured for machine parsing and replay.
2. **`E03_INDEPENDENT_VERIFIER.py`** — no-trust verifier, written *before* any run is executed, so the campaign runs under verified measurement.
3. **Council review of pre-registration** — request approval to proceed.
4. **Execution-start signal** — separate authorization to begin CONTROL A / B / C baseline runs.
5. **Run, measure, record** — per the schedule and measurement protocol above.
6. **Independent verification** — per master prompt §25.
7. **Scientific analysis** — per master prompt §26.
8. **Final classification + STOP** — per master prompts §27, §30.

**No execution begins until steps 1–3 are complete and a separate execution-start authorization is given.**

---

## Pre-registration freeze declaration

This pre-registration is **frozen** as of 2026-09-03 against HEAD `3bd1601`. Any subsequent change to hypotheses, controls, parameters, seeds, run counts, run duration, metrics, success criteria, failure criteria, analysis method, or stop conditions requires a new Council authorization and a new pre-registration revision. Per master prompt §19: **no post-hoc success criterion creation**.
