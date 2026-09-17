# CAUSAL_CERTIFICATION.md

## Phase 17.3 — Causal Discovery Constitutional Certification

---

## 1. Certification Purpose

Certify that a causal graph and its discovery process satisfy the constitutional requirements of:

- **Deterministic replay** — every stage reproduces identically
- **Evidence grounding** — every edge has supporting evidence
- **Uncertainty transparency** — all confidence bounds are explicit
- **Archaeological completeness** — every decision is traceable
- **Intervention safety** — no paradoxical or invalid interventions

---

## 2. Certification Checks

### Check 1 — Deterministic Replay

**Verification**: Re-run the full discovery pipeline from the original evidence set and configuration. Compare all stage roots against stored values.

**Pass condition**: All stage roots match exactly.

**Failure**: Root mismatch at any stage — certification blocked.

---

### Check 2 — Evidence Grounding

**Verification**: For each edge in the final graph:
1. Locate the independence test that established the edge
2. Verify the test references a valid evidence root
3. Verify the evidence root exists in the ObservationRegistry
4. Verify the test statistic supports the edge direction

**Pass condition**: 100% of edges have verifiable evidence grounding.

**Failure**: Any edge lacks evidence grounding — certification blocked.

---

### Check 3 — Cycle Prevention

**Verification**:
1. Run DFS-based cycle detection on the directed graph
2. Validate that do-calculus level is consistent with graph structure
3. Verify that orientation rules did not create cycles
4. Check that all cycles detected during construction were properly rejected

**Pass condition**: Graph is acyclic, do-calculus level is valid.

**Failure**: Cycle found — certification blocked.

---

### Check 4 — Uncertainty Transparency

**Verification**:
1. Every edge has a confidence score in [0, 1]
2. Every independence test stores p-value and confidence
3. Every latent variable has confidence and alternatives
4. Every intervention plan stores confidence and identifiability

**Pass condition**: No missing uncertainty metadata.

**Failure**: Any element missing uncertainty — certification blocked.

---

### Check 5 — Archaeological Completeness

**Verification**:
1. Archaeology entries exist for each pipeline stage
2. Every edge in the final graph has an archaeology entry
3. Rejected alternatives are preserved in archaeology
4. Latent variable entries document competing explanations

**Pass condition**: Full archaeological coverage.

**Failure**: Missing archaeology entries — certification blocked.

---

### Check 6 — Alternative Structure Preservation

**Verification**:
1. At least one alternative graph is replayable for the same evidence set
2. Alternative graphs are stored with their scores and derivation
3. The difference between each alternative and the chosen graph is documented

**Pass condition**: At least one alternative exists and is replayable.

**Failure**: No alternatives preserved — certification blocked.

---

### Check 7 — Intervention Safety

**Verification**:
1. Every proposed intervention has an identifiability classification
2. Non-identifiable interventions are flagged
3. Intervention effects include confidence intervals
4. Downstream consequences are traced for all causal pathways

**Pass condition**: All interventions classified, non-identifiable flagged.

**Failure**: Any intervention lacks classification — certification blocked.

---

### Check 8 — Mathematical Consistency

**Verification**:
1. Edge directions respect known mathematical laws (from Phase 16.X)
2. No contradictory edge directions (X → Y and Y → X)
3. No impossible causal loops given domain constraints
4. Latent variables respect dimensionality constraints

**Pass condition**: All mathematical consistency checks pass.

**Failure**: Mathematical inconsistency detected — certification blocked.

---

## 3. Certificate Structure

```elixir
defmodule TiannaraRuntime.CausalDiscovery.CausalCertificate do
  defstruct [
    :certificate_id,
    :causal_graph_id,        # graph fingerprint
    :model_id,               # from Phase 17.1 ModelRegistry
    :model_version,
    :checks,                 # [CertificationCheck.t]
    :overall_status,         # :pass | :fail
    :causal_root,            # combined stage root
    :issued_at,
    :issued_by               # :self | :auditor
  ]
end
```

---

## 4. Certification Flow

```
┌──────────────┐
│  Request      │
│  Certification│
└──────┬───────┘
       │
       ▼
┌──────────────────────────────────────────────────────┐
│                   Pre-Checks                          │
│  • Model exists in ModelRegistry                     │
│  • Evidence roots are valid                          │
│  • Causal config is recorded                         │
└──────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────┐
│               Deterministic Replay                    │
│  • Re-run full pipeline from evidence                │
│  • Compare all stage roots                           │
│  • Report mismatches                                  │
└──────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────┐
│             Evidence Grounding Check                  │
│  • Verify every edge references a test               │
│  • Verify test references evidence                   │
│  • Verify evidence exists in registry                │
└──────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────┐
│          Structure & Safety Checks                    │
│  • Cycle detection                                    │
│  • Uncertainty transparency                           │
│  • Intervention safety                                │
│  • Mathematical consistency                           │
└──────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────┐
│            Archaeological Completeness                 │
│  • Every edge has archaeology entry                   │
│  • Alternatives are preserved                         │
└──────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────┐
│              Issue Certificate                         │
│  • All checks pass → status :pass                     │
│  • Any check fails → status :fail                     │
│  • Certificate stored in ModelRegistry metadata       │
└──────────────────────────────────────────────────────┘
```

---

## 5. Certification Authority

| Issuer | Authority |
|--------|-----------|
| `:self` | Pipeline self-certification (Stage 8 in Phase 17.2) |
| `:auditor` | Independent audit (Phase 17.3.96) |

Self-certification can be overridden by independent audit.

---

## 6. Post-Certification Actions

| Status | Action |
|--------|--------|
| `:pass` | Graph is certified. Model can transition to `:operational` |
| `:fail` | Graph cannot be deployed. Model remains `:validated` |
| Violation details | Full violation report added to archaeology |

---

## 7. Recertification

A graph must be recertified if:

- New evidence changes the independence results
- The pipeline configuration changes
- The graph is evolved with new edges
- An independent audit finds violations
- The certificate expires (if time-bound)

---

*This document is Phase 17.3.0 deliverable. Certification model subject to constitutional review before freeze.*
