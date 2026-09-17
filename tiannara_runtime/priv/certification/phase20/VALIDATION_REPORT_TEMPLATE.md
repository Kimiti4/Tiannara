# Validation Report Template (Phase 20.95)

## Campaign: [Campaign Label]
## Scenario: [Scenario ID]
## Subsystem: [Subsystem Name]

---

### 1. Campaign Metadata
- Campaign Label: [A/B/C/D/E/F/G/H]
- Campaign ID: Content-addressed identifier computed from the artifact contents
- Objective: [campaign objective]
- Subsystems Under Test: [list]
- Validation Gates: [list of gates checked]

### 2. Scenario Description
- Scenario ID: [identifier]
- Description: [what is being tested]
- Inputs: [description of deterministic inputs]
- Expected Outcome: [what should happen]
- Expected Hash: [SHA-256 of expected output]

### 3. Execution Results
- Total Scenarios Run: Total count
- Passed: Total count
- Failed: Total count
- Errors: Total count
- Skipped: Total count
- Overall Status: [Pass/Fail/ConditionalPass]

### 4. Detailed Results
| Scenario | Result | Observed Hash | Expected Hash | Match | Failure Category |
|----------|--------|--------------|--------------|-------|-----------------|
| [id] | Pass | 0x... | 0x... | Yes | — |
| [id] | Fail | 0x... | 0x... | No | Critical |

### 5. Metrics Summary
| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| Replay stability | 1.0 | 1.0 | ✓ |
| Determinism score | 1.0 | 1.0 | ✓ |
| [other metrics] | [value] | [target] | [status] |

### 6. Failures
| Failure ID | Category | Severity | Recoverable | Root Cause |
|-----------|----------|----------|-------------|------------|
| [id] | Minor | 2 | Yes | [description] |

### 7. Archaeology
- Replay Root: Content-addressed SHA-256 hash of the certified artifact
- Archaeology Root: Content-addressed SHA-256 hash of the certified artifact
- Artifacts Deposited: [count]
- Replay Verification: Verification outcome

### 8. Gates Passed
- [x] Structural
- [x] Behavioral
- [x] Deterministic
- [x] Replay
- [ ] Knowledge (N/A)
- [ ] Scientific (N/A)
- [ ] Mathematical (N/A)
- [x] Integration
- [ ] Long-duration (N/A)
- [ ] Adversarial (N/A)

### 9. Conclusion
[Campaign Label] [Passed/Failed/ConditionalPassed]. [Brief summary of results, notable failures, and overall assessment.]

### 10. Certification Readiness
- Campaign Certificate: [Issued/Pending/NotApplicable]
- Certificate ID: [if issued]
- Recommendation: [Proceed to certification / Remediation required]
