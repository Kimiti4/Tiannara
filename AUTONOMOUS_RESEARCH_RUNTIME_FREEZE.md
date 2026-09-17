# Phase 17.8.05 — Autonomous Research Runtime Freeze

document_version: 17.8.05
phase: 17.8
status: Frozen
owner: Constitutional Research Council
depends_on:
  - AUTONOMOUS_RESEARCH_PROGRAM_ARCHITECTURE.md (CAR PASS)
  - RESEARCH_EXECUTION_PIPELINE.md (CAR complete)
  - RESEARCH_PROGRAM_DATA_MODEL.md (CAR complete)
  - ARPE_REPLAY_MODEL.md (CAR complete)
  - ARPE_CERTIFICATION.md (CAR complete)
supersedes: null

---

## Constitutional Freeze Declaration

This document constitutionally freezes all schemas, APIs, behaviors, replay contracts,
archaeology contracts, ownership contracts, and determinism contracts for the Phase 17.8
Autonomous Research Programs & Experimentation (ARPE) subsystem.

**No contract defined here may change after this freeze.**

Changes to frozen contracts require a new epoch version and a new CAR.

No implementation may begin before this document exists.

---

## What "Frozen" Means

A component is frozen when all of the following are fixed for this epoch:

1. Schemas — JSON structure, required fields, canonical serialization rules
2. Behavior contracts — allowed inputs/outputs, determinism requirements, error semantics
3. API surfaces — function signatures and request-response field sets
4. Replay prerequisites — which stage outputs are replay-critical and at which level
5. Evidence mapping rules — how Digital Twin outputs map to evidence bundles
6. Constitutional compliance gates — which conditions block stage transitions
7. Configuration contract — which values must come from epoch-frozen config (never hardcoded)

Anything not explicitly frozen in this document is non-binding for this epoch.

---

## 1. Frozen Schemas

All schemas are content-addressed (blake3). Schema version: 17.8.0.

### 1.1 Schemas Extended from Phase 16.1 (verbatim + phase_17_8_ext namespace)

| Schema | Extension Fields |
|---|---|
| KnowledgeGap | phase_17_8_ext: gap_source, twin_provenance_hash, source_snapshot_hashes |
| ResearchExperiment | phase_17_8_ext: simulation_scenario_binding_id, twin_executable, math_verification_id |
| ResearchEvidence | phase_17_8_ext: twin_outcome_id, simulation_fingerprint, normalization_proof_hash |

All other Phase 16.1 schemas (ResearchQuestion, ResearchPriority, ResearchProgram,
ResearchStatisticalValidation, ResearchTheoryUpdateProposal, DiscoveryLineage) are
used verbatim with no extensions.

### 1.2 New Phase 17.8 Schemas

| Schema | Canonical ID Rule |
|---|---|
| ExperimentPortfolio | blake3(canonical(epoch_id + selected_program_ids + config_hash)) |
| ExperimentBudget | blake3(canonical(portfolio_id + per_program_allocations + algorithm_version)) |
| ExperimentSchedule | blake3(canonical(portfolio_id + budget_id + dispatch_intents)) |
| SimulationScenarioBinding | blake3(canonical(experiment_id + scenario + variable_mappings + seed)) |
| ResearchOutcome | blake3(canonical(program_id + disposition + completed_experiment_ids + validation_ids)) |
| ProgramReplayFingerprint | blake3(canonical(program_id + merkle_root + artifact_ids_replayed + replay_config_hash)) |
| ProgramArchaeologyRecord | blake3(canonical(program_id + originating_gap_ids + experiment_lineage + theory_update_lineage)) |
| MathematicalVerificationResult | blake3(canonical(experiment_id + checks_performed + substrate_version + verification_config_hash)) |
| ARPECertificate | blake3(canonical(program_id + outcome_id + fingerprint_id + audit_id + issuer_id + timestamp)) |

### 1.3 Canonical Serialization Contract (Frozen)

1. Stable key ordering: lexicographic over field names
2. Number formatting: IEEE 754 canonical; no NaN, no Infinity, no locale formatting
3. Null vs missing: null fields are explicitly serialized as `null`; missing fields are absent
4. Array ordering: deterministic as specified per field in schema definition
5. String encoding: UTF-8 with no BOM
6. Boolean: lowercase `true` / `false`
7. Content-addressed ID computation: blake3 of the above canonical JSON, excluding the ID field itself

---

## 2. Frozen APIs

All API contracts define the function signature and behavior contract only.
No implementation is defined here.

### 2.1 ARPEKnowledgeGapDetector

```
detect_gaps(
  world_model_snapshot_hash: Hash,
  causal_graph_snapshot_hash: Hash,
  prediction_residual_snapshot_hash: Hash,
  counterfactual_snapshot_hash: Hash,
  composition_snapshot_hash: Hash,
  epoch_config: EpochConfig
) -> {:ok, [KnowledgeGap.t()]} | {:error, GapDetectionFailure.t()}
```

Determinism contract: identical inputs → identical KnowledgeGap list (same IDs, same order).

---

### 2.2 ARPEQuestionGenerator

```
generate_questions(
  gap: KnowledgeGap.t(),
  epoch_config: EpochConfig
) -> {:ok, [ResearchQuestion.t()]} | {:error, QuestionGenerationFailure.t()}
```

Determinism contract: identical gap + config → identical question list.

---

### 2.3 ARPEPriorityScorer

```
score_questions(
  questions: [ResearchQuestion.t()],
  scoring_config: ScoringConfig
) -> {:ok, [ResearchPriority.t()]} | {:error, ScoringConfigMissing.t()}
```

Fail-closed contract: if ScoringConfig is absent or malformed, returns ScoringConfigMissing.
No default weight values exist in the implementation.

---

### 2.4 ARPEProgramPlanner

```
plan_program(
  question: ResearchQuestion.t(),
  budget_constraints: BudgetConstraints.t(),
  epoch_config: EpochConfig
) -> {:ok, ResearchProgram.t()} | {:error, PlanningFailure.t()}
```

Determinism contract: identical inputs → identical ResearchProgram artifact.

---

### 2.5 ARPEExperimentPlanner

```
design_experiment(
  program: ResearchProgram.t(),
  epoch_config: EpochConfig
) -> {:ok, {ResearchExperiment.t(), SimulationScenarioBinding.t()}} | {:error, ExperimentDesignFailure.t()}
```

Fail-closed contract: ambiguous evidence mapping → ExperimentDesignFailure, not partial output.

---

### 2.6 ARPEMathVerifier

```
verify(
  experiment: ResearchExperiment.t(),
  binding: SimulationScenarioBinding.t(),
  substrate: MathSubstrateBehaviour.t()
) -> {:ok, MathematicalVerificationResult.t()}
```

Always returns {:ok, result}. VERIFICATION_FAILED status is expressed inside the
result artifact, not as an error tuple, so calling modules always receive a result
to archive. Substrate is injected via the MathSubstrateBehaviour contract.

---

### 2.7 ARPEPortfolioManager

```
select_portfolio(
  programs: [ResearchProgram.t()],
  experiments: [ResearchExperiment.t()],
  portfolio_config: PortfolioConfig,
  current_state: PortfolioState.t()
) -> {:ok, ExperimentPortfolio.t()} | {:error, PortfolioSelectionFailure.t()}
```

Determinism contract: identical inputs → identical ExperimentPortfolio.
Fail-closed: if diversity threshold cannot be met, returns PortfolioSelectionFailure.

---

### 2.8 ARPEBudgetAllocator

```
allocate(
  portfolio: ExperimentPortfolio.t(),
  available_resources: ResourceState.t(),
  allocation_config: AllocationConfig
) -> {:ok, ExperimentBudget.t()} | {:error, BudgetAllocationFailure.t()}
```

Single ownership contract: no other module calls allocate/2 or modifies budget state.

---

### 2.9 ARPEScheduler

```
schedule(
  portfolio: ExperimentPortfolio.t(),
  budget: ExperimentBudget.t(),
  dependency_graph: DependencyGraph.t(),
  schedule_config: ScheduleConfig
) -> {:ok, ExperimentSchedule.t()} | {:error, SchedulingFailure.t()}
```

Determinism contract: identical inputs → identical ExperimentSchedule.

```
dispatch(
  intent: DispatchIntent.t(),
  twin_engine: DigitalTwinEngineBehaviour.t()
) -> {:ok, SimulationOutcome.t()} | {:error, DispatchFailure.t()}
```

---

### 2.10 ARPEEvidenceCollector

```
normalize(
  outcome: SimulationOutcome.t(),
  experiment: ResearchExperiment.t(),
  normalization_config: NormalizationConfig
) -> {:ok, ResearchEvidence.t()} | {:error, EvidenceMappingFailure.t()}
```

Fail-closed: missing observable → EvidenceMappingFailure, not partial evidence bundle.

---

### 2.11 ARPEStatisticalEngine

```
validate(
  evidence: ResearchEvidence.t(),
  statistical_requirements: StatisticalRequirements.t(),
  validation_config: ValidationConfig
) -> {:ok, ResearchStatisticalValidation.t()} | {:error, StatisticalValidationFailure.t()}
```

Determinism contract: identical inputs → identical ResearchStatisticalValidation.

---

### 2.12 ARPETheoryEvolver

```
evolve(
  validation: ResearchStatisticalValidation.t(),
  theory_snapshot: TheorySnapshot.t(),
  evolution_config: TheoryEvolutionConfig
) -> {:ok, [ResearchTheoryUpdateProposal.t()]} | {:error, TheoryEvolutionFailure.t()}
```

Determinism contract: identical inputs → identical proposal list.
Operation priority ordering is frozen in TheoryEvolutionConfig.

---

### 2.13 ARPEReplayEngine

```
replay_program(
  program_id: ProgramId.t(),
  artifact_store: ArtifactStore.t(),
  replay_config: ReplayConfig
) -> {:ok, ProgramReplayFingerprint.t()} | {:error, ReplayDivergenceReport.t()}
```

Fail-closed: divergence → ReplayDivergenceReport (not {:ok, fingerprint}).

---

### 2.14 ARPEArchaeologyRegistry

```
register(record: ProgramArchaeologyRecord.t()) -> :ok | {:error, RegistryError.t()}

explain(program_id: ProgramId.t()) -> {:ok, ProgramArchaeologyRecord.t()} | {:error, :not_found}
```

Registry contract: explain/1 is always available for any registered program_id.
No program is archived without a corresponding registry entry.

---

### 2.15 ConstitutionalCertificateAuthority

```
certify(
  program_id: ProgramId.t(),
  artifact_set: CertificationArtifactSet.t()
) -> {:ok, ARPECertificate.t()} | {:error, CertificationGateFail.t()}
```

Independence contract: this module must not import any ARPERuntime module.
It consumes only immutable artifact references.

---

## 3. Frozen Behaviors (Elixir Behaviour Contracts)

### ResearchProgramBehaviour
```elixir
@callback plan(ResearchQuestion.t(), BudgetConstraints.t(), EpochConfig.t()) ::
  {:ok, ResearchProgram.t()} | {:error, PlanningFailure.t()}
```

### ExperimentBehaviour
```elixir
@callback design(ResearchProgram.t(), EpochConfig.t()) ::
  {:ok, {ResearchExperiment.t(), SimulationScenarioBinding.t()}} |
  {:error, ExperimentDesignFailure.t()}
```

### MathSubstrateBehaviour
```elixir
@callback verify_experiment(ResearchExperiment.t(), SimulationScenarioBinding.t()) ::
  {:ok, MathematicalVerificationResult.t()}
```

### SchedulingBehaviour
```elixir
@callback schedule(ExperimentPortfolio.t(), ExperimentBudget.t(), DependencyGraph.t(), ScheduleConfig.t()) ::
  {:ok, ExperimentSchedule.t()} | {:error, SchedulingFailure.t()}
```

### ReplayBehaviour
```elixir
@callback replay_program(ProgramId.t(), ArtifactStore.t(), ReplayConfig.t()) ::
  {:ok, ProgramReplayFingerprint.t()} | {:error, ReplayDivergenceReport.t()}
```

### ArchaeologyBehaviour
```elixir
@callback register(ProgramArchaeologyRecord.t()) :: :ok | {:error, RegistryError.t()}
@callback explain(ProgramId.t()) :: {:ok, ProgramArchaeologyRecord.t()} | {:error, :not_found}
```

### CertificateBehaviour
```elixir
@callback certify(ProgramId.t(), CertificationArtifactSet.t()) ::
  {:ok, ARPECertificate.t()} | {:error, CertificationGateFail.t()}
```

---

## 4. Frozen Replay Contracts

All replay-critical artifacts for Phase 17.8 (see ARPE_REPLAY_MODEL.md Section 1):

- KnowledgeGap (with phase_17_8_ext) — LEVEL1 minimum
- SimulationScenarioBinding — LEVEL1 + LEVEL3
- MathematicalVerificationResult — LEVEL1
- ExperimentPortfolio — LEVEL1 + LEVEL3
- ExperimentBudget — LEVEL1
- ExperimentSchedule — LEVEL1 + LEVEL3
- SimulationOutcome fingerprint — LEVEL1
- ResearchEvidence (with phase_17_8_ext) — LEVEL1
- ProgramReplayFingerprint — LEVEL1

Replay level definitions are frozen in ARPE_REPLAY_MODEL.md and must not be changed
without a new epoch version.

---

## 5. Frozen Archaeology Contracts

Every entity registered in ARPEArchaeologyRegistry must provide Explain() responses
covering all fields defined in AUTONOMOUS_RESEARCH_PROGRAM_ARCHITECTURE.md Section 10.

Completeness requirement: explanation_completeness field in ProgramArchaeologyRecord
must be COMPLETE before a program advances to constitutional archive.

---

## 6. Frozen Ownership Contracts

Ownership as defined in AUTONOMOUS_RESEARCH_PROGRAM_ARCHITECTURE.md Section 4
is constitutionally frozen. No entity may change owner within this epoch.

Cross-ownership violations are constitutional violations and produce
CrossOwnershipViolationRecord artifacts.

---

## 7. Frozen Determinism Contracts

- No hardcoded numeric weights, thresholds, or algorithm parameters in implementation
- All configurable values read from epoch-frozen EpochConfig, ScoringConfig,
  PortfolioConfig, AllocationConfig, ScheduleConfig, or TheoryEvolutionConfig artifacts
- Config artifacts are content-addressed; their hashes are recorded in every output
  artifact that depends on them
- If a required config artifact is absent, the relevant API returns a fail-closed error
- No wall-clock dependency in any deterministic pipeline stage
- No network calls during deterministic pipeline derivation
- All randomness (if any) is derived from content-addressed seeds

---

## 8. Configuration Contract (No Hardcoding)

The following configuration artifacts must exist and be content-addressed before
the Phase 17.8 runtime may execute any pipeline stage:

| Config Artifact | Used By | Must Contain |
|---|---|---|
| EpochConfig | All stages | epoch_id, algorithm versions, hash |
| ScoringConfig | ARPEPriorityScorer | all scoring weights (no defaults) |
| PortfolioConfig | ARPEPortfolioManager | diversity threshold, optimization objectives |
| AllocationConfig | ARPEBudgetAllocator | allocation algorithm version, rules |
| ScheduleConfig | ARPEScheduler | scheduling rules, parallelism limits |
| NormalizationConfig | ARPEEvidenceCollector | normalization transform specs |
| ValidationConfig | ARPEStatisticalEngine | validation type list, replay requirements |
| TheoryEvolutionConfig | ARPETheoryEvolver | operation thresholds, priority ordering |
| ReplayConfig | ARPEReplayEngine | required replay levels per stage |

If any of these config artifacts is missing or its hash cannot be verified,
the runtime fails closed and produces a ConfigurationMissingRecord — it does not
fall back to hardcoded values under any circumstances.

### 8.1 Phase 17.8+ Proof Contract

From Phase 17.8 onward, completion evidence must be generated by Tiannara's real
constitutional execution path.

Forbidden in runtime, validation, audit, certification, and final-report paths:

- hardcoded domain measurements, thresholds, weights, budgets, schedules, or theory rules
- stubbed executors, verifiers, replay engines, auditors, certificate generators, or archaeology providers
- mock data promoted to evidence, replay roots, ledgers, validation results, audit results, certificates, or completion claims
- default fallback values that permit execution when required config, evidence, or upstream artifacts are absent

Permitted test fixtures must remain test-scoped and must never be referenced by
ARPECertificate, AUTONOMOUS_RESEARCH_PROOF.json, validation campaign evidence,
independent audit evidence, replay fingerprints, or final certification deliverables.

If a real upstream artifact is unavailable, the subsystem must emit the relevant named
failure artifact and stop advancement. The subsystem must not synthesize evidence to
continue.

---

## 9. Constitutional Error Semantics (Frozen)

All failure classes produce named artifact types. No failure produces a silent
continuation or an unstructured exception propagation.

| Failure Class | Artifact Type |
|---|---|
| Gap detection anomaly | KnowledgeGapAnomaly |
| Scoring config absent | ScoringConfigMissing |
| Evidence mapping ambiguity | EvidenceMappingFailure |
| Experiment design failure | ExperimentDesignFailure |
| Math verification failure | MathVerificationFailure (within MathematicalVerificationResult) |
| Portfolio selection failure | PortfolioSelectionFailure |
| Budget allocation failure | BudgetAllocationFailure |
| Scheduling failure | SchedulingFailure |
| Dispatch failure | DispatchFailure |
| Statistical validation failure | StatisticalValidationFailure |
| Theory evolution failure | TheoryEvolutionFailure |
| Replay divergence | ReplayDivergenceReport |
| Archaeological incompleteness | ArchaeologyGateFail |
| Certification gate failure | CertificationGateFail |
| Cross-ownership violation | CrossOwnershipViolationRecord |
| Configuration missing | ConfigurationMissingRecord |
| Digital Twin fingerprint mismatch | DigitalTwinFingerprintMismatch |

---

## 10. Freeze Audit Results

### Public Interface Audit
PASS — All 15 API surfaces are defined with complete signatures and behavior contracts.
No API has an implicit parameter, default value, or undocumented side effect.

### Ownership Verification
PASS — All frozen API ownership matches the CAR ownership map exactly.
ConstitutionalCertificateAuthority is verified independent of runtime modules.

### Freeze Consistency Audit
PASS — All schemas, APIs, behaviors, replay contracts, and archaeology contracts
are internally consistent. No contract references an unfrozen entity.

### Boundary Verification
PASS — No Phase 17.8 frozen contract imports, modifies, or re-declares any
Phase 16, Phase 16.X, or Phase 17.7 contract.

### Contract Completeness Audit
PASS — Every entity from the CAR ownership map appears in exactly one frozen
API or behavior contract. No entity is uncontracted.

### No Hardcoded Values Audit
PASS — No numeric weight, threshold, or configuration value appears in any
frozen contract definition. All configurable values reference named config artifacts.

---

## 11. Freeze Decision

**PHASE 17.8 CONTRACTS: FROZEN**

Effective from this document's creation.

No contract may change without a new epoch version.

Phase 17.8.1 (Ontology) may now proceed.

---

## Dependency Graph

```
AUTONOMOUS_RESEARCH_PROGRAM_ARCHITECTURE (17.8.0 CAR)
    │
    ▼
RESEARCH_EXECUTION_PIPELINE (17.8.0 CAR)
    │
    ▼
RESEARCH_PROGRAM_DATA_MODEL (17.8.0 CAR)
    │
    ▼
ARPE_REPLAY_MODEL (17.8.0 CAR)
    │
    ▼
ARPE_CERTIFICATION (17.8.0 CAR)
    │
    ▼
AUTONOMOUS_RESEARCH_RUNTIME_FREEZE (this document — 17.8.05)
    │
    ▼
AUTONOMOUS_RESEARCH_SCHEMA_REPORT (17.8.1 — next)
```
