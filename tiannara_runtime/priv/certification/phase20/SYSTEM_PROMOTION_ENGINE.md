# Phase 20.9 — System Promotion Engine

## Role

The System Promotion Engine governs the deterministic promotion of integration proposals through progressive states — from Candidate through Current Generation. Each promotion requires specific evidence, verification, and constitutional authorization.

## Promotion States

```
Candidate
    ↓ (Integration Proposal + Initial Review)
Validated
    ↓ (9/9 Compatibility Pass)
Integration Ready
    ↓ (Constitutional Certification)
Sandbox
    ↓ (Sandbox Tests Pass)
Canary
    ↓ (Canary Metrics Meet Thresholds)
Production Candidate
    ↓ (Constitutional Review + Transition Plan)
Current Generation
    ↓ (Freeze + Archaeology)
Historical Generation
```

## State Transitions

### Candidate → Validated
- **Evidence required:** IntegrationProposal, initial compatibility assessment
- **Verification:** Proposal structure valid, scope defined, evidence chain complete
- **Authorization:** Integration Decision Engine

### Validated → Integration Ready
- **Evidence required:** CompatibilityReport (9/9 pass), MathematicalVerificationReport, ReplayVerificationReport, KnowledgePreservationReport
- **Verification:** All 9 dimensions pass, mathematical consistency confirmed, replay continuity verified, knowledge preservation confirmed
- **Authorization:** Constitutional Compatibility Engine + Integration Decision Engine

### Integration Ready → Sandbox
- **Evidence required:** Integration Certificate, sandbox deployment plan
- **Verification:** Certificate valid, deployment plan complete, rollback plan verified
- **Authorization:** Constitutional authority

### Sandbox → Canary
- **Evidence required:** SandboxRun (passed), sandbox metrics report
- **Verification:** All sandbox tests pass, metrics match predictions within tolerance, no compatibility violations
- **Authorization:** Integration Decision Engine

### Canary → Production Candidate
- **Evidence required:** CanaryRun (passed), canary metrics report, comparison with sandbox predictions
- **Verification:** All canary metrics meet thresholds, no behavioral deviations, rollback plan verified functional
- **Authorization:** Constitutional authority

### Production Candidate → Current Generation
- **Evidence required:** Generation transition plan, rollback plan, certification artifacts, archaeology records
- **Verification:** Transition plan complete, rollback verified, certification valid, archaeology complete
- **Authorization:** Constitutional authority + Independent audit

### Current Generation → Historical Generation
- **Trigger:** New generation promoted to Current
- **Process:** Archive generation to cold storage, verify full replay, seal archaeology
- **Verification:** Full replay verified from cold storage, all artifacts preserved
- **Authorization:** Automatic (constitutional requirement)

## Promotion Determinism

- Same evidence always produces the same promotion decision
- Promotion criteria are immutable for a given integration
- Promotion failures are recorded and preserved
- Promotions are fully replayable
