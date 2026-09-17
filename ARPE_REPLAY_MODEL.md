# Phase 17.8.0 — ARPE Replay Model (CAR)

document_version: 17.8.0
phase: 17.8
status: Architecture Review
owner: Constitutional Research Council
depends_on:
  - AUTONOMOUS_RESEARCH_PROGRAM_ARCHITECTURE.md
  - RESEARCH_EXECUTION_PIPELINE.md
  - RESEARCH_PROGRAM_DATA_MODEL.md
  - RESEARCH_REPLAY_MODEL.md (Phase 16.2 — extended, not replaced)
  - digital_twin/engines/digital_twin_engine.ex (Phase 17.7.9)
supersedes: null

---

## Purpose

This document defines the Phase 17.8 replay model for the ARPE subsystem.

It extends the Phase 16.2 replay model with the additional replay scope introduced
by the Digital Twin execution bridge, portfolio management, and theory evolution.

This is a constitutional architecture document. No implementation is introduced here.

---

## Inheritance from Phase 16.2

The Phase 16.2 replay model defines:
- Three replay levels (LEVEL1 hash equality, LEVEL2 semantic equality, LEVEL3 structural)
- Canonical serialization contract
- Tie-breaking rules
- Replay output types: ReplayVerificationResult, ReplayMerkleRootProof, ReplayDivergenceReport
- Divergence handling (fail-closed)
- Archaeological reconstruction contract

All Phase 16.2 replay rules apply to Phase 17.8 without modification.

Phase 17.8 extends the replay scope to cover new ARPE-specific stages and artifacts.

---

## 1. New Replay Scope (Phase 17.8 Additions)

The following stages and artifacts are Phase 17.8-specific and must be added to the
replay scope:

| Stage | Artifact | Minimum Replay Level |
|---|---|---|
| Stage 0 — WORLD_MODEL_GAP_SCAN | KnowledgeGap (with phase_17_8_ext) | LEVEL1 |
| Stage 3 — PROGRAM_PLANNING | SimulationScenarioBinding template | LEVEL1 + LEVEL3 |
| Stage 4 — EXPERIMENT_DESIGN | SimulationScenarioBinding (final) | LEVEL1 + LEVEL3 |
| Stage 5 — MATHEMATICAL_VERIFICATION | MathematicalVerificationResult | LEVEL1 |
| Stage 6 — PORTFOLIO_SELECTION | ExperimentPortfolio | LEVEL1 + LEVEL3 |
| Stage 7 — BUDGET_ALLOCATION | ExperimentBudget | LEVEL1 |
| Stage 8 — SCHEDULING | ExperimentSchedule | LEVEL1 + LEVEL3 |
| Stage 9 — DIGITAL_TWIN_EXECUTION | SimulationOutcome fingerprint | LEVEL1 |
| Stage 10 — EVIDENCE_COLLECTION | ResearchEvidence (with phase_17_8_ext) | LEVEL1 |
| Stage 12 — THEORY_EVOLUTION | ResearchTheoryUpdateProposal | LEVEL1 (Phase 16.2) |
| Stage 13 — REPLAY_CERTIFICATION | ProgramReplayFingerprint | LEVEL1 |
| Stage 14 — CONSTITUTIONAL_ARCHIVE | ProgramArchaeologyRecord | LEVEL1 |

LEVEL3 (full pipeline structural replay) is required for any stage that produces
outputs which influence the portfolio selection, scheduling, or theory evolution
decisions.

---

## 2. Digital Twin Execution Replay

The Digital Twin execution (Stage 9) has a special replay rule.

The Digital Twin's `DigitalTwinEngine.run_simulation/2` is deterministic when given:
- identical initial_conditions
- identical events list (same events in same order)
- identical interventions list
- identical total_ticks
- identical simulation seed (derived from SimulationScenarioBinding.deterministic_seed)

ARPE replay does NOT re-execute the Digital Twin simulation to verify replay.

Instead, ARPE replay verifies:
1. The SimulationScenarioBinding artifact is identical (LEVEL1 hash check)
2. The SimulationOutcome.simulation_fingerprint matches the expected fingerprint
   (computed from: initial_state_hash + events_hash + seed → deterministic fingerprint)

The SimulationOutcome itself is treated as an immutable artifact once produced.
ARPE's replay responsibility is to verify that the scenario that produced it matches
the one registered in the experiment design.

If the SimulationOutcome fingerprint cannot be verified:
- Replay emits a DigitalTwinFingerprintMismatch artifact
- Pipeline fails closed
- The outcome is not used for evidence collection

---

## 3. Portfolio Selection Replay

Portfolio selection (Stage 6) must be LEVEL3 replayable.

Replay must reconstruct the portfolio selection from:
- The exact set of ResearchProgram and ResearchExperiment artifacts at selection time
- The frozen portfolio optimization config (weights, diversity threshold, constraints)
- The current EpochState (resource budget, portfolio history)

All of these must be captured as immutable artifacts at selection time.

Replay verifies:
1. The optimization input set is identical (LEVEL1 hash check)
2. The selected portfolio is identical given identical inputs (LEVEL1 hash check)
3. The optimization path (intermediate scoring) can be reconstructed (LEVEL3)

Tie-breaking in portfolio selection uses:
- Lexicographic ordering over program_id (blake3 hash)
- This is identical to the Phase 16.2 tie-breaking rule, applied to programs

---

## 4. Theory Evolution Replay

Theory evolution (Stage 12) must be LEVEL1 replayable at minimum.

Given:
- Identical ResearchStatisticalValidation artifacts (content-addressed)
- Identical theory graph snapshot hash at the time of evolution
- Frozen theory evolution config (operation thresholds, merge/split criteria)

The same ResearchTheoryUpdateProposal must be produced with the same proposal_id.

Theory operation tie-breaking:
- When multiple operations are triggered simultaneously, operations are ordered by:
  - operation priority (REJECT > CONTRADICT > MERGE > SPLIT > SUPERSEDE > REVISE > STRENGTHEN > WEAKEN)
  - within the same priority: lexicographic over target_theory_id hash

---

## 5. Evidence Normalization Replay

Evidence collection (Stage 10) must be LEVEL1 replayable.

Given:
- Identical SimulationOutcome (verified via fingerprint)
- Identical SimulationScenarioBinding (specifically: evidence_observable_mappings)
- Frozen normalization rules (normalization_transform strings)

The same ResearchEvidence bundles must be produced with identical content-addressed IDs.

If any normalization_transform is non-deterministic for a given input (e.g., relies on
external state or floating-point rounding that differs across environments):
- The transform must be replaced with a canonical deterministic version before freeze
- This is an architecture-level constraint, not a runtime concern

---

## 6. Replay Artifacts

Phase 17.8 replay produces the following artifacts:

### ProgramReplayFingerprint
(Defined in RESEARCH_PROGRAM_DATA_MODEL.md)

Captures:
- program_id
- replay_levels_achieved
- merkle_root (over all replayed artifact IDs)
- artifact_ids_replayed
- divergence_report_id (if any divergence)
- replay_algorithm_version
- replay_config_hash

### ReplayDivergenceReport (extended)

Phase 16.2 divergence reports are extended with Phase 17.8-specific stage identifiers:

```json
{
  "divergence_report_id": "blake3_hash",
  "schema_version": "17.8.0",
  "program_id": "blake3_hash",
  "diverging_stage": "STAGE_0_GAP_SCAN|STAGE_4_EXPERIMENT_DESIGN|STAGE_6_PORTFOLIO|STAGE_8_SCHEDULE|STAGE_9_TWIN_FINGERPRINT|STAGE_10_EVIDENCE|STAGE_12_THEORY|...",
  "input_hash_set": ["blake3_hash"],
  "expected_output_hash": "blake3_hash",
  "actual_output_hash": "blake3_hash",
  "earliest_divergence_artifact_id": "blake3_hash",
  "explanation": "string"
}
```

---

## 7. Independent Evidence-Only Replay

The independent evidence-only auditor (Phase 17.8.96) must be able to:

1. Verify KnowledgeGap provenance from World Model snapshot hashes (without re-running
   the World Model — the snapshot hash is the immutable anchor)
2. Verify SimulationScenarioBinding from experiment design artifacts
3. Verify portfolio selection from program artifacts + frozen config
4. Verify evidence normalization from outcome fingerprint + normalization rules
5. Verify statistical validation determinism
6. Verify theory evolution proposals from validation artifacts + theory snapshot hash
7. Verify replay fingerprint Merkle root

The auditor must NOT:
- Import the ARPE runtime
- Re-execute Digital Twin simulations
- Access mutable database state
- Access live World Model state

Everything the auditor needs must be captured in immutable artifacts at pipeline time.

---

## 8. Replay Boundary for Digital Twin

The Digital Twin engine itself (Phase 17.7) has its own replay model.

The boundary is:
- Phase 17.7's replay model governs: simulation determinism, state reconstruction,
  simulation archaeology, mathematical invariant verification during simulation.
- Phase 17.8's replay model governs: ARPE's use of simulation outputs, scenario
  construction determinism, evidence collection determinism, and the research program
  lifecycle artifacts.

The two replay models are independent but interoperable via the SimulationOutcome
fingerprint as the shared immutable anchor.

There is no shared replay engine. ARPE has its own ARPEReplayEngine. The Digital Twin
has its own replay. Neither imports the other's replay internals.

---

## 9. Long-Horizon Replay

Phase 17.8 must support replay at scale:
- Point-in-time replay: replay the program state at any historical epoch
- Partial replay: replay a single experiment within a program without replaying all others
- Full replay: replay a complete research program from initial gap to final outcome
- Verification replay: replay specifically to produce a ProgramReplayFingerprint
  for certification

The archaeology registry must retain sufficient immutable artifact references
to support all four replay modes indefinitely.

Artifact pruning is forbidden — every artifact produced by the ARPE pipeline
must remain available for replay, stored in the content-addressable store.

---

## 10. Failure Mode: Irreproducible Digital Twin Output

If a SimulationOutcome fingerprint cannot be reproduced, the correct response is:

1. Emit DigitalTwinFingerprintMismatch artifact
2. Mark the experiment as REPLAY_FAILED
3. Do not proceed with evidence collection for this experiment
4. If this experiment is critical to the program's stopping criteria, trigger
   an adaptive rescheduling decision (which is itself a deterministic operation
   logged as an InterruptionRecord)
5. Archive the failure artifact in the program's archaeology record

This is the only case where a pipeline stage fails and the program continues —
because the program itself can detect the failure, log it, and adapt its schedule.
The adaptation is constitutional (deterministic, logged, replayable).

---

## 11. CAR Compliance

Replay model satisfies all Phase 17.8.0 CAR requirements:

- Extends Phase 16.2 without replacing it
- Defines replay scope for all new Phase 17.8 artifacts
- Separates ARPE replay from Digital Twin replay with a clean boundary
- Defines failure semantics (fail-closed) for all replay cases
- Supports independent evidence-only replay without runtime imports
- Supports all four replay modes (full, partial, point-in-time, verification)
- Defines Merkle root structure for ProgramReplayFingerprint
- No implementation introduced
