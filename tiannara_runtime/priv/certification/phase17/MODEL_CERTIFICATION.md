# MODEL_CERTIFICATION.md

## Phase 17 — World Model Certification Framework

---

## 1. Purpose

Certification is the constitutional process by which a world model is deemed fit for operational use. A certified model carries guarantees of mathematical consistency, causal soundness, evidence fidelity, and replay determinism.

Certification is not optional. No model may issue predictions without an operational certificate.

---

## 2. Certification Tiers

### Tier 1 — Mathematical Certification

**Required for**: All models entering validation

**Checks**:

| Check | Description | Gate |
|-------|-------------|------|
| Equation parseability | All symbolic expressions valid in Phase 16.X form | Mandatory |
| Dimensional consistency | All equations dimensionally homogeneous | Mandatory |
| Algebraic solvability | Equation system has a solution | Mandatory |
| Differential well-posedness | Initial value problem has unique solution (if ODE) | Mandatory |
| Variable bounds satisfaction | Parameter estimates lie within declared bounds | Mandatory |
| Graph acyclicity | Causal graph is a DAG (excluding reciprocal edges) | Mandatory |

**Outcome**: `certificate.mathematical = :pass | :fail`

### Tier 2 — Validation Certification

**Required for**: All models entering operational deployment

**Checks**:

| Check | Description | Gate |
|-------|-------------|------|
| Predictive accuracy | RMSE below domain threshold | Mandatory |
| Coverage calibration | Confidence intervals within ±2% of nominal | Mandatory |
| Log-likelihood | Above baseline model | Mandatory |
| Cross-validation | Performance consistent across folds | Mandatory |
| Intervention accuracy | Intervention predictions match experiments | Mandatory |
| Sensitivity stability | Small parameter changes → small output changes | Mandatory |
| Extrapolation warning | Flag if predictions leave training evidence range | Advisory |

**Outcome**: `certificate.validation = :pass | :fail`

### Tier 3 — Operational Certification

**Required for**: All models in `:operational` status

**Checks**:

| Check | Description | Gate |
|-------|-------------|------|
| Full certificate chain | Tier 1 + Tier 2 both pass | Mandatory |
| Replay determinism | `replay_model()` returns identical model | Mandatory |
| Evidence lineage | Every variable traceable to evidence | Mandatory |
| Fingerprint consistency | All replay roots verified | Mandatory |
| Constitutional compliance | Model conforms to CWMS constitution | Mandatory |
| Resource bounds | Prediction computation within defined limits | Advisory |

**Outcome**: `certificate.operational = :pass | :fail`

---

## 3. Certificate Structure

```elixir
defmodule TiannaraRuntime.CertificateIssuer.ModelCertificate do
  defstruct [
    :certificate_id,       # SHA-256
    :model_id,
    :model_version,
    :tier,                 # :mathematical | :validation | :operational
    :status,               # :pass | :fail | :pending
    :checks,               # [CertificationCheck.t]
    :summary,              # %{pass: int, fail: int, total: int}
    :fingerprint,          # of this certificate
    :issued_at,            # ISO-8601
    :issued_by,            # :self | :auditor
    :supersedes            # certificate_id or nil
  ]
end
```

---

## 4. Certificate Lifecycle

```
Certificate Issued (Tier 1)
    │
    ▼
Certificate Issued (Tier 2)
    │
    ▼
Certificate Issued (Tier 3) ─── Model is :operational
    │
    ├── Model updated (new version)
    │   └── All tiers re-certified
    │
    ├── Evidence refreshed
    │   └── Tiers 2, 3 re-certified
    │
    └── Model deprecated
        └── Certificates archived
```

---

## 5. Certificate Archive

All certificates, past and present, are stored in the Certificate Archive:

```elixir
defmodule TiannaraRuntime.CertificateIssuer.Archive do
  use TiannaraRuntime.Archaeology.Artifact

  defstruct [
    :archive_id,
    :model_id,
    :certificates,   # [ModelCertificate.t, ...]
    :current_version,
    :archive_root    # Merkle root of all certificate fingerprints
  ]
end
```

The archive can be queried for any model's full certification history:

```elixir
def get_history(model_id) :: [ModelCertificate.t()]
def get_active_certificate(model_id) :: ModelCertificate.t() | nil
def verify_chain(model_id) :: {:ok, CertificateChain.t()} | {:error, String.t()}
```

---

## 6. Certificate Revocation

A certificate may be revoked in the following cases:

| Reason | Description | Recovery |
|--------|-------------|----------|
| Evidence contradiction | New evidence contradicts model predictions | Re-estimate and re-certify |
| Mathematical flaw | ProofEngine detects inconsistency | Fix and re-certify from Tier 1 |
| Replay failure | Model fails deterministic replay | Debug and re-certify |
| Constitutional change | Constitution updated | Re-certify under new constitution |
| Auditor override | Independent audit finds violations | Manual review required |

Revoked certificates are not deleted. They are marked `:revoked` with a revocation reason and timestamp, and remain in the archive.

---

## 7. Certification Orchestration

The certification pipeline is automated:

```elixir
defmodule TiannaraRuntime.CertificateIssuer do
  @callback certify(model :: WorldModel.t(), tier :: atom()) ::
    {:ok, ModelCertificate.t()} | {:error, String.t()}

  @callback certify_all_tiers(model :: WorldModel.t()) ::
    {:ok, [ModelCertificate.t()]} | {:error, String.t()}

  @callback re_certify(model_id :: String.t(), tier :: atom()) ::
    {:ok, ModelCertificate.t()} | {:error, String.t()}

  @callback revoke(certificate_id :: String.t(), reason :: String.t()) ::
    {:ok, ModelCertificate.t()} | {:error, String.t()}

  @callback verify(certificate :: ModelCertificate.t()) ::
    :pass | {:fail, String.t()}
end
```

---

## 8. Integration with Phase 16.X

The certification framework depends on Phase 16.X for:

- **ProofEngine**: Mathematical consistency checks (Tier 1)
- **OptimizationEngine**: Parameter estimation correctness (Tier 1)
- **ValidationRegistry**: Validation metric thresholds (Tier 2)
- **UCC ConstraintEngine**: Constraint checking (all tiers)
- **ObservationRegistry**: Evidence lineage verification (Tier 3)
- **ArchaeologyEngine**: Replay determinism verification (Tier 3)

---

## 9. Integration with Phase 17 Model Pipeline

Certification gates the pipeline:

```
Structure Learning
    │
    ▼
Equation Learning ──► Mathematical Certification ──► ─┐
    │                                                   │
    ▼                                                   │
Parameter Estimation                                    │
    │                                                   │
    ▼                                                   ▼
Model Assembly ──► Validation Certification ──► Operational Certification ──► Deploy
```

No stage output enters the next stage without passing the corresponding certification gate.

---

*This document is Phase 17.0 deliverable. Certification framework subject to constitutional freeze in Phase 17.05.*
