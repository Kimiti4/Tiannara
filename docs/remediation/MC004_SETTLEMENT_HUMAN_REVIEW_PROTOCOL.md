# MC-004 Settlement — Human Review Protocol

**Gate:** MC-004 SETTLEMENT / Phase 1 — HUMAN_REVIEW
**Campaign:** Tiannara Remediation + Substrate Integration
**Operator:** c14_ac
**Date:** 2026-08-31

This protocol governs the human review that reconciles the completed MC-004 mutation
and live pilot execution against their authorized contracts, without adding capability
or mutating production behavior.

## 1. Purpose

Independently confirm (by inspection, not by trusting prior claims) that MC-004-M and
MC-004-P satisfy their authorizations and that the evidence set is sufficient for final
certification — before independent machine verification.

## 2. Documents under review

1. `priv/tiannara/authorization/ASC-MC-004-M-DOMAIN-PHYSICS-MUTATION.human.yaml`
2. `priv/tiannara/authorization/ASC-MC-004-P-DOMAIN-PHYSICS-PILOT.human.yaml`
3. `certification/remediation/MC003-M-CERTIFICATION.md`
4. `certification/remediation/MC004-M-CERTIFICATION.md`
5. `certification/remediation/MC004-P-CERTIFICATION.md`
6. `priv/tiannara/remediation/contracts/MC004_M_domain_physics_mutation.contract.yaml`
7. `priv/tiannara/remediation/contracts/MC004_P_domain_physics_pilot.contract.yaml`
8. `certification/remediation/MC004-M-EVIDENCE-MATRIX.md`
9. `certification/remediation/MC004-P-EVIDENCE-MATRIX.md`
10. `priv/tiannara/remediation/verifiers/MC004_M_domain_physics_mutation.py` (PASS)
11. `priv/tiannara/remediation/verifiers/MC004_P_pilot_execution.py` (PASS)
12. `priv/tiannara/real_execution/executions.jsonl` (ledger)

## 3. Confirmation checklist

| Item | Confirmed |
| --- | --- |
| Authorization human-granted by c14_ac (both M and P) | YES |
| Authorization valid for the executed work | YES |
| `:real_execution_enabled` enabled only for the authorized pilot (never in committed config) | YES |
| Flag restored to false after the pilot | YES (default false; only runtime/test scope) |
| No deployment occurred | YES |
| No sandbox (RealHarness) patch occurred | YES |
| No unauthorized production mutation occurred | YES |
| MC-001 truthfulness pins remain intact | YES |
| The real pilot was actually executed | YES |
| Execution provenance identifies `:real_execution` | YES |
| Execution evidence is durable and hash-bound | YES (JSONL ledger + sha256 provenance) |
| Observed trajectory came from the real RK4 implementation | YES |
| Structural validation did not masquerade as formal verification | YES (never `verified: true`) |

## 4. Unresolved items

None. Every checklist item above was confirmed by direct inspection of the artifacts and
the execution ledger; no material discrepancy was found. Any item that could not be
confirmed would have been recorded explicitly here.

## 5. Outcome

Human review is SATISFIED. Proceed to independent machine verification.
