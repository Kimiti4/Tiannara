# Tiannara — Empirical Validation: Reconnaissance

**Mission:** TIANNARA EMPIRICAL VALIDATION & SCIENTIFIC GOVERNANCE (master prompt).
**Phase 0 output.** Verdict on capability honesty is derived from **source inspection of the live repository**, not from filenames, module names, docs, or claimed certification. D1–D5 remain `CERTIFIED_BOUNDED` and are terminal for this mission; no code was modified.

**Date:** 2026-09-03 · **HEAD:** `3bd1601b9bb3c718f985d44ceaa8ef2e638d4ec6` · **App:** `:tiannara` v0.3.5

---

## 0. How this reconnaissance was conducted

Three independent source scans (read-only, no modifications) were run against `lib/tiannara/` and root scripts. The governing rule of the mission applies: *Do not trust filenames. Do not trust documentation. Do not trust module names. Do not trust claimed certification. Verify implementation and runtime behavior.* Every classification below cites concrete files and the actual code behavior observed.

Runtime feasibility was additionally confirmed: `mix.exs` `mod: {Tiannara.Application, []}`, a 53+-child `:one_for_one` supervision tree (Council Tier-0 → CEL ServiceRegistry → CEL Kernel → 32 EOS services via DynamicSupervisor → core/loop children), and **3,500+ compiled `.beam` artifacts** across `_build/dev` (1,457) and `_build/test` (2,066). The system compiles and is structurally bootable.

---

## 1. Runtime posture (calibrated to the mission's honesty bar)

The system is **heterogeneous** and cannot be judged as a whole. It contains four sharply different classes that the mission must keep distinct:

1. **REAL (implemented + tested or genuinely algorithmic):** world model, simulation engine + multiworld, evolution + long-horizon validation, council + CIS control, telemetry + observatory validation harness, `repro/` framework, research proposal pipeline (honest, execution-disabled), and the **D1–D5 forecasting chain (354 tests, 0 failures)**.
2. **REAL but UNTESTED (large, zero dedicated tests):** the stabilizer subsystem **OLEF / OCM / HSV / CTL** (~2,500+ lines of GenServer code) is the single largest untested area and the top robustness-risk candidate.
3. **SIMULATED / theatrical ("looks real, is not"):** `archaeology/`, `epistemic_mirror/`, `discovery/engine.ex`, `forecasting/planner.ex`, `validation/campaign.ex`, `ecology/regime_ladder.ex`, and the root `simulation_output/*.csv`. These log hardcoded metrics/success values; the `Metrics.Aggregator` even **discards** the pushes.
4. **STUBBED (genuine placeholders, mostly via `use Tiannara.Stub`):** all 12 modules in `lib/tiannara/stubs/`, plus `p9x_ecosystem/` (empty supervisor), `civics/` (10-line placeholder), and several empty supervisors.

Two important honesty signals found:
- Experiment **execution is deliberately disabled** (`lib/tiannara/research/research_director.ex` Pipeline quarantines every dequeued experiment with reason `:fabrication_path_disabled`). This is a **genuine anti-fabrication control** already in place — and it means **no durable experimental results yet exist**.
- `evidence/provenance.ex` explicitly refuses to fabricate a `kind`, and `acceptable_as_evidence?` is true only for `:real_execution`. This is honest-by-construction scaffolding, but there is **no persisted evidence ledger** (zero persistence functions in `evidence/` and `provenance/`).

---

## 2. Capability classification (REAL / PARTIAL / SIMULATED / STUBBED / UNKNOWN)

| Named capability in mission | Live classification | Evidence |
|---|---|---|
| **World state / world model** | **REAL** | 27+ modules in `world/` (UnifiedWorldModel 481L, WorldMutationEngine 373L, VersionManager 418L, ReplayEngine, TemporalWorldEngine, SnapshotManager); 19 test files incl. property-based + chaos tests |
| **Simulation engine / multiworld / scenario / horizon / impact** | **REAL** | `simulation/` GenServer + formula-based pipeline; multiworld (forker/counterfactual/comparison); 4 test files incl. property tests. NOTE: is formula computation (logistic/wtd-avg), not physics simulation |
| **P9X ecosystem** | **STUBBED** | `p9x_ecosystem/supervisor.ex` — 1 file, empty children list |
| **Ecology (civilization organism + tracker)** | **REAL** | `ecology/civilization.ex` (full REA `EvolutionaryOrganism` behaviour, 236L), `ecology.ex` (ETS tracker, Shannon diversity, 380L). No dedicated tests |
| **Ecology regime ladder** | **SIMULATED** | `ecology/regime_ladder.ex` logs **hardcoded** gate numbers (`Basin Escape Rate: 0.22 ...`) with comment `# Mock the final gate outputs`; values never computed |
| **Civics** | **STUBBED** | `civics/constitution.ex` — 10 lines, `# Placeholder`, returns `[]` |
| **Orbits (classifier)** | **PARTIAL** | `orbital/classifier.ex` — 14-line trivial `cond` (3 thresholds); no tests. Orbit *analysis* ecosystem lives in `discoveries/` (orbit_residency, orbit_resilience, orbit_reachability) computing metrics from `data/orbit_transitions.ndjson` whose provenance is **unknown**; no tests |
| **Stabilization: OLEF / OCM / HSV / CTL** | **REAL (UNTESTED)** | OLEF 362+324L, OCM 702+263L, HSV 471+295L, CTL 515L — real diffusion/consensus/archival/causal-lattice GenServers. **Zero dedicated test files** (~2,500+ lines untested) |
| **Evolution engine** | **REAL** | `evolution/` evolution_engine, long_horizon (tested), drift_audit, constitutional_auditor, trajectory; 3 test files |
| **Intelligence tiers** | **ABSENT** | "intelligence tier" **0 matches** in `lib/` `.ex`; only 2 mentions in `.md`. The "Tier" concept in code is the **certification protocol** (Tier1Cognitive–Tier6Discovery) and audit tiers — not an intelligence progression |
| **Forecasting D1–D5** | **REAL + TESTED** | `forecasting/` full chain; **354 tests, 0 failures** (D1–D5). `planner.ex` is SIMULATED (sub-parts hardcoded) |
| **Council / CIS control** | **REAL** | `council/council.ex` (emergency lockdown, `authorize/3`), `cis/supervisor.ex` CollapsePredictor computes grounded risk from live telemetry, returns `{:unknown, :insufficient_evidence}` rather than fabricating |

### Scientific/empirical infrastructure

| Area | Classification | Evidence |
|---|---|---|
| `repro/` (manifest, verdict, artifact_bundle) | **REAL** | git commit + `System.version()` + deterministic SHA-256 `config_hash`; `:reproduced/:divergent/:inconclusive` |
| `observatory/validation/` (campaign+checks+metrics_store) | **REAL** | live `:erlang.memory()`, `:erlang.processes()`, `:scheduler_wall_time`; ETS store (in-memory) |
| `telemetry/` (RuntimeAdapter, observatory checks, telemetry_sink) | **REAL** | live BEAM metrics; `data/metrics_snapshot.ndjson` persisted via `metrics/export.ex`; most handlers log-only |
| `discovery/pipeline_telemetry.ex` | **REAL (honest)** | reads live counters; reports `:uninstrumented` when a reader can't resolve |
| `research/director/evidence_driven.ex` | **REAL (honest)** | full investigation-only pipeline (info-gain ranking); **never executes** |
| `evidence/` + `provenance/` | **REAL schema, NO persistence** | honest `kind` taxonomy (refuses fabrication); **zero persistence functions**; no ledger |
| `archaeology/` | **SIMULATED** | FossilExcavator/SemanticReconstructor/etc. log `"Simulating 1,000,000 tick memory retrieval..."` and push hardcoded recovery scores (0.99, 0.96, ...) |
| `epistemic_mirror/` | **SIMULATED** | accuracy_auditor/collapse_predictor/... push hardcoded fidelity (0.98), calibration (0.99); `mirror_registry` is empty supervisor |
| `discovery/engine.ex` | **SIMULATED** | scenario handlers with hardcoded metrics (0.95, 0.05, ...) |
| `forecasting/planner.ex` | **SIMULATED** | hardcoded regret/effectiveness; records hardcoded "Stabilization" prediction |
| `validation/campaign.ex` + `validation/registry` | **SIMULATED / EMPTY** | `# Simulate execution`; `validation/registry` children = `[]` |
| `metrics/aggregator.ex` | **REAL (discards sim pushes)** | genuine GenServer; the simulated `:mirror/:forecasting/:archaeology/...` casts are **no-op drops** |
| `stubs/` (12 modules) | **STUBBED (genuine)** | all use `use Tiannara.Stub` → `StubRegistry` + `[:tiannara,:stub,:called]` telemetry; hardcoded defaults (e.g. LongitudinalMemory → `leoc: [1.0,0,0,0]`) |
| `verification_authority.ex` | **REAL-but-non-functional (honest)** | returns `%{reproduced: false, method: :unavailable}`, `reason: :not_independently_assessed` |
| "Independent audit" (`run_independent_audit*.exs`, `PHASE14_...REPORT.json`) | **ARTIFACT-FINGERPRINT ONLY** | recomputes SHA-256 of frozen JSON + trusts each campaign's **self-declared** `status: "passed"`; does **not** re-derive results |
| Experiment registry | **PARTIAL / IN-MEMORY ONLY** | `research/director.ex` ETS tables (`:research_hypotheses`, `:research_experiments`); not disk-persisted; **no durable experiment-result registry** |
| Evidence ledger | **ABSENT** | no persisted ledger anywhere |
| Root `simulation_output/*.csv` | **SIMULATED** | 11-line scripted synthetic campaigns; near-linear "measurements", flat constants (cycle_duration=25), all 0 adaptations; not real data |

---

## 3. Most consequential findings for the falsification campaign

1. **False emergence is materially present.** Multiple "smart-looking" subsystems are theatrical: `archaeology/`, `epistemic_mirror/`, `discovery/engine.ex`, `forecasting/planner.ex`, `ecology/regime_ladder.ex`, and the synthetic CSVs. These are prime FALSE-EMERGENCE targets — the mission's central concern is embodied in the current code.
2. **The stabilizer stack is the largest untested surface.** OLEF/OCM/HSV/CTL (~2,500+ lines) have zero tests. Any "stability/robustness/emergence" claim resting on them is **UNVALIDATED** and susceptible to **stabilizer-only emergence** (regulatory artifact vs. genuine ecology).
3. **No durable experiment registry and no persisted evidence ledger exist.** The mission's Phase 2–4 (baseline, long-horizon campaigns, reproductions) must first build the honest recording layer — the anti-fabrication controls (`:fabrication_path_disabled`, provenance `kind` honesty) are already in place to support it.
4. **The "independent audit" is not independent** — it verifies artifact integrity and trusts self-declared PASS. The mission's Phase 19 no-trust auditor requirement is unmet.
5. **Intelligence tiers do not exist in code** — the claim (mission CLAIM-E05) is currently **UNKNOWN/ABSENT**, not falsifiable as stated.
6. **Orbit claims are under-supported:** the classifier is trivial; the analysis modules read NDJSON whose origin is unverified. Orbit claims are **UNKNOWN** until provenance + tests exist.
7. **The D1–D5 chain is the trustworthy anchor** — the one area genuinely implemented AND tested (354/0). It can serve as the reference-grade harness for noise/robustness evaluation.

---

## 4. Real runtime entry points (verified)

- **App boot:** `Tiannara.Application.start/2` → supervision tree → `register_subsystems()` → `BootSequencer.boot()` → `CEL.Kernel.boot()` (32 EOS services).
- **Council gate:** `Tiannara.Council.authorize/3`.
- **Genuine harnesses:** `tiannara_runtime/run_god_loop.exs` (real GenServer loop), `tiannara_runtime/run_validation.exs` (10 named campaigns), root `run_phase99_campaign.exs` (`Ecology.RegimeLadder.run_campaign/1`), root `run_ecological_stress_test.exs` + `run_ecology_stabilization.exs` (substantial 196/195-line harnesses referencing real modules), `run_phase10_campaign.exs` (50,000 simulated epochs on real BreakthroughAnalyzer).
- **Watch-out:** several harnesses run SIMULATED epochs (e.g. phase10's `Enum.each` loop of `record_breakthrough`); they are demo harnesses, not measurements.

---

## 5. Exclusions / non-goals honored this phase

- **No code was modified.** Reconnaissance was read-only.
- D1–D5 remain `CERTIFIED_BOUNDED` and are not extended or rewritten.
- No new subsystem was invented; findings are recorded as claims/baseline for the Council.
- Scope for **this** phase: reconnaissance only. Per the master prompt, **DO NOT IMPLEMENT UNTIL THE RECONNAISSANCE AND CLAIM REGISTRY ARE COMPLETE.**
