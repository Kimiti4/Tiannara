# Phase 19 — Civilizational Data Model

## Struct Definitions

### S1: Civilization

| Field | Type | Description |
|-------|------|-------------|
| civilization_id | CivilizationId | Unique identifier |
| genesis_time | Timestamp | Time of civilization genesis |
| institution_ids | [InstitutionId] | Registered institutions |
| status | CivilizationStatus | Active, Frozen, Archived |
| constitution_hash | Hash | Constitution artifact hash |
| metrics | CivilizationMetrics | Aggregate metrics |

**Invariants:**
- `civilization_id` must be globally unique.
- `status` transitions: Active → Frozen → Archived (no reversal).
- At least one institution must be registered before `status` can leave `Genesis`.

### S2: Institution

| Field | Type | Description |
|-------|------|-------------|
| institution_id | InstitutionId | Unique identifier |
| charter_hash | Hash | Constitutional charter artifact |
| institute_type | InstituteType | Physics, Mathematics, Robotics, Medicine, Engineering |
| program_ids | [ResearchProgramId] | Hosted research programs |
| scientist_ids | [ScientistId] | Registered scientists |
| capital_balance | Capital | Allocated economic capital |
| status | InstitutionStatus | Chartering, Active, Suspended, Dissolved |

**Invariants:**
- `institute_type` is immutable after registration.
- `capital_balance` ≥ 0.
- `status` cannot transition from Dissolved to any other state.

### S3: ResearchProgram

| Field | Type | Description |
|-------|------|-------------|
| program_id | ResearchProgramId | Unique identifier |
| institution_id | InstitutionId | Owning institution |
| domain | ResearchDomain | Scientific domain |
| novelty_score | Score | Novelty metric (0–1) |
| uncertainty_score | Score | Uncertainty metric (0–1) |
| maturity_score | Score | Maturity metric (0–1) |
| productivity_score | Score | Productivity metric (0–1) |
| dependency_ids | [ResearchProgramId] | Dependency programs |
| impact_score | Score | Projected impact (0–1) |
| status | ProgramStatus | Proposed, Active, Completed, Failed, Archived |

**Invariants:**
- `novelty_score + uncertainty_score + maturity_score + productivity_score` ≤ 1.0.
- Circular dependencies (`dependency_ids`) are forbidden.
- `status` transitions must follow: Proposed → Active → Completed | Failed → Archived.

### S4: ResearchPortfolio

| Field | Type | Description |
|-------|------|-------------|
| portfolio_id | PortfolioId | Unique identifier |
| program_allocations | {ResearchProgramId → Allocation} | Program capital allocations |
| governance_log | [GovernanceAction] | Ordered governance actions |
| portfolio_version | Version | Monotonic version counter |

**Invariants:**
- Sum of `program_allocations` ≤ total civilizational capital.
- `governance_log` must be append-only.
- `portfolio_version` increments by exactly 1 per action.

### S5: Collaboration

| Field | Type | Description |
|-------|------|-------------|
| collaboration_id | CollaborationId | Unique identifier |
| program_ids | [ResearchProgramId] | Participating programs |
| discovery_graph | Graph | Cross-domain discovery edges |
| formation_time | Timestamp | Time of formation |
| collaboration_hash | Hash | Deterministic hash of graph |

**Invariants:**
- At least 2 distinct programs must participate.
- `collaboration_hash` must equal `hash(program_ids, discovery_graph)`.
- No duplicate edges in `discovery_graph`.

### S6: ScientificEconomy

| Field | Type | Description |
|-------|------|-------------|
| economy_id | EconomyId | Unique identifier |
| capital_ledger | {InstitutionId → Capital} | Institutional capital balances |
| reward_history | [RewardEvent] | Historical reward disbursements |
| total_capital | Capital | Total civilizational capital |
| settlement_version | Version | Economy settlement version |

**Invariants:**
- `total_capital` = sum of all `capital_ledger` values.
- `settlement_version` increments monotonically.
- Reward events must reference a certified ResearchProgramId.

### S7: CivilizationEvidence

| Field | Type | Description |
|-------|------|-------------|
| evidence_id | EvidenceId | Unique identifier |
| origin | PipelineTransition | Originating pipeline transition |
| payload | Binary | Evidence payload |
| producer_hash | Hash | Hash of producing component |
| timestamp | Timestamp | Time of evidence creation |

**Invariants:**
- `evidence_id` must be globally unique across all evidence.
- `producer_hash` must match the certified component hash.

### S8: CivilizationReplay

| Field | Type | Description |
|-------|------|-------------|
| replay_id | ReplayId | Unique identifier |
| root | CivilizationRoot | Replay root artifact |
| subsystem_roots | {Subsystem → ArtifactRoot} | Per-subsystem roots |
| replay_log | [ReplayEvent] | Deterministic event log |
| final_state_hash | Hash | Hash of final reconstructed state |

**Invariants:**
- `final_state_hash` must equal `hash(replay_log, root)`.
- `subsystem_roots` must contain all active subsystems.

### S9: CivilizationArchaeology

| Field | Type | Description |
|-------|------|-------------|
| archaeology_id | ArchaeologyId | Unique identifier |
| civilization_id | CivilizationId | Source civilization |
| excavated_artifacts | [Artifact] | Excavated artifacts |
| reconstruction_confidence | Score | Reconstruction confidence (0–1) |
| archaeology_depth | Depth | Excavation depth level |

**Invariants:**
- `archaeology_id` must be unique per `civilization_id`.
- `reconstruction_confidence` ∈ [0, 1].
- Each artifact must have verifiable provenance.

### S10: CivilizationMetrics

| Field | Type | Description |
|-------|------|-------------|
| metrics_id | MetricsId | Unique identifier |
| total_programs | Count | Active research programs |
| total_collaborations | Count | Active collaborations |
| total_discoveries | Count | Total discoveries |
| total_capital | Capital | Total economic capital |
| novelty_reserve | Score | Aggregate novelty score |
| maturity_index | Score | Aggregate maturity index |
| civilization_age | Duration | Civilization runtime age |
