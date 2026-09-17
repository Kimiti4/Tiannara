# Governance Proof Constitution

**Version**: 14.0.965  
**Date**: June 13, 2026  
**Type**: Constitutional Specification  
**Status**: ✅ **FROZEN**  

---

## Preamble

This document defines **what constitutes proof** in the Tiannara governance system.

It is to Phase 14 what `CAUSAL_FLOW.md` was to Phase 13: the foundational ontology that all subsequent machinery must respect.

**Core Principle**: Proof is not assertion. Proof is independently verifiable evidence supported by cryptographic guarantees and statistical confidence.

---

## 1. Proof Ontology

### 1.1 What is a Proof?

A **Proof** is a structured object that makes a claim about the governance system and provides:

1. **Inputs**: The data or conditions under which the claim was tested
2. **Measurements**: Quantitative results from executing the test
3. **Confidence**: Statistical confidence level (0.0 to 1.0)
4. **Statistical Power**: Ability to detect true effects (0.0 to 1.0)
5. **Failure Modes**: Known ways the proof could be invalid
6. **Supporting Evidence**: Content-addressed artifacts backing the claim
7. **Certificate**: Cryptographic signature binding proof to evidence
8. **Signature**: SHA-256 hash ensuring proof integrity

### 1.2 Proof Object Schema

All proof objects follow this frozen schema:

```elixir
%{
  # Identification
  proof_id: String.t(),              # Unique identifier (e.g., "GC-001-REPLAY-PROOF-001")
  proof_type: atom(),                # :replay, :authority, :capability, etc.
  version: String.t(),               # Proof schema version
  
  # Claim
  claim: String.t(),                 # What is being proven (e.g., "Replay determinism verified")
  claim_type: atom(),                # :determinism, :authority_enforcement, :conservation, etc.
  
  # Inputs
  inputs: map(),                     # Test parameters, random seeds, sample sizes
  
  # Measurements
  measurements: map(),               # Quantitative results
  metrics: %{                        # Standardized metrics
    sample_size: integer(),
    success_rate: float(),           # 0.0 to 1.0
    failure_count: integer(),
    duration_ms: integer()
  },
  
  # Confidence Model
  confidence: float(),               # Overall confidence (0.0 to 1.0)
  confidence_breakdown: %{           # How confidence was computed
    replay_confidence: float(),
    statistical_power: float(),
    fuzz_coverage: float(),
    archaeology_completeness: float(),
    drift_detection_sensitivity: float(),
    entropy_stability_score: float()
  },
  statistical_power: float(),        # Power to detect true effects (0.0 to 1.0)
  significance_level: float(),       # Alpha level (typically 0.05 or 0.01)
  
  # Failure Analysis
  failure_modes: [map()],            # Known failure modes and their probabilities
  assumptions: [String.t()],         # Assumptions underlying the proof
  
  # Evidence Chain
  supporting_evidence: [String.t()], # List of content-addressed evidence hashes
  evidence_manifest: String.t(),     # Hash of manifest linking all evidence
  
  # Certification
  certificate: map(),                # Signed certificate binding proof to evidence
  certificate_hash: String.t(),      # SHA-256 of certificate
  
  # Integrity
  timestamp: DateTime.t(),           # When proof was generated
  prover_version: String.t(),        # Version of proving system
  sha256: String.t()                 # SHA-256 of entire proof object (excluding this field)
}
```

### 1.3 Proof Types

The following proof types are frozen:

| Proof Type | Atom | Claim | Confidence Factors |
|------------|------|-------|-------------------|
| Replay Proof | `:replay` | Deterministic state reconstruction | replay_success_rate, hash_consistency |
| Authority Proof | `:authority` | Authority boundaries enforced | rejection_rate, bypass_count |
| Capability Proof | `:capability` | No orphan capabilities | traceability_rate, conservation_check |
| Institution Proof | `:institution` | Institutions archaeologically reconstructable | completeness, provenance_depth |
| Drift Proof | `:drift` | Unauthorized mutations detected | detection_rate, false_negative_rate |
| Certificate Proof | `:certificate` | Certificates cryptographically valid | signature_validity, chain_integrity |
| Evidence Proof | `:evidence` | Evidence artifacts authentic | hash_verification, signature_check |
| Archaeology Proof | `:archaeology` | Provenance chains complete | explanation_termination, ledger_traceability |
| Entropy Proof | `:entropy` | Entropy remains stable | growth_rate, threshold_margin |
| Fitness Proof | `:fitness` | Fitness remains stable | variance, confidence_interval |
| Cost Proof | `:cost` | Costs reconstructable from ledger | reconstruction_accuracy, completeness |
| Evolution Proof | `:evolution` | Long-horizon stability | degradation_rate, recovery_capability |

---

## 2. Evidence Ontology

### 2.1 What is Evidence?

**Evidence** is an immutable, content-addressed artifact produced by executing a validation campaign.

Evidence supports proofs but does not constitute proof by itself.

### 2.2 Evidence Artifact Schema

```json
{
  "campaign_id": "string",
  "campaign_version": "string",
  "timestamp": "ISO8601",
  "content": {
    "data": {},
    "measurements": {},
    "timings": {}
  },
  "content_hash": "sha256_hex_string",
  "signature": "sha256_hex_string",
  "input_fingerprint": "sha256_hex_string",
  "output_fingerprint": "sha256_hex_string"
}
```

### 2.3 Evidence Properties

**Immutability**: Once written, evidence cannot be modified. Any change produces a new content hash.

**Content Addressing**: Evidence is stored by its SHA-256 content hash. Filename = content_hash.json

**Cryptographic Binding**: Each evidence artifact is signed with SHA-256 signature over critical fields.

**Provenance**: Every evidence artifact traces back to:
- Campaign specification
- Adapter implementations
- Runtime execution context
- Input parameters

---

## 3. Certification Ontology

### 3.1 What is a Certificate?

A **Certificate** is a cryptographically signed attestation that a proof has been independently verified.

Certificates are issued by the IndependentGovernanceAuditor, never by the runtime itself.

### 3.2 Certificate Schema

```json
{
  "certificate_id": "string",
  "certificate_type": "governance_constitutional_certification",
  "issued_to": "proof_id",
  "issued_by": "IndependentGovernanceAuditor",
  "issued_at": "ISO8601",
  "verification_result": {
    "proof_verified": true,
    "evidence_verified": true,
    "signatures_valid": true,
    "hashes_match": true,
    "independence_maintained": true
  },
  "confidence_level": 0.99997,
  "valid_until": "ISO8601_or_null",
  "revocation_status": "active",
  "signature": "ed25519_or_rsa_signature",
  "public_key_fingerprint": "sha256_of_public_key"
}
```

### 3.3 Certificate Properties

**Independence**: Certificates are issued ONLY by IndependentGovernanceAuditor. Runtime cannot self-certify.

**Revocability**: Certificates can be revoked if evidence is later found invalid.

**Chain of Trust**: Each certificate references the proof it certifies, creating an auditable chain.

**Non-Repudiation**: Cryptographic signatures prevent denial of issuance.

---

## 4. Trust Stack

The governance system implements a strict **Trust Stack** with six layers. Each layer trusts ONLY the layer below it, never above.

```
Layer 6: Scientific Claims          ← Highest-level assertions (e.g., "Governance is stable")
         ↓ trusts
Layer 5: Governance Decisions       ← RFC ratifications, deployments, institutional actions
         ↓ trusts
Layer 4: Proof Objects              ← Structured proofs with confidence levels
         ↓ trusts
Layer 3: Evidence Artifacts         ← Content-addressed execution results
         ↓ trusts
Layer 2: Replay Certificates        ← Deterministic reconstruction verification
         ↓ trusts
Layer 1: Cryptographic Hashes       ← SHA-256 integrity guarantees
```

### 4.1 Layer 1: Cryptographic Hashes

**Trust Model**: Mathematical certainty (SHA-256 collision resistance)

**Guarantees**:
- Data integrity
- Tamper detection
- Content addressing

**Algorithms**: SHA-256 (frozen)

### 4.2 Layer 2: Replay Certificates

**Trust Model**: Deterministic computation

**Guarantees**:
- State can be reconstructed from events
- Identical inputs produce identical outputs
- Hash chain integrity

**Verification**: Independent replay engine recomputes state and compares hashes.

### 4.3 Layer 3: Evidence Artifacts

**Trust Model**: Cryptographic binding + content addressing

**Guarantees**:
- Evidence is immutable
- Evidence is attributable to specific campaign
- Evidence has not been tampered with

**Verification**: Recompute content_hash and verify signature.

### 4.4 Layer 4: Proof Objects

**Trust Model**: Statistical inference + evidence chain

**Guarantees**:
- Claims are supported by measurements
- Confidence levels are statistically justified
- Failure modes are documented

**Verification**: Independent auditor recomputes confidence from raw evidence.

### 4.5 Layer 5: Governance Decisions

**Trust Model**: Certified proofs + constitutional compliance

**Guarantees**:
- Decisions are based on verified proofs
- Authority boundaries were respected
- Institutional processes were followed

**Verification**: Check certificates, verify authority chains, audit decision logs.

### 4.6 Layer 6: Scientific Claims

**Trust Model**: Accumulated evidence + long-horizon observation

**Guarantees**:
- Claims are supported by multiple independent proofs
- Claims have survived adversarial testing
- Claims demonstrate statistical robustness

**Verification**: Meta-analysis of all supporting proofs, longitudinal stability assessment.

### 4.7 Trust Stack Invariant

**CRITICAL**: No layer may trust a higher layer. This prevents circular reasoning.

Example violations (FORBIDDEN):
- ❌ Layer 3 trusting Layer 5 claims
- ❌ Runtime certifying its own evidence
- ❌ Proof asserting its own confidence without measurement

Correct flow:
- ✅ Layer 4 computes confidence from Layer 3 measurements
- ✅ Layer 5 decisions reference Layer 4 certificates
- ✅ Layer 6 claims aggregate Layer 5 decisions

---

## 5. Verification Independence

### 5.1 Core Principle

**The generator of evidence must NEVER be the verifier of that evidence.**

This is the fundamental separation that prevents "grading your own exam."

### 5.2 Architectural Separation

```
┌─────────────────────┐
│  Governance Runtime │  ← Generates evidence
│  - CampaignExecutor │
│  - Adapters         │
│  - SimulationEngine │
└──────────┬──────────┘
           │
           ▼ produces
┌─────────────────────┐
│  Evidence Artifacts │  ← Immutable, content-addressed
│  (content-hash.json)│
└──────────┬──────────┘
           │
           ▼ verifies
┌─────────────────────┐
│  Independent Auditor│  ← Verifies without trusting runtime
│  - Hash recomputation│
│  - Signature check  │
│  - Manifest audit   │
└──────────┬──────────┘
           │
           ▼ issues
┌─────────────────────┐
│  Certificates       │  ← Cryptographic attestation
│  (cert-id.json)     │
└─────────────────────┘
```

### 5.3 Auditor Trust Boundaries

The IndependentGovernanceAuditor:

**TRUSTS**:
- ✅ SHA-256 hash algorithm (mathematical certainty)
- ✅ Evidence files read from disk (raw bytes)
- ✅ Cryptographic signatures (if public key is known)
- ✅ Replay engine (independently implemented)
- ✅ Manifest files (structure only)

**DOES NOT TRUST**:
- ❌ Runtime internal state
- ❌ Self-reported metrics
- ❌ Unverified claims
- ❌ Runtime assertions
- ❌ Campaign pass/fail status (recomputes independently)

### 5.4 Independence Verification

To verify independence is maintained:

1. **Code Separation**: Auditor code lives in separate module hierarchy (`TiannaraOS.Governance.Certification.*`)
2. **No Runtime Imports**: Auditor does not import runtime modules (except for data structures)
3. **File-Based Interface**: Auditor reads evidence from filesystem, not from runtime memory
4. **Independent Replay**: Auditor uses separate replay implementation or verifies replay independently
5. **Audit Trail**: All auditor operations logged separately from runtime logs

---

## 6. Confidence Model

### 6.1 Constitutional Confidence Engine

Instead of binary PASS/FAIL, every proof produces a **confidence level** derived from multiple factors.

### 6.2 Confidence Formula

```
Overall Confidence = 
  (Replay Confidence × w1) +
  (Statistical Power × w2) +
  (Fuzz Coverage × w3) +
  (Archaeology Completeness × w4) +
  (Drift Detection Sensitivity × w5) +
  (Entropy Stability Score × w6)
```

Where weights (w1 through w6) sum to 1.0 and are defined per proof type.

### 6.3 Confidence Factors

#### Replay Confidence
```
replay_confidence = successful_replays / total_replays
```
- Measures deterministic state reconstruction
- Target: ≥ 0.999 (99.9%)

#### Statistical Power
```
statistical_power = 1 - β (Type II error rate)
```
- Probability of detecting true effect
- Computed from sample size and effect size
- Target: ≥ 0.80 (80%)

#### Fuzz Coverage
```
fuzz_coverage = illegal_operations_tested / total_possible_violations
```
- Measures authority boundary testing completeness
- Target: ≥ 0.95 (95%)

#### Archaeology Completeness
```
archaeology_completeness = explained_artifacts / total_artifacts
```
- Measures provenance chain termination at GovernanceLedger
- Target: 1.0 (100%)

#### Drift Detection Sensitivity
```
drift_sensitivity = detected_mutations / injected_mutations
```
- Measures ability to detect unauthorized changes
- Target: 1.0 (100% detection, 0% false negatives)

#### Entropy Stability Score
```
entropy_stability = 1 - (entropy_growth_rate / threshold)
```
- Measures governance entropy over time
- Target: ≥ 0.95 (stable, not growing)

### 6.4 Confidence Levels

| Level | Confidence | Interpretation |
|-------|-----------|----------------|
| CERTIFIED | ≥ 0.9999 | Constitutional grade - suitable for freeze |
| VALIDATED | ≥ 0.99 | High confidence - suitable for production |
| VERIFIED | ≥ 0.95 | Moderate confidence - suitable for testing |
| EXPERIMENTAL | < 0.95 | Low confidence - requires more evidence |

### 6.5 Confidence Reporting

Every proof must report:

```elixir
%{
  overall_confidence: 0.99997,
  confidence_level: :CERTIFIED,
  breakdown: %{
    replay_confidence: 1.0,
    statistical_power: 0.99,
    fuzz_coverage: 0.998,
    archaeology_completeness: 1.0,
    drift_sensitivity: 1.0,
    entropy_stability: 0.999
  },
  limiting_factor: :statistical_power,  # Which factor limits overall confidence
  recommendation: "Increase sample size from 1000 to 5000 to achieve 0.9999 confidence"
}
```

---

## 7. Statistical Guarantees

### 7.1 Sample Size Requirements

Minimum sample sizes for constitutional certification:

| Campaign | Minimum Samples | Recommended | Rationale |
|----------|----------------|-------------|-----------|
| GC-001 Replay | 1000 | 10000 | Detect rare non-determinism |
| GC-002 Authority Fuzzing | 5000 | 50000 | Cover edge cases |
| GC-009 Entropy | 10000 | 100000 | Observe long-term trends |
| GC-010 Fitness | 10000 | 100000 | Measure stability over time |
| GC-012 Long Horizon | 100000 | 1000000 | Detect slow degradation |

### 7.2 Statistical Significance

All proofs must report:

- **p-value**: Probability of observing results by chance
- **Effect size**: Magnitude of measured effect
- **Confidence interval**: Range of plausible values (95% CI)

Target: p < 0.01 (99% confidence) for constitutional certification.

### 7.3 Reproducibility Guarantee

Every proof must be **reproducible**:

Given the same:
- Input parameters
- Random seed (if applicable)
- Runtime environment

The proof must produce:
- Identical measurements (± floating point tolerance)
- Identical confidence level
- Identical conclusion

Verification: Independent auditor re-runs proof and compares results.

---

## 8. Failure Mode Analysis

### 8.1 Known Failure Modes

Every proof must document its failure modes:

```elixir
failure_modes: [
  %{
    mode: :insufficient_sample_size,
    probability: 0.01,
    impact: :low_confidence,
    mitigation: "Increase samples to 10000"
  },
  %{
    mode: :floating_point_drift,
    probability: 0.001,
    impact: :hash_mismatch,
    mitigation: "Use decimal arithmetic for critical comparisons"
  },
  %{
    mode: :clock_skew,
    probability: 0.0001,
    impact: :timestamp_inconsistency,
    mitigation: "Use monotonic clocks for timing measurements"
  }
]
```

### 8.2 Catastrophic Failure Modes

These failure modes invalidate the entire proof:

- **Hash collision**: SHA-256 collision (probability ≈ 2^-128, effectively zero)
- **Private key compromise**: Auditor signing key leaked
- **Systematic bias**: All samples drawn from biased distribution
- **Implementation bug**: Proof computation contains logic error

Mitigation: Independent implementation cross-check, formal verification where possible.

---

## 9. Amendment Process

This constitution can only be amended through:

1. **RFC Submission**: Propose amendment with justification
2. **Impact Analysis**: Show how amendment affects existing proofs
3. **Simulation**: Run all certification campaigns with proposed change
4. **Review Board Review**: Constitutional compliance check
5. **Ratification**: Governance Council supermajority vote (≥ 2/3)
6. **Migration Plan**: Define how existing proofs transition
7. **Deployment**: Execute via DeploymentOrchestrator with rollback
8. **Evidence**: Generate signed evidence of amendment process
9. **Certificate Update**: Issue new constitution version certificate

---

## 10. Relationship to Other Constitutions

### 10.1 Phase 13 Causal Flow Constitution

- **CausalFlow** defines causality in scientific execution
- **GovernanceProof** defines proof in governance validation
- Both share: immutability, determinism, archaeological explainability

### 10.2 Kernel Constitution

- **Kernel Constitution** defines core OS invariants
- **GovernanceProof Constitution** defines governance validation invariants
- Governance proofs must respect kernel invariants

### 10.3 Validation Runtime Constitution

- **Validation Runtime** executes campaigns
- **GovernanceProof Constitution** defines what campaigns must prove
- Runtime implements, constitution specifies

---

## Appendix A: Proof Object Examples

### A.1 Replay Proof Example

```elixir
%{
  proof_id: "GC-001-REPLAY-PROOF-001",
  proof_type: :replay,
  version: "14.0.965",
  
  claim: "Deterministic state reconstruction verified across 1000 random histories",
  claim_type: :determinism,
  
  inputs: %{
    sample_size: 1000,
    random_seed: 42,
    history_length_range: 10..50
  },
  
  measurements: %{
    total_replays: 1000,
    successful_replays: 1000,
    failed_replays: 0,
    average_duration_ms: 15.3
  },
  
  metrics: %{
    sample_size: 1000,
    success_rate: 1.0,
    failure_count: 0,
    duration_ms: 15300
  },
  
  confidence: 0.9999,
  confidence_breakdown: %{
    replay_confidence: 1.0,
    statistical_power: 0.99,
    fuzz_coverage: nil,
    archaeology_completeness: nil,
    drift_detection_sensitivity: nil,
    entropy_stability_score: nil
  },
  statistical_power: 0.99,
  significance_level: 0.01,
  
  failure_modes: [
    %{
      mode: :hash_collision,
      probability: 1.0e-38,
      impact: :catastrophic,
      mitigation: "SHA-256 collision resistance"
    }
  ],
  assumptions: [
    "SHA-256 is collision-resistant",
    "Random number generator is unbiased",
    "State serialization is deterministic"
  ],
  
  supporting_evidence: [
    "a0d27f2e1f1d2ddad83514144fe17fe336abed646ca4c867231659d0254f8a06",
    "a1922e8555ec511c7d152b2dbc2a371bc8ccaf8ea61bb0899080b8598ee9ea81"
  ],
  evidence_manifest: "manifest_gc001_20260613.json",
  
  certificate: %{
    certificate_id: "CERT-GC001-001",
    issued_by: "IndependentGovernanceAuditor",
    issued_at: "2026-06-13T19:30:00Z"
  },
  certificate_hash: "abc123...",
  
  timestamp: ~U[2026-06-13 19:30:00Z],
  prover_version: "14.0.965",
  sha256: "COMPUTE_HASH_OF_THIS_OBJECT"
}
```

### A.2 Authority Proof Example

```elixir
%{
  proof_id: "GC-002-AUTHORITY-PROOF-001",
  proof_type: :authority,
  version: "14.0.965",
  
  claim: "Authority boundaries enforced across 5000 illegal operations",
  claim_type: :authority_enforcement,
  
  inputs: %{
    test_count: 5000,
    operation_types: [:review_board_deploy, :citizen_edit_kernel, ...]
  },
  
  measurements: %{
    total_tests: 5000,
    rejections: 5000,
    bypasses: 0,
    errors: 0
  },
  
  metrics: %{
    sample_size: 5000,
    success_rate: 1.0,
    failure_count: 0,
    duration_ms: 2500
  },
  
  confidence: 0.9998,
  confidence_breakdown: %{
    replay_confidence: nil,
    statistical_power: 0.98,
    fuzz_coverage: 0.998,
    archaeology_completeness: nil,
    drift_detection_sensitivity: nil,
    entropy_stability_score: nil
  },
  statistical_power: 0.98,
  significance_level: 0.01,
  
  failure_modes: [...],
  assumptions: [...],
  
  supporting_evidence: [...],
  evidence_manifest: "manifest_gc002_20260613.json",
  
  certificate: %{...},
  certificate_hash: "...",
  
  timestamp: ~U[2026-06-13 19:35:00Z],
  prover_version: "14.0.965",
  sha256: "..."
}
```

---

## Appendix B: Trust Stack Verification Checklist

To verify Trust Stack integrity:

- [ ] Layer 1 (Hashes): SHA-256 implementation verified against test vectors
- [ ] Layer 2 (Replay): Independent replay produces identical hashes
- [ ] Layer 3 (Evidence): All evidence files have valid content_hash and signature
- [ ] Layer 4 (Proofs): All proofs reference valid evidence hashes
- [ ] Layer 5 (Decisions): All decisions reference valid certificates
- [ ] Layer 6 (Claims): All claims aggregate multiple certified proofs
- [ ] No circular dependencies between layers
- [ ] Auditor code does not import runtime internals
- [ ] All cryptographic keys properly managed

---

**Signed**: Governance Council  
**Witnessed**: Observatory  
**Verified**: Independent Auditor  
**Frozen**: June 13, 2026

**Amendment requires**: RFC ratification with ≥ 2/3 supermajority
