# Policy: CERTIFICATION ≠ AUTHORIZATION

**Policy ID:** POL-CERT-AUTH-001
**Status:** ACTIVE
**Authority:** Human operator
**Supersedes:** "Internal certification requires a signed human authorization artifact."

## The Invariant

```text
CERTIFICATION                AUTHORIZATION
"What is true?"              "May we act?"
      │                            │
      ▼                            ▼
evidence/oracle              HUMAN / C14
      │                            │
      ▼                            ▼
CERTIFICATION RECORD         PERMISSIBLE ACTION
```

**Certification determines epistemic status. Authorization determines permissible action.**
A certification record can never grant permission to mutate production, adopt
candidates, change constitutional rules, or act externally.

## New Rule

Internal certification requires **no human authorization**. It requires:
1. An immutable, hash-verified probe contract
2. Real execution (no mocks counting as evidence)
3. Provenance
4. Evidence artifacts with cryptographic hashes
5. Independent oracle/verifier
6. A bounded verdict (epistemic status only)

Human authorization remains **mandatory** for:
- production adoption / mutation
- external side effects (C11)
- constitutional amendments
- privileged capability activation
- irreversible actions
- **bootstrapping / starting / stopping / reconfiguring supervised services**

## The Operational Boundary (critical)

A probe is **certification** (auth-free) iff ALL hold:
- declares an immutable contract before execution
- does NOT mutate production or persistent state
- does NOT start/stop/reconfigure supervised services
- does NOT make external calls
- verdict is bounded to epistemic status (cannot trigger adoption/action)

The moment any of those is violated, the probe is **action** and MUST be refused
by the certification layer and routed through C14 authorization.

## Why This Is Constitutional
- Supports Continuous Self-Evaluation (removes friction from measuring oneself).
- Preserves "Capability must never outpace verification" (bounded verdict).
- Preserves human judgment for all actions (final clause).
- Maintains audit trails via the certification record.

## Honest Limitation (recorded, not hidden)
Certification probes can still cause incidental runtime effects (e.g., a linked
process exiting, as seen in U1/C2). The boundary above controls *intended*
mutations and service bootstrap; incidental effects must be declared in the
contract's `declared_side_effects` field and kept within bounds.
