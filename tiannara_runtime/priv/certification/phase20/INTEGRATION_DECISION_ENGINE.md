# Phase 20.9 — Integration Decision Engine

## Role

The Integration Decision Engine evaluates all evidence from prior pipeline stages and determines whether a proposed integration is ready for promotion to the next state. Decisions are deterministic — same evidence always produces identical decisions.

## Inputs

- IntegrationProposal
- CompatibilityReport (9 dimensions)
- MathematicalVerificationReport
- ReplayVerificationReport
- KnowledgePreservationReport
- Current runtime generation state
- Constitutional rules and constraints

## Outputs

- PromotionDecision with decision, promotion_state, conditions, timeline

## Decision Dimensions

### Evidence Completeness
Is the evidence necessary for a promotion decision complete?

| Check | Criteria |
|-------|----------|
| Proposal completeness | All required proposal fields present |
| Evidence chain continuity | Evidence chain has no gaps |
| Artifact availability | All pipeline stage artifacts present |
| Replay verification | All replay hashes verified |

### Compatibility Status
Are all compatibility dimensions satisfied?

| Dimension | Required Status |
|-----------|-----------------|
| Structural | Pass |
| Behavioral | Pass |
| Interface | Pass |
| Replay | Pass |
| Mathematical | Pass |
| Knowledge | Pass |
| Engineering | Pass |
| Scientific | Pass |
| Constitutional | Pass |

### Risk Assessment
Is the integration risk acceptable?

| Risk Factor | Acceptable Level |
|-------------|------------------|
| Technical risk | No critical or major risks |
| Integration risk | No critical or major risks |
| Performance risk | Acceptable with mitigation |
| Security risk | No unresolved risks |
| Constitutional risk | Zero tolerance |

### Readiness Assessment
Is the integration ready for promotion?

| Criterion | Assessment |
|-----------|------------|
| Sandbox readiness | All sandbox tests passed |
| Canary readiness | All canary metrics met |
| Production readiness | All production criteria satisfied |
| Rollback readiness | Rollback plan verified functional |

## Promotion States

| State | Description | Entry Criteria |
|-------|-------------|----------------|
| Candidate | Proposal received, initial review pending | Valid IntegrationProposal |
| Validated | All compatibility checks passed | 9/9 compatibility dimensions pass |
| Integration Ready | Ready for sandbox deployment | Mathematical, replay, knowledge verified |
| Sandbox | Deployed to sandbox runtime | Integration Ready + certification |
| Canary | Deployed to canary runtime | Sandbox passed |
| Production Candidate | Approved for production | Canary passed + constitutional review |
| Current Generation | Active production runtime | Production Candidate + freeze |
| Historical Generation | Superseded, cold storage | Replaced by newer Current Generation |

## Decision Determinism

- Same evidence always produces the same promotion decision
- Decision criteria are immutable for a given generation
- Tie-breaking uses deterministic ordering (proposal_id hash)
- All decision evidence is content-addressed and replayable
