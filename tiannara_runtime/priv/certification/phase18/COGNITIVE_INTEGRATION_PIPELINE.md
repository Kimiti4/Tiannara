# Phase 18.9 — Cognitive Integration Pipeline

## Pipeline Stages

### 1. Mission Creation
- **Inputs:** Raw mission objective, constraints, authorization tokens
- **Outputs:** Validated CognitiveMission
- **Owner:** Kernel 18.2
- **Evidence:** Mission validation receipt, raw objective hash
- **Replay:** Kernel replay root with mission_id
- **Archaeology:** Mission creation timestamp and origin context

### 2. Working Memory Load
- **Inputs:** CognitiveMission, session history, long-term memory indices
- **Outputs:** Loaded CognitiveContext with working_memory populated
- **Owner:** Working Memory 18.3
- **Evidence:** Memory load summary, recall chain, context snapshot
- **Replay:** WM replay root with load operations
- **Archaeology:** Memory provenance and relevance scores

### 3. Attention Focus
- **Inputs:** CognitiveContext (working_memory)
- **Outputs:** Attended CognitiveContext (salience-weighted)
- **Owner:** Attention 18.4
- **Evidence:** Attention weights, focus map, discarded inputs
- **Replay:** Attention replay root with salience vector
- **Archaeology:** Attention allocation narrative

### 4. Plan Generation
- **Inputs:** Attended CognitiveContext, plan templates, constraints
- **Outputs:** Plan alternatives, selected plan
- **Owner:** Planning 18.5
- **Evidence:** Plan candidates, selection criteria, plan graph
- **Replay:** Planning replay root with plan tree
- **Archaeology:** Planning rationale and trade-off analysis

### 5. Decision Making
- **Inputs:** Selected plan, risk assessment, utility model
- **Outputs:** Authorized Decision, execution directives
- **Owner:** Decision 18.6
- **Evidence:** Decision receipt, authorization chain, risk score
- **Replay:** Decision replay root with authorization trail
- **Archaeology:** Decision justification, alternatives dismissed

### 6. Authorization (Runtime Gate)
- **Inputs:** Decision, constitutional constraints, safety bounds
- **Outputs:** Signed execution permit or rejection
- **Owner:** Runtime (Constitutional Gate)
- **Evidence:** Permit (or rejection), constraint satisfaction proof
- **Replay:** Gate replay artifact
- **Archaeology:** Gate decision context

### 7. Evidence Collection
- **Inputs:** Execution permit, plan steps
- **Outputs:** Execution state, evidence chain per step
- **Owner:** Runtime (ExecutionCoordinator)
- **Evidence:** Step receipts, output hashes, failure records
- **Replay:** Execution replay root with step sequence
- **Archaeology:** Execution narrative with outcome markers

### 8. Reflection Session
- **Inputs:** Execution evidence chain, expected vs actual outcomes
- **Outputs:** Reflection assessment, deviation analysis
- **Owner:** Reflection 18.7
- **Evidence:** Deviation list, confidence scores, lessons identified
- **Replay:** Reflection replay root with assessment vectors
- **Archaeology:** Reflection narrative, corrective recommendations

### 9. Meta-Cognitive Assessment
- **Inputs:** Reflection assessment, full pipeline trace
- **Outputs:** Meta-assessment, performance metrics, calibration deltas
- **Owner:** Meta-Cognition 18.8
- **Evidence:** Meta-scores, calibration adjustments, anomaly flags
- **Replay:** Meta-cognition replay root with calibration trace
- **Archaeology:** Meta-cognitive narrative, system health summary

### 10. Replay Recording
- **Inputs:** All subsystem replay roots
- **Outputs:** Complete RuntimeReplay (mission_root + 7 subsystem roots)
- **Owner:** Runtime (ReplayCoordinator)
- **Evidence:** Replay integrity hash, root linkage proof
- **Replay:** N/A (self-referential)
- **Archaeology:** Replay construction narrative

### 11. Archaeology Recording
- **Inputs:** RuntimeReplay, all evidence collections
- **Outputs:** Complete RuntimeArchaeology (mission narrative)
- **Owner:** Runtime (ArchaeologyCoordinator)
- **Evidence:** Archaeology integrity hash, narrative completeness proof
- **Replay:** Archaeology construction artifact
- **Archaeology:** N/A (self-referential)
