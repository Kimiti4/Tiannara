# Scientific Discovery Architecture

## Overview

This document defines the constitutional architecture for Phase 15: Scientific Discovery. It transforms Tiannara into a constitutional scientific discovery platform capable of generating, testing, validating, preserving, replaying, and evolving scientific knowledge through reproducible evidence.

**Scientific discovery—not governance—is now the primary workload.**

---

## Constitutional Principles

### 1. Reproducibility as Constitution
Every scientific claim must be reproducible through deterministic replay. No result is valid without a verifiable replay certificate.

### 2. Evidence-First Architecture
Evidence is the atomic unit of scientific truth. All higher constructs (hypotheses, theories, discoveries) are derived from and traceable to evidence.

### 3. Content-Addressed Identity
Every scientific object is identified by its content hash (Blake3). Identity is immutable and derived from content, not assigned.

### 4. Deterministic Execution
All scientific computation must be deterministic. Non-determinism is treated as a bug, not a feature.

### 5. Archaeological Preservation
Every state transition, every decision, every experiment is preserved for archaeological reconstruction.

### 6. Ownership Graph Transparency
Every scientific object has an explicit owner (agent, civilization, or protocol). Ownership transfers are recorded in the ledger.

### 7. Theory Evolution with Lineage
Theories evolve through explicit revision chains. Supersession, contradiction, and refinement are first-class operations with full provenance.

---

## System Topology

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        SCIENTIFIC DISCOVERY PLATFORM                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐  │
│  │  OBSERVATION │   │ HYPOTHESIS   │   │ EXPERIMENT   │   │  DISCOVERY   │  │
│  │   REGISTRY   │───│   REGISTRY   │───│   REGISTRY   │───│   REGISTRY   │  │
│  └──────┬───────┘   └──────┬───────┘   └──────┬───────┘   └──────┬───────┘  │
│         │                  │                  │                  │          │
│         ▼                  ▼                  ▼                  ▼          │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                      EVIDENCE ENGINE                                  │   │
│  │         (Collection, Validation, Statistical Analysis, Fingerprinting)│   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│         │                                                                  │
│         ▼                                                                  │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐  │
│  │    THEORY    │   │   KNOWLEDGE  │   │  SCIENTIFIC  │   │    REPLAY    │  │
│  │    ENGINE    │───│    GRAPH     │───│   CAPITAL    │───│    ENGINE    │  │
│  └──────┬───────┘   └──────┬───────┘   └──────┬───────┘   └──────┬───────┘  │
│         │                  │                  │                  │          │
│         └──────────────────┼──────────────────┼──────────────────┘          │
│                            ▼                  ▼                             │
│              ┌────────────────────────────────────────────────┐             │
│              │           CERTIFICATE ISSUER                    │             │
│              │  (DiscoveryCertificate, ReplayCertificate,      │             │
│              │   TheoryCertificate, CapitalCertificate)        │             │
│              └────────────────────────────────────────────────┘             │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Core Components

### 1. Observation Registry
**Purpose**: Canonical registry of all scientific observations
- Immutable, append-only ledger
- Content-addressed by Blake3 hash of observation data
- Supports multi-modal observations (sensor, simulation, human, derived)
- Each observation carries: timestamp, observer_id, context_hash, raw_data_ref, metadata

### 2. Hypothesis Registry
**Purpose**: Registry of falsifiable scientific hypotheses
- Every hypothesis links to: originating observations, proposed mechanism, falsification criteria
- Hypothesis state machine: PROPOSED → TESTING → SUPPORTED / FALSIFIED / INCONCLUSIVE
- Hypotheses are versioned; revisions create new content-addressed entries

### 3. Experiment Registry
**Purpose**: Registry of experimental designs and executions
- Experiment = Design + Execution + Results
- Design: protocol, parameters, controls, predicted outcomes, statistical power
- Execution: runtime environment hash, resource allocation, timeline
- Results: evidence references, statistical analysis, conclusion

### 4. Discovery Registry
**Purpose**: Registry of validated scientific discoveries
- Discovery = Hypothesis + Supporting Evidence + Statistical Significance + Reproducibility Proof
- Requires independent replication (configurable threshold)
- Discovery certificate issued upon validation

### 5. Theory Engine
**Purpose**: Manages theory lifecycle and evolution
- Theory = Set of hypotheses + Mathematical framework + Predictive scope + Confidence
- Operations: REVISE, SUPERSEDE, CONTRADICT, MERGE, DEPRECATE
- Full lineage tracking with content-addressed theory versions

### 6. Knowledge Graph
**Purpose**: Semantic graph of scientific knowledge
- Nodes: Observations, Hypotheses, Experiments, Discoveries, Theories, Concepts
- Edges: SUPPORTS, CONTRADICTS, DERIVES_FROM, REFINES, SUPERSEDES, REPLICATES
- Graph is deterministic, replayable, and archaeologically complete

### 7. Evidence Engine
**Purpose**: Centralized evidence management
- Evidence collection, validation, fingerprinting, statistical analysis
- Evidence chains: raw → processed → analyzed → interpreted
- Statistical engine: p-values, confidence intervals, effect sizes, Bayesian factors

### 8. Scientific Capital Engine
**Purpose**: Tracks and evolves scientific capital across 8 dimensions
- Discovery Capital, Evidence Capital, Knowledge Capital, Theory Capital
- Prediction Capital, Engineering Capital, Innovation Capital, Reproducibility Capital
- Capital deltas are deterministic, replayable, and auditable

### 9. Replay Engine
**Purpose**: Deterministic replay of any scientific computation
- Input: Content-addressed experiment/observation/discovery + Environment snapshot
- Output: Bit-for-bit identical results + Replay certificate
- Supports: Full replay, Partial replay, Differential replay, Archaeological replay

### 10. Certificate Issuer
**Purpose**: Cryptographic certification of scientific claims
- DiscoveryCertificate: Validates a discovery meets all criteria
- ReplayCertificate: Validates deterministic replay succeeded
- TheoryCertificate: Validates theory evolution follows protocol
- CapitalCertificate: Validates capital delta computation

---

## Data Flow Architecture

### Observation → Hypothesis Flow
```
Observation Registry
       │
       ▼ (pattern detection, anomaly identification)
Hypothesis Generator
       │
       ▼ (falsification criteria specification)
Hypothesis Registry ◄── Falsification Criteria
```

### Hypothesis → Experiment Flow
```
Hypothesis Registry
       │
       ▼ (experiment design)
Experiment Designer
       │
       ▼ (protocol, parameters, power analysis)
Experiment Registry (DESIGN phase)
       │
       ▼ (execution scheduling)
Experiment Executor
       │
       ▼ (evidence collection)
Evidence Engine
       │
       ▼ (statistical analysis)
Statistics Engine
       │
       ▼ (results recording)
Experiment Registry (RESULTS phase)
```

### Experiment → Discovery Flow
```
Experiment Registry (completed)
       │
       ▼ (evidence aggregation)
Evidence Engine
       │
       ▼ (significance testing, replication check)
Discovery Validator
       │
       ▼ (certificate issuance)
Certificate Issuer → Discovery Registry
```

### Discovery → Theory Flow
```
Discovery Registry
       │
       ▼ (theory integration)
Theory Engine
       │
       ▼ (lineage update, confidence revision)
Theory Registry + Knowledge Graph
```

---

## Ownership Model

### Canonical Ownership Graph

```
┌─────────────────────────────────────────────────────────────┐
│                    OWNERSHIP HIERARCHY                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  PROTOCOL (Root Owner)                                       │
│       │                                                      │
│       ├── CIVILIZATION A                                     │
│       │       │                                              │
│       │       ├── AGENT_1 ──► Observation_1, Hypothesis_1   │
│       │       ├── AGENT_2 ──► Experiment_1, Discovery_1     │
│       │       └── AGENT_N ──► Theory_1                      │
│       │                                                      │
│       ├── CIVILIZATION B                                     │
│       │       └── ...                                        │
│       │                                                      │
│       └── AUTONOMOUS DISCOVERY ENGINE                        │
│               │                                              │
│               ├── Observation_auto_1                         │
│               ├── Hypothesis_auto_1                          │
│               └── Theory_auto_1                              │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Ownership Transfer Rules
1. **Observation**: Owner = Observer (agent or sensor). Transfer only via explicit delegation.
2. **Hypothesis**: Owner = Proposer. Co-ownership for collaborative hypotheses.
3. **Experiment**: Owner = Designer. Execution rights delegated to Executor.
4. **Discovery**: Owner = Validating Civilization. Shared with replicators.
5. **Theory**: Owner = Theory Engine (protocol). Contributors credited in lineage.
6. **Evidence**: Owner = Collector. Immutable once collected.
7. **Capital**: Owner = Capital Engine (protocol). Agents hold claims.

---

## Replay Model

### Replay Ownership
- **Replay Requestor**: Owns the replay request and results
- **Replay Engine**: Protocol-owned, executes replay
- **Original Owner**: Retains ownership of original artifacts
- **Replay Certificate**: Owned by Requestor, verified by Protocol

### Replay Determinism Guarantees
1. **Environment Snapshotting**: Complete runtime state captured (memory, RNG state, clock)
2. **Content-Addressed Inputs**: All inputs identified by Blake3 hash
3. **Deterministic Scheduling**: Fixed execution order, no race conditions
4. **Verifiable Outputs**: Output hash matches original; certificate proves equivalence

---

## Scientific Capital Model

### Eight Capital Types

| Capital Type | Source | Measurement | Evolution |
|--------------|--------|-------------|-----------|
| Discovery | Validated discoveries | Count × Significance × Replication | Compounds with independent validation |
| Evidence | Collected evidence | Quality × Quantity × Novelty | Accumulates; decays without replication |
| Knowledge | Graph nodes/edges | Connectivity × Centrality × Accuracy | Grows through integration; pruned by contradiction |
| Theory | Active theories | Scope × Predictive Power × Confidence | Evolves through revision; supersession transfers capital |
| Prediction | Verified predictions | Accuracy × Horizon × Specificity | Validated predictions transfer to Theory Capital |
| Engineering | Deployed applications | Utility × Reliability × Adoption | Compounds with real-world validation |
| Innovation | Novel methods/tools | Novelty × Adoption × Impact | Transfers to Engineering Capital upon deployment |
| Reproducibility | Successful replays | Rate × Diversity × Independence | Meta-capital; amplifies all other capital |

### Capital Delta Computation
```
ΔCapital = Σ(weight_i × Δmetric_i) × confidence_factor × reproducibility_multiplier
```

All deltas are deterministic, content-addressed, and replayable.

---

## Certification Framework

### Certificate Types

1. **DiscoveryCertificate**
   - Proves: Hypothesis tested, evidence collected, statistics significant, replication achieved
   - Fields: discovery_hash, hypothesis_hash, evidence_hashes[], statistical_result_hash, replication_proofs[], issuer_signature, timestamp

2. **ReplayCertificate**
   - Proves: Deterministic replay produced identical results
   - Fields: original_hash, replay_hash, environment_snapshot_hash, executor_id, verifier_signature, timestamp

3. **TheoryCertificate**
   - Proves: Theory evolution followed protocol (revision/supersession/contradiction)
   - Fields: theory_hash, previous_theory_hash, operation_type, justification_hash, lineage_proof, issuer_signature

4. **CapitalCertificate**
   - Proves: Capital delta computed correctly from validated sources
   - Fields: capital_type, delta_hash, source_hashes[], computation_proof, issuer_signature

---

## Interface Contracts

### Registry Contract (All Registries)
```elixir
@behaviour RegistryContract
@spec register(content: Content.t()) :: {:ok, ContentHash.t()} | {:error, Reason.t()}
@spec get(hash: ContentHash.t()) :: {:ok, Content.t()} | {:error, :not_found}
@spec verify(hash: ContentHash.t()) :: :valid | :invalid
@spec lineage(hash: ContentHash.t()) :: [ContentHash.t()]
@spec ownership(hash: ContentHash.t()) :: Owner.t()
```

### Ledger Contract
```elixir
@behaviour LedgerContract
@spec append(entry: LedgerEntry.t()) :: {:ok, LedgerIndex.t()} | {:error, Reason.t()}
@spec get(index: LedgerIndex.t()) :: {:ok, LedgerEntry.t()} | {:error, :not_found}
@spec verify_chain(from: LedgerIndex.t(), to: LedgerIndex.t()) :: :valid | :invalid
@spec proof(index: LedgerIndex.t()) :: MerkleProof.t()
```

### Replay Contract
```elixir
@behaviour ReplayContract
@spec replay(execution_id: ExecutionId.t(), environment: EnvironmentSnapshot.t()) :: 
  {:ok, ReplayResult.t()} | {:error, Reason.t()}
@spec verify_replay(original: ExecutionId.t(), replay: ReplayResult.t()) :: 
  {:ok, ReplayCertificate.t()} | {:error, :mismatch}
```

### Certificate Contract
```elixir
@behaviour CertificateContract
@spec issue(certificate_type: CertificateType.t(), payload: Payload.t()) :: 
  {:ok, Certificate.t()} | {:error, Reason.t()}
@spec verify(certificate: Certificate.t()) :: :valid | :invalid
@spec revoke(certificate: Certificate.t(), reason: Reason.t()) :: :ok | {:error, Reason.t()}
```

---

## Integration with Existing Tiannara Systems

### Phase 13 (Constitutional Governance) Integration
- Scientific discovery operates under constitutional laws
- Certificate issuer uses governance identity system
- Capital evolution subject to constitutional conservation laws

### Phase 14 (Meta-Governance) Integration
- Discovery validation campaigns are meta-governance operations
- Independent audit uses Phase 14 audit infrastructure
- Scientific readiness index feeds into civilization metrics

### OSE (Ontology Substrate Engine) Integration
- Knowledge graph uses OSE for cross-ontology translation
- Theory evolution uses OSE causal compatibility stress testing
- Concept nodes mapped to OSE epistemic niches

### REL (Reality Economy Layer) Integration
- Scientific capital trades on REL economy engine
- Discovery assets are REL discovery assets
- Capital deltas generate REL economic outcomes

### ASC (Autonomous Scientific Civilization) Integration
- ASC agents participate as observers, hypothesizers, experimenters
- ASC guilds organize around scientific domains
- ASC research programs drive discovery campaigns

---

## Security Model

### Threat Model
1. **Data Poisoning**: Malicious observations injected → Mitigated by observer reputation, evidence validation
2. **Replay Subversion**: Non-deterministic execution → Mitigated by environment snapshots, deterministic scheduling
3. **Certificate Forgery**: Fake certificates → Mitigated by cryptographic signatures, governance PKI
4. **Capital Manipulation**: Inflated capital claims → Mitigated by deterministic computation, independent audit
5. **History Rewriting**: Ledger tampering → Mitigated by Merkle proofs, content-addressed immutability

### Trust Boundaries
- **Protocol Boundary**: Core registries, engines, certificate issuer (highest trust)
- **Civilization Boundary**: Civilization-owned agents and assets (medium trust)
- **Agent Boundary**: Individual agent actions (lowest trust, requires verification)
- **External Boundary**: Human input, sensor data (requires validation pipeline)

---

## Scalability Architecture

### Horizontal Scaling
- Registries sharded by content hash prefix
- Evidence engine partitioned by observation domain
- Replay engine stateless; scales with compute
- Knowledge graph uses distributed graph database

### Performance Targets
- Observation registration: < 10ms p99
- Hypothesis registration: < 50ms p99
- Experiment scheduling: < 100ms p99
- Discovery validation: < 1s p99 (async)
- Replay verification: < 5s p99
- Certificate issuance: < 100ms p99

---

## Deployment Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     DEPLOYMENT TOPOLOGY                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │  CONTROL    │  │  DATA       │  │  COMPUTE    │             │
│  │  PLANE      │  │  PLANE      │  │  PLANE      │             │
│  ├─────────────┤  ├─────────────┤  ├─────────────┤             │
│  │ Certificate │  │ Registries  │  │ Experiment  │             │
│  │ Issuer      │  │ (ETS/DB)    │  │ Executors   │             │
│  │ Replay      │  │ Ledgers     │  │ Evidence    │             │
│  │ Verifier    │  │ Graph DB    │  │ Collectors  │             │
│  │ Capital     │  │ Blob Store  │  │ Statistics  │             │
│  │ Engine      │  │             │  │ Engine      │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│         │               │               │                       │
│         └───────────────┼───────────────┘                       │
│                         ▼                                       │
│              ┌─────────────────────┐                           │
│              │   MESSAGE BUS       │                           │
│              │   (NATS/Event Bus)  │                           │
│              └─────────────────────┘                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Constitutional Compliance

This architecture satisfies all Constitutional Invariants:

1. **Causality**: All scientific operations have explicit causal chains (observation → hypothesis → experiment → discovery → theory)
2. **Conservation**: Scientific capital is conserved; deltas are auditable and reversible
3. **Identity**: Every object has content-addressed identity; ownership is explicit
4. **Stability**: Deterministic replay ensures meta-stability of scientific knowledge
5. **Observability**: Full archaeological trace for every scientific claim

---

## Next Steps

1. **DISCOVERY_PIPELINE.md** - Detailed pipeline specifications
2. **DISCOVERY_DATA_MODEL.md** - Complete data model with schemas
3. **DISCOVERY_REPLAY_MODEL.md** - Replay engine specification
4. **DISCOVERY_CERTIFICATION.md** - Certification framework details
5. **PHASE15_ARCHITECTURE_REVIEW.md** - Architecture review summary

---

*This document is part of Phase 15.0 Architecture Review. No implementation occurs in this phase.*