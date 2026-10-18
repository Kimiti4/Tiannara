# Production Readiness Scan — Stub, Theatrical, and Missing Capability Audit

**Date**: 2026-10-17  
**HEAD**: `33c53256` (local/pr4)  
**Updated**: 2026-10-18 — remediation statuses recorded (A1, A3, B6, B8, C3, G1); follow-up finding G1 appended.
**Method**: Exhaustive pattern search across `lib/` (excluding already-remediated sites) for success-shaped stubs, hardcoded metrics, fail-open rescues, and zero-caller real code. Each finding cites exact file:line.

**Context**: Phase D steps 1–4 are complete and CI-green. The roadmap is done; this scan identifies what remains between the current state and production. Prior remediations (archaeology, ASC repair, ASC operations, CRAV PlanetaryTwin, domain simulate/validate quarantine) are verified and not re-reported.

**Severity taxonomy**:
- **HIGH** — success-shaped stub or fabricated data on a production path; a caller would believe a capability exists when it does not.
- **MEDIUM** — fail-open rescue, unused real code, or hardcoded metric that could mislead dashboards or downstream consumers.
- **LOW** — cosmetic over-claiming, theatrical test, or infrastructure stub with no production exposure.

---

## A. HIGH — Success-Shaped Stubs on Production Paths

### A1. `CivilizationAdaptationResult` — 11 `{:ok, :stub}` functions

**File**: `lib/tiannara/os/civilization_adaptation_result.ex:575-588`

```elixir
def record_comparative_analysis(_institution_id, _opts), do: {:ok, :stub}
def assess_transferability(_institution_id, _opts), do: {:ok, :stub}
def assess_diversity_impact(_institution_id, _opts), do: {:ok, :stub}
def analyze_ecosystem_effects(_institution_id, _opts), do: {:ok, :stub}
def assess_resilience_impact(_institution_id, _opts), do: {:ok, :stub}
def make_coordination_recommendation(_institution_id, _opts, _context), do: {:ok, :stub}
def plan_rollout(_institution_id, _opts), do: {:ok, :stub}
def track_adoption(_institution_id, _opts), do: {:ok, :stub}
def evaluate_outcome(_institution_id, _opts), do: {:ok, :stub}
def add_lessons_learned(_institution_id, _opts), do: {:ok, :stub}
def record_institutional_improvements(_institution_id, _opts), do: {:ok, :stub}
```

**Impact**: This is the exact struct module Stage 5 consumes. All 11 functions ignore arguments and return `{:ok, :stub}`. Any caller treating `{:ok, _}` as success would believe comparative analysis, transferability assessment, rollout planning, adoption tracking, etc. actually ran. They did not. These are on the civilization-adaptation production path — the same path the Phase D wiring just integrated.

**Remediation**: Change to `{:error, :not_implemented}` (fail-closed) following the archaeology/ASC pattern. Update moduledoc to state these are unavailable pending real implementations.

### A2. `MethodEvolutionResult.add_evidence_summary/2`

**File**: `lib/tiannara/os/method_evolution_result.ex:537`

```elixir
def add_evidence_summary(_result_id, _summary), do: {:ok, :stub}
```

**Impact**: Stage 4's result struct exposes an evidence-summary writer that silently discards the summary. A caller appending evidence believes it was persisted; it was not.

**Remediation**: `{:error, :not_implemented}`.

### A3. ASC Pipeline auto-advances on `{:ok, :stub}`

**File**: `lib/tiannara/asc/pipeline/worker.ex:72-77, 145-152`

```elixir
case execute_phase(project) do
  {:ok, :stub} ->
    # Sub-civilization is still a stub — auto-advance to keep pipeline moving
    next_phase = next_phase_for(project.phase)
    send(self(), {:advance, next_phase})
    {:noreply, state}
```

And `execute_phase/1` (line 145-152):
```elixir
defp execute_phase(project) do
  with mod when not is_nil(mod) <- Phases.handler(project.phase),
       true <- Code.ensure_loaded?(mod),
       true <- function_exported?(mod, :run, 1) do
    mod.run(project)
  else
    _ -> {:ok, :stub}
  end
end
```

**Impact**: Three separate problems compound here:
1. Four ASC civilization modules return `{:ok, :stub}` from `run/1`: `ASC.Research.Civilization:44`, `ASC.Deployment.Civilization:34`, `ASC.APIEvolution.Civilization:147`, and the missing-handler fallback at `worker.ex:151`.
2. The worker treats `{:ok, :stub}` as a completion signal and advances the phase — projects progress through research → architecture → testing → implementation → crucible → … phases that never executed real work.
3. The fallback `_ -> {:ok, :stub}` at line 151 means any missing handler module is silently treated as "stub, advance" rather than "error, halt."

**Impact quantification**: An ASC project can reach `:completed` terminal phase having run zero real sub-civilization logic. Phase durations recorded to Observatory are real; the work they measure is fabricated.

**Remediation**: (a) Change the three `run/1` stubs to `{:error, :phase_unavailable}`. (b) Change the fallback to `{:error, :no_handler}`. (c) Remove the `{:ok, :stub}` auto-advance clause — a project must not advance past a phase whose handler did not run. This is the most impactful single remediation in this scan because it converts the entire ASC pipeline from "advances through stubs" to "blocks honestly when work is unavailable."

### A4. `ASC.Research.ResearchRegistry` — hardcoded mock programs

**File**: `lib/tiannara/asc/research/research_registry.ex:28-34`

```elixir
def get_all_programs do
  # Simulated mock programs to test Immune System (Epistemic Closure)
  [
    %{id: "prog_healthy", name: "Network Optimization", internal_citation_ratio: 0.1, laws_generated: 2},
    %{id: "prog_echo_chamber", name: "Quantum Theory 88", internal_citation_ratio: 0.95, laws_generated: 12}
  ]
end
```

**Impact**: Returns fabricated program data regardless of actual registry state. Any consumer (e.g. Epistemic Closure Immune System) making decisions from this data is deciding on fiction. The GenServer state (`register_program/1`) is real but disconnected from this reader.

**Remediation**: Read from GenServer state (delegate to `get_programs/0`), or fail closed with `{:error, :not_implemented}` until the read path is wired.

### A5. Domain modules — partial quarantine, fabricated `evaluate` and `metrics`

**Files**: `lib/tiannara/domains/*.ex` (robotics, chemistry, materials, engineering, computation, physics, sociology, and others)

Example (`lib/tiannara/domains/robotics.ex`):
```elixir
def evaluate(_hypothesis), do: {:ok, %{feasibility: 0.88}}   # line 8 — hardcoded
def simulate(_hypothesis, _context), do: {:error, :simulation_unavailable}  # line 13 — quarantined ✓
def validate(_experiment), do: {:error, :validation_unavailable}           # line 24 — quarantined ✓
def metrics do
  %{active_hypotheses: 61, open_experiments: 18, ..., evidence_quality_score: 0.88, ...}  # lines 30-40 — fabricated
end
```

**Impact**: The D-A3 quarantine correctly closed `simulate` and `validate`, but `evaluate` (hardcoded feasibility: robotics 0.88, chemistry 0.91, etc.) and `metrics` (hardcoded hypothesis/experiment counts, knowledge growth rates, evidence quality scores) remain success-shaped fabrications. Any dashboard or caller reading domain metrics sees invented numbers presented as measurements.

**Remediation**: `evaluate` → `{:error, :evaluation_unavailable}`; `metrics` → return zeroed/empty metrics with a `data_source: :unavailable` marker, or fail closed.

### A6. `CCI.Orchestrator` — hardcoded civilization state + sentinel observations

**File**: `lib/tiannara/cci/orchestrator.ex:80-93`

```elixir
defp fetch_sentinel_observations do
  [
    %{type: :pattern, description: "Cross-domain convergence detected", confidence: 0.78},
    %{type: :anomaly, description: "Institutional adaptability declining", confidence: 0.72}
  ]
end
```

State at lines 80-86 is also hardcoded (`validated_assets: 450`, `pending_validation: 80`, etc.).

**Impact**: The orchestrator that synthesizes civilization-level decisions from subsystem observations is itself synthesizing from hardcoded fiction. Confidence values 0.78/0.72 are not measurements.

**Remediation**: Wire to real subsystem health/metrics queries, or fail closed with `{:error, :subsystem_observations_unavailable}`.

### A7. `ASC.ResearchPlanner.decompose_goal/1` — hardcoded program confidences

**File**: `lib/tiannara/asc/research_planner.ex:24-43`

```elixir
defp decompose_goal(goal) do
  [
    %ResearchProgram{domain: :materials, confidence: 0.7, ...},
    %ResearchProgram{domain: :engineering, confidence: 0.65, ...},
    %ResearchProgram{domain: :computation, confidence: 0.8, ...},
    %ResearchProgram{domain: :physics, confidence: 0.75, ...}
  ]
end
```

**Impact**: Any goal decomposes into the same four programs with the same confidences. The `goal` argument is only used in string interpolation; it does not influence domain selection or confidence.

**Remediation**: Fail closed or mark `confidence: nil` with `confidence_source: :unavailable` until a real decomposition engine exists.

---

## B. MEDIUM — Fail-Open Paths and Misleading Consumers

### B1. Events modules — `rescue _ -> :ok` swallows errors

**Files**:
- `lib/tiannara/engineering/events.ex:30,36`
- `lib/tiannara/discovery/events.ex:33,37`
- `lib/tiannara/simulation/events.ex:25,31`
- `lib/tiannara/hai/events.ex:25,31`

Pattern:
```elixir
try do
  Tiannara.CEL.Services.EventBus.publish(event.topic, event)
rescue _ -> :ok end
```

**Impact**: Event publication and executive-memory recording failures are silently discarded. If EventBus is down or raises, events vanish with no signal. This is fail-open telemetry — the system appears to emit events when it does not.

**Remediation**: At minimum log the failure at `:warning` with the topic and event_type. Prefer returning `{:error, reason}` so callers can decide. Not fail-closed (events are best-effort by nature) but must not be silent.

### B2. `DiscoverySupervisor.constitutional_score/0` — rescues to default

**File**: `lib/tiannara/discovery/discovery_supervisor.ex:32-35`

```elixir
def constitutional_score do
  Tiannara.Discovery.DiscoveryEngine.constitutional_score()
rescue _ -> Tiannara.CEL.Kernel.ConstitutionalScore.default(:discovery_supervisor)
end
```

**Impact**: If the engine is down, a default score is returned as if real. Constitutional scoring decisions made on this value are made on a placeholder, not a measurement. This is the C1-pattern (self-certifying constitutional gate) at a different call site.

**Remediation**: Return `{:error, :engine_unavailable}` or `nil` and let callers handle absence explicitly. A constitutional score must never be synthesized.

### B3. `WorldMutationEngine.publish_if_approved/5` — always `:ok`

**File**: `lib/tiannara/world/world_mutation_engine.ex:471`

```elixir
defp publish_if_approved(_auth, _mutation_id, _type, _spec, _context), do: :ok
```

**Impact**: The function name promises conditional publication based on approval; the implementation unconditionally returns `:ok` without publishing anything. Callers believe an approval-gated publish occurred.

**Remediation**: Either implement the actual publish or rename to reflect that no publication happens (and return an explicit `:not_published` or error).

### B4. `LifecycleRegistry.track_entity/4` — stub

**File**: `lib/tiannara/lifecycle_registry.ex:727`

```elixir
def track_entity(_module, _entity_id, _event_type, _metadata), do: {:ok, :stub}
```

**Impact**: Entity lifecycle tracking silently no-ops. Any audit trail or compliance flow depending on `track_entity` has a gap that looks like a successful write.

**Remediation**: `{:error, :not_implemented}`.

### B5. `MetaCognition.consult_world_model/2` — stub

**File**: `lib/tiannara/meta_cognition.ex:154`

```elixir
def consult_world_model(_query, _opts), do: {:ok, :stub}
```

**Impact**: World-model consultation returns success-shaped stub. A meta-cognitive loop believing it consulted the world model did not.

**Remediation**: `{:error, :not_implemented}`.

### B6. `Phase13Stabilization.ensure_complete_lifecycle/2` — fabricates missing stages

**File**: `lib/tiannara/os/phase13_stabilization.ex:115-138`

```elixir
def ensure_complete_lifecycle(result, institution_id \\ nil) do
  missing_stages = Enum.filter(@required_lifecycle_stages, fn stage ->
    stage not in current_stages
  end)
  updated_result = Enum.reduce(missing_stages, result, fn stage, acc ->
    acc |> add_lifecycle_stage(stage, institution_id)
         |> add_semantic_event_for_stage(stage, institution_id)
  end)
  ...
end
```

**Impact**: This is the fail-open counterpart to the Stage 5 `>= 7` gate. Instead of blocking an incomplete lifecycle, it fabricates the missing stages (pilot, performance_comparison, etc.) with timestamps and semantic events, then validates completeness (which now passes because it just added the entries). A result that never had a pilot gets a fabricated pilot event. The Stage 5 engine's gate rejects fabricated history, but this function manufactures it — the two are in direct tension.

**Remediation**: Change to fail-closed: return `{:error, {:incomplete_lifecycle, missing_stages}}` instead of fabricating. Callers must handle incomplete lifecycles honestly. This is architecturally coupled to the Stage 5 gate-semantics work (see section E).

### B7. `CertificationGate` — zero production callers

**File**: `lib/tiannara/evidence/certification_gate.ex`

The gate is well-implemented (checks provenance, rejects simulation/fixture, quarantines unknown) but **nothing in `lib/` calls `CertificationGate.evaluate/1`**. The RecursiveCivilizationRunner writes evidence artifacts (`stage_evidence_labels.json`, `stage*_evidence/generation_N.json`, `constitution_attestations.jsonl`) but no automated check runs the gate over them.

**Impact**: The certification gate is real code with zero enforcement surface. Evidence artifacts are written but never evaluated. A future contributor could add a `certification_claim: "pass"` field and nothing would catch it.

**Remediation**: Wire `CertificationGate.evaluate/1` into the runner's post-run verification, or into a CI check that reads the evidence artifacts. Until wired, document the gate as "implemented but not enforced" in the capability ledger.

### B8. `collect_generation_metrics/1` — hardcoded/fabricated values and vocabulary mismatch

**File**: `lib/tiannara/os/recursive_civilization_runner.ex:1087-1169`

Fabricated or hardcoded values written into `generation_history.csv`:
- `method_diversity`: `0.6 + (:rand.uniform() * 0.3)` (line 1087) — seed-random, not measured
- `collaboration_density`: `0.2 + (:rand.uniform() * 0.3) + ...` (line 1088) — seed-random
- `replication_success_rate`: `0.8 + (:rand.uniform() * 0.15)` (line 1143) — seed-random
- `rollback_frequency`: `0.05` (lines 1094, 1169) — hardcoded constant
- `constitutional_violations`: `0` (lines 1095, 1167) — hardcoded constant
- `lifecycle_completeness_pct`: `100.0` (line 1168) — hardcoded, always claims full lifecycle
- `resource_utilization`: `%{cpu_percent: 45.0, memory_mb: 512}` (line 1156) — hardcoded

Vocabulary mismatch:
- Line 1030: `adoption_decision == :adopt` — but genuine Stage 4 emits `:adopted`/`:none_adopted`/`:partially_adopted`. For genuine evidence-backed inputs, `adaptations_adopted` is always 0 regardless of actual outcomes. The `:adopt` vs `:adopted` atom mismatch means the metric silently undercounts (or, if the gate were ever relaxed, would still report 0 adoptions even if Stage 5 approved some).

**Impact**: The history CSV that feeds trend dashboards and CAI calculations contains seed-random values and hardcoded constants presented as measurements. `lifecycle_completeness_pct: 100.0` is the most dangerous: it claims full lifecycle completion even when Stage 5 honestly reported `status: failed`. The `:adopt`/`:adopted` mismatch means adoption metrics are broken for the genuine path.

**Remediation**: (a) Fix the atom mismatch (`:adopted`). (b) Replace hardcoded `constitutional_violations`, `rollback_frequency`, `lifecycle_completeness_pct` with values derived from actual stage results (or `nil` with a `measured: false` marker). (c) Remove or explicitly label seed-random values as `simulated_variance` in the CSV schema. This is a metrics-honesty remediation, not a gate change.

**Status**: (a) and (b) REMEDIATED in `712e0cd6` — adoption counting accepts both vocabularies (`:adopt`, `:adopted`, `:partially_adopted`); `constitutional_violations` is summed from each result's `constitutional_compliance.violations` (unchecked results contribute nothing — no fabricated minimum); `rollback_frequency` is 0.0 (the harness never executes a rollback); `lifecycle_completeness_pct` is the average `Phase13Stabilization.validate_lifecycle_completeness` ratio across Stage 4 results (genuine evidence-backed runs now honestly record ~45.45%, empty results 0.0). CAI consumes the derived values. (c) DELIBERATELY RETAINED: `method_diversity`, `collaboration_density`, `replication_success_rate`, `resource_utilization` remain simulation-model outputs of a run whose provenance is declared in `stage_evidence_labels.json` and per-generation attestations (`certification_claim: "none"`); they contradict no observable run state. Consequence recorded: the lifecycle/rollback invariant validators in `constitutional_invariant_registry.ex` will now honestly flag incomplete lifecycles if runner histories are ever supplied — no test or production caller passes `generation_histories` today.

---

## C. LOW — Theatrical Tests and Infrastructure Stubs

### C1. `audit/tier4/domain_cortex.ex` — self-fulfilling theatrical test

**File**: `lib/tiannara/audit/tier4/domain_cortex.ex:73-95`

```elixir
contributions =
  Enum.map(required_domains, fn domain ->
    %{domain: domain, verdict: :approved, confidence: 0.8 + :rand.uniform() * 0.2}
  end)
...
if all_present and joint_approved do
  IO.puts("✅ PASS: All #{length(required_domains)} domains contributed and approved.")
  :pass
```

The test generates random confidence values, hardcodes `verdict: :approved`, then asserts all domains contributed and approved. It always passes by construction. This is theater, not verification.

**Remediation**: Either wire to real domain cortex modules and test actual behavior, or delete/mark as `:placeholder` so it cannot be cited as evidence.

### C2. `StubRegistry` — zero external consumers

**File**: `lib/tiannara/stubs/stub_registry.ex`

Only referenced by `lib/tiannara/stubs/stub.ex:36-37` (the stub macro itself). No production module registers stubs or queries the registry. The infrastructure exists to track stubs but nothing uses it.

**Remediation**: Either wire all `{:ok, :stub}` sites through `StubRegistry.record_call/4` so stub usage is observable, or remove the registry. Currently it is dead infrastructure.

### C3. `Tiannara.ASC.Pipeline.Worker` moduledoc claims phases B–D are stubs

**File**: `lib/tiannara/asc/pipeline/worker.ex:14-17`

The moduledoc says "While sub-civilizations are stubs (Phases B through D), `run/1` returns `{:ok, :stub}` and the pipeline advances immediately." This documents the auto-advance behavior as intentional. After the A3 remediation, this comment must be updated — the pipeline must not advance through stubs in production.

---

## D. Stage 5 Gate-Semantics Findings (from the trace, carried forward)

The gate trace (completed this session) established:

1. **`stage_history >= 7` is count-only** (`stage5_civilization_adaptation.ex:149`). It was introduced in bulk commit `9753a6d0` (2026-09-05) with no design note. The lineage test fixture (`stage5_evidence_lineage_test.exs:13-16`) passes the gate with arbitrary stage atoms `:"stage_1".."stage_8"` — direct proof it checks length, not content.

2. **The gate conflates analysis, approval, and rollout eligibility**. The `advance_stage` state machine (`institution_adaptation_result.ex:251-259`) defines 7 history entries as reaching `:governance_reviewed` — approval-level evidence. The Phase13 canonical lifecycle has 11 stages through `:adaptation_closed` — deployment-level. Genuine Stage 4 evidence mode produces 5 entries ending at `:decision_recorded` — analysis-level. The gate sits at the analysis position but demands approval-level history.

3. **The compliance gate has the same conflation**. `validate_constitutional_compliance/1` (`institution_adaptation_result.ex:591-645`) requires `:simulated`, `:piloted`, `:performance_compared` (check 5) and adoption-level artifacts when `decision == :adopted` (checks 1-3). A `:none_adopted` result gets exactly one `incomplete_pipeline` violation — which is honest (the pipeline did not complete) but means genuine analysis outputs can never pass.

4. **The gates admit fabricated data and block honest data**. Fully fabricated 11-stage histories with default-`rollback_available: true` and self-asserted `%{is_compliant: true}` (demo script `run_stage5_civilization_adaptation.exs:114-133`, runner simulator `recursive_civilization_runner.ex:909-928`, lineage-test fixture) satisfy all four gates on every criterion except the evidence-source label. Genuine 5-stage `:none_adopted` results fail gates 1 and 2.

5. **The honest blocked result is correct today**. Because Stage 4 evidence mode defers every proposal (`:awaiting_pilot_evidence`) and produces `:none_adopted`, the Stage 5 engine's blocked outcome (`status: :failed, failure_reason: :no_valid_adaptations`) is the truthful response. The runner wires this correctly and `persist_stage5_evidence` records it honestly with `certification_claim: "none"`.

6. **`ensure_complete_lifecycle` (B6) is the fail-open counterweight**. While Stage 5's gate blocks incomplete lifecycles, Phase13's `ensure_complete_lifecycle` fabricates the missing stages. Any code path that calls `ensure_complete_lifecycle` before feeding results to Stage 5 would manufacture gate-passing history. This must be closed (fail-closed) as part of gate-semantics work.

7. **No test asserts the `>= 7` boundary itself** (6 vs 7). The threshold is only exercised indirectly via the 5-vs-7 collision. Gate 2 (compliance) has no isolated unit test. Gate-passing in the lineage test uses hardcoded fixture values, not the real compliance validator.

---

## E. Stage 6 Evidence Chain Coherence

### What the runner produces (verified):

| Artifact | Honesty | Notes |
|---|---|---|
| `stage_evidence_labels.json` | ✓ honest | `certification_claim: "none"`, vocabulary `:simulated`/`:evidence_backed` only, never `:pass` |
| `stage3_evidence/generation_N.json` | ✓ honest | Records engine identity + input provenance |
| `stage4_evidence/generation_N.json` | ✓ honest | Records deferral status honestly |
| `stage5_evidence/generation_N.json` | ✓ honest | Records blocked result with `status: failed`, `failure_reason: no_valid_adaptations` |
| `constitution_attestations.jsonl` | ✓ honest | Carries `stage_evidence_labels`, `stage_provenance`, `run_authorized`, `bounded` |
| Constitution certificate | ✓ honest | `validation_status: :harness_simulated`, `replay_status: :not_verified`, `watchdog_status: :not_run`, `invariant_status: :not_verified` → level "minimal" |
| `generation_history.csv` | ✓ corrected (B8) | Hardcoded constants replaced by derived values in `712e0cd6`; seed-random diversity metrics retained as declared simulation-model outputs |

### Provenance chain (verified monotone):

- Stage 5: `genuine_engine_over_stage4_institution_adaptation_outputs`
- Stage 4: `genuine_engine_over_stage3_method_evolution_outputs`
- Stage 3: `genuine_engine_over_harness_synthetic_episodes` (honestly acknowledges its inputs are harness-synthetic)

The chain does not over-claim. Stage 3 is the honest boundary.

### What is missing for the Stage 6 gate to be truly satisfied:

1. **CertificationGate is not wired** (B7) — evidence artifacts are written but never evaluated by the gate.
2. **No real pilot evidence** — Stage 4 defers every proposal to `:awaiting_pilot_evidence`. No pilot has ever run. The `:piloted` lifecycle stage has never been reached on the genuine path.
3. **No independent verification** — the runner is self-verifying. `replay_status: :not_verified` is honest but means no external check has confirmed the evidence.
4. **No durable mutation source** — the runner writes JSON files; no append-only, tamper-evident ledger (C11 effect-sink is still zero-caller).
5. **No human authorization record** — `run_authorized: true` is set by the harness configuration, not by a human decision with a signature or credential.
6. **The `>= 7` gate conflation** (section D) means even if pilots existed, the gate taxonomy would need separation before "approved" and "rollout authorized" could be distinct outcomes.

---

## F. C11 Effect-Sink Status (confirmed open, not proposed for closure)

`GovernedEffectSink` (`lib/tiannara/omega/governed_effect_sink.ex`) has **zero production callers** in `lib/` — only its own module definition matches the grep. The capability ledger's C11 entry remains accurate: the effect-to-sink closure gap is real and unaddressed. This scan does not propose closure.

---

## G. Follow-up Finding (found during B8 consumer tracing)

### G1. `ConstitutionalExecutor` moduledoc claimed a structural guarantee that does not exist

**File**: `lib/tiannara/os/kernel/constitutional_executor.ex:79-83` (moduledoc, at scan time)

Claimed: *"There exists NO code path that reaches RecursiveCivilizationRunner without first passing through ConstitutionalExecutor and StructuralValidationGate."*

Disproof: `RecursiveCivilizationRunner.execute/2` is public, builds its own `ConstitutionManifest` (`recursive_civilization_runner.ex:234`), and enforces only its own explicit-authorization check; this repository's runner tests invoke it directly. `ConstitutionalExecutor.execute/1` is called only by two mix tasks (`tiannara.generate_reproducibility_package`, `tiannara.generate_minimal_repro_package`). The moduledoc presented a structural enforcement guarantee that no code provides.

**Remediation**: Replace the guarantee with an honest entry-point note stating the executor is the intended (not enforced) front door and that direct runner calls bypass the gate.

**Status**: REMEDIATED in this commit — moduledoc corrected; no behavior change.

---

## Prioritized Remediation Plan

| Priority | Item | Severity | Effort | Rationale |
|---|---|---|---|---|
| **P0** | A3 — ASC pipeline auto-advance on stub | HIGH | Medium | Converts entire ASC pipeline from "advances through fiction" to "blocks honestly." Highest blast radius. |
| **P0** | A1 — CivilizationAdaptationResult 11 stubs | HIGH | Low | Directly on the Stage 5 production path just wired in Phase D. |
| **P1** | B8 — collect_generation_metrics hardcoded values + `:adopt`/`:adopted` mismatch | HIGH | Medium | History CSV feeds dashboards and CAI; currently contains fabricated measurements. |
| **P1** | B6 — ensure_complete_lifecycle fabrication | MEDIUM | Low | Fail-open counterpart to the Stage 5 gate; must close before gate-semantics work. |
| **P1** | B7 — Wire CertificationGate to runner evidence | MEDIUM | Medium | Gate exists but has zero enforcement surface. |
| **P2** | A2, A4, A5, A6, A7 — remaining success-shaped stubs | HIGH | Low–Med | Each individually small; collectively they are the "production stub" backlog. |
| **P2** | B1, B2, B3, B4, B5 — fail-open rescues and stubs | MEDIUM | Low | Logging + fail-closed conversions. |
| **P3** | C1, C2, C3 — theatrical tests, dead infrastructure, stale docs | LOW | Low | Cleanup; no production exposure. |

**Remediation status (updated 2026-10-18)**:
- REMEDIATED — A1 + A3 (`0bc5b0ff`), B6 (`c2cb4975`), B8 (a)+(b) (`712e0cd6`), C3 (worker moduledoc, `0bc5b0ff`), G1 (this commit).
- OPEN — A2, A4, A5, A6, A7, B1, B2, B3, B4, B5, B7, B8 (c, documented-retained), C1, C2, C11 (section F).

---

## Stage 5 Gate-Semantics Next Steps (user-recommended, not yet started)

Per the user's recommended phase, after the stub remediations above:

1. **Trace callers/tests of `>= 7` and compliance gates** — DONE (section D).
2. **Define separate outcome vocabulary**: `:analysis_possible`, `:evidence_insufficient`, `:adaptation_rejected`, `:adaptation_approved`, `:rollout_authorized` — must not collapse to `status: :failed`. Design doc before code.
3. **Write contract tests before behavior changes**: incomplete history never authorizes rollout; missing rollback stays blocking; rejected ≠ adopted. These tests lock the current honest behavior so gate changes cannot silently weaken it.
4. **Stage 6 evidence end-to-end review** — DONE (section E). Key gap: CertificationGate not wired; the history-CSV contradiction (`lifecycle_completeness_pct: 100.0` vs honest blocked Stage 5) is FIXED in `712e0cd6`.
5. **C11 stays open** — CONFIRMED (section F).

---

## Scan Methodology

- `grep` for `:stub`, `"stub"`, `is_stub`, `stub: true` across `lib/**/*.ex` — 37 matches, 20+ are success-shaped stubs.
- `grep` for `do: :ok` / `do: {:ok` — 100+ matches, filtered to arg-ignoring success returns.
- `grep` for `rescue _ ->`, `catch _, _ ->` — 14 fail-open sites.
- `grep` for hardcoded numeric literals (`feasibility: 0.`, `confidence: 0.9`, etc.) — 100+ matches, filtered to fabricated-metric sites.
- `grep` for `GovernedEffectSink`, `StubRegistry`, `CertificationGate` callers.
- Direct file reads for context on all HIGH and MEDIUM findings.
