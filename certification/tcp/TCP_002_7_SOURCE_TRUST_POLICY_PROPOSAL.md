# TCP-002.7 Source-Trust Policy Proposal

**Status:** PROPOSED — not ratified  
**Policy version:** `efdi-source-trust-v1-proposal`  
**Finding:** TCP-B-066  
**Author:** TCP-002.7 implementation  
**Ratification authority:** Constitutional Council (human/constitutional approval required)

## 1. Purpose

This document proposes a source-trust policy for forecast outcome evidence. It is a
**proposal only**. It has not been ratified and must not be treated as an active
policy until the appropriate human/constitutional authority approves it.

Until ratification, the implementation enforces fail-closed behaviour: real
evidence with `:verified_with_limited_source_assurance` is refused for
resolution (`:source_trust_policy_not_ratified`).

## 2. Source classes

| Class | Description | Examples |
|---|---|---|
| `:authoritative_primary` | The publisher is the authoritative source for the event. | Government statistical agency, official exchange, primary sensor network. |
| `:authoritative_secondary` | A trusted aggregator or mirror of a primary source. | Licensed data vendor, official mirror. |
| `:community` | Community-contributed or crowdsourced data. | OpenStreetMap, community reports. |
| `:unverified` | Source identity is declared but not established. | Anonymous API, unauthenticated feed. |

## 3. Outcome classes

| Class | Description | Criticality |
|---|---|---|
| `:observational` | Outcome is a directly observable fact. | Low |
| `:financial` | Outcome involves monetary values. | High |
| `:safety_critical` | Outcome affects safety or health. | Critical |
| `:regulatory` | Outcome affects regulatory compliance. | Critical |

## 4. Required assurance per (source class, outcome class)

| Source class | Observational | Financial | Safety-critical | Regulatory |
|---|---|---|---|---|
| `:authoritative_primary` | Limited assurance acceptable | Limited assurance acceptable | Verified required | Verified required |
| `:authoritative_secondary` | Limited assurance acceptable | Verified required | Verified required | Verified required |
| `:community` | Review required | Review required | Rejected | Rejected |
| `:unverified` | Rejected | Rejected | Rejected | Rejected |

Where:
- **Limited assurance** = `:verified_with_limited_source_assurance` (integrity + semantics + temporal, but publisher authenticity not established).
- **Verified** = `:verified` (all dimensions including publisher authenticity).
- **Review required** = `:requires_review`.
- **Rejected** = `:rejected`.

## 5. Identity assurance

Source identity must be established to the level required by the outcome class.
For `:authoritative_primary` and `:authoritative_secondary`, identity must be
verifiable through a documented, auditable mechanism (e.g., API key, TLS
certificate, published signing key).

For `:community` and `:unverified`, identity is declared only.

## 6. Transport protection

Transport protection (TLS or equivalent) is required for all remote sources.
A connection without transport protection is refused regardless of source class.

## 7. Publisher authenticity

Publisher authenticity is established only when the source provides a
cryptographic signature or equivalent attestation that Tiannara can verify
independently.

For sources without publisher signatures, `publisher_authenticity` remains
`:not_established` and the overall status is `:verified_with_limited_source_assurance`.

## 8. Evidence integrity

Raw evidence bytes must match their recorded SHA-256 digest. A mismatch is a
`:rejected` verdict.

## 9. Semantic verification

The independently parsed evidence value must equal the bound observation's
`observed_outcome`. A disagreement is `:rejected`.

## 10. Temporal eligibility

The event timestamp must fall within the registered typed horizon. The
publication timestamp must satisfy the registered publication policy.

## 11. Corroboration

For `:safety_critical` and `:regulatory` outcomes, independent corroboration
from a second source is required. For `:observational` and `:financial`
outcomes, corroboration is optional.

## 12. Freshness and publication lag

Evidence must be published within the registered horizon's publication policy.
Evidence published after the horizon's end is refused under `:closed` policy.

## 13. Acceptable evidence schemas

Evidence must conform to a versioned schema. The schema version is recorded in
the observation. Unknown schema versions are refused.

## 14. Failure and revocation behaviour

- A source that fails verification is recorded as `:rejected` or
  `:requires_review`.
- A source that becomes unavailable is recorded as `:unavailable`.
- A previously verified source that is later found to be unreliable must be
  revoked through the governance mechanism, not silently downgraded.
- Revocation does not alter historical records; it prevents future use.

## 15. Required assurance for each permitted resolution class

A resolution is permitted only when the overall verification status meets the
minimum required by the source class and outcome class (from the table in §4).

## 16. Human-review requirements

- `:authoritative_primary` + `:observational` or `:financial`: no human review required.
- `:authoritative_secondary` + `:financial`: human review required.
- `:community` (any outcome): human review required.
- `:safety_critical` or `:regulatory` (any source): human review required.
- Any resolution with `:requires_review` status: human review required.

## 17. Policy versioning and amendment procedure

- Policy versions are immutable once published.
- Amendments create new versions, not modifications.
- Ratification follows the existing constitutional authority mechanism.
- The active policy version is recorded in every verification record and
  resolution.

## 18. Ratification status

**PROPOSED — NOT RATIFIED**

This policy has not been approved by the authorized human/constitutional
process. It is a proposal only. Until ratification, the implementation
enforces fail-closed behaviour: real evidence with
`:verified_with_limited_source_assurance` is refused for resolution.

## 19. Implementation note

The current implementation (`OutcomeResolution.validate_source_trust_policy/2`)
blocks real resolutions with limited source assurance. This is correct
behaviour until a policy is ratified.

The policy's ratification reference, once approved, must be recorded in the
durable resolution event.
