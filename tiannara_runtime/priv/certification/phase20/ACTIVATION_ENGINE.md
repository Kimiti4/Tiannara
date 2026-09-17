# Phase 20.4 — Activation Engine

## Role

The Activation Engine governs the staged rollout of an integrated candidate from isolation through full production deployment. Each activation stage has measurable promotion criteria. No stage may be skipped. Failure at any stage triggers deterministic rollback.

## Activation Stages

### Stage 1 — Shadow

The candidate is deployed in shadow mode — fully active but invisible to all subsystems.

- Candidate runs in parallel with existing system
- All inputs are duplicated to both existing and shadow systems
- Shadow outputs are recorded but never acted upon
- Shadow is fully instrumented for measurement
- No production workload depends on shadow output

**Promotion Criteria:**
- Shadow produces identical results to existing system for all test inputs
- Shadow replay hashes match predicted values
- Shadow resource consumption within budget
- No shadow-side errors or exceptions
- Performance metrics match simulation predictions within tolerance

**Duration:** Minimum N simulation steps with zero failures.

### Stage 2 — Limited Activation

The candidate handles a small, isolated subset of production workload.

- Candidate receives limited real workload (defined by traffic_percentage)
- Existing system continues handling majority of workload
- Both systems run in parallel for comparison
- All outputs are verified against existing system

**Promotion Criteria:**
- Limited results match existing system results for overlapping workload
- No determinism violations
- Resource consumption within predicted bounds
- No failure propagation from candidate to existing system
- Response quality metrics match or exceed existing system

**Duration:** Minimum N successful cycles with zero critical failures.

### Stage 3 — Progressive Rollout

The candidate's workload share increases gradually.

- Workload fraction increases in defined steps (e.g., 25%, 50%, 75%, 100%)
- Each step requires verification before proceeding
- Existing system remains active as fallback
- Continuous monitoring at each step

**Promotion Criteria:**
- At each step, metrics match or exceed previous stage
- No regression in any measured dimension
- Replay and archaeology chains remain continuous
- No constitutional violations detected
- Rollback plan verified functional at each step

**Duration:** Each step requires minimum N successful cycles.

### Stage 4 — Full Activation

The candidate handles 100% of production workload.

- Existing system fully replaced by candidate
- Existing system state preserved as rollback target
- Fallback remains available
- Full monitoring active

**Promotion Criteria:**
- All production metrics within constitutional tolerances
- Replay chains verified continuous
- Archaeology chains verified intact
- No constitutional violations detected after full workload
- Rollback verified functional from full activation state

**Duration:** Minimum N successful cycles with zero failures.

### Stage 5 — Freeze

The integration is permanently frozen as a RuntimeGeneration.

- Integration sealed as permanent runtime component
- All pipeline artifacts archived
- Archaeology record finalized
- Rollback still possible but requires constitutional amendment

**Promotion Criteria:**
- Full observation period completed without incident
- All artifacts present and verified
- Archaeology complete for all pipeline stages
- Final fingerprint matches predicted value
- Generation registry updated

**Duration:** Instant (point-in-time freeze).

## Promotion Criteria Determinism

All promotion decisions are deterministic:

- Same metrics → same promotion decision
- Promotion criteria are immutable for a given integration
- Promotion failure always triggers the same rollback procedure
- Promotion evidence is content-addressed and replayable

## Rollback During Activation

- Any stage failure triggers deterministic rollback to pre-activation state
- Rollback restores the previous production system
- Rollback produces complete evidence chain
- Rollback is archaeologically preserved
- Candidate may be re-deployed after issue resolution (re-enters at Stage 1)

## Activation Artifacts

Each activation stage produces:

- StageResult with metrics, promotion decision, evidence
- StageReplayEntry in the activation replay chain
- StageArchaeologyEntry in the activation archaeology record
- ActivationRecord aggregating all stage results

## Constraints

- No activation stage may be skipped
- Each stage promotion requires measurable evidence
- Rollback must be tested and verified at every stage
- Activation may be paused at any stage by constitutional authority
- Human governance may override activation decisions
- All activation artifacts are immutable and content-addressed
