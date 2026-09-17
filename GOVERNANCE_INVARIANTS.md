# Governance Invariants

These are executable obligations for valid constitutional configurations.

| ID | Invariant | Machine-checkable predicate |
|---|---|---|
| GI-001 | Canonical ownership | Every governed asset resolves to exactly one canonical owner. |
| GI-002 | Provenance | Every ratified decision reaches source evidence through a complete directed path. |
| GI-003 | Evidence before ratification | A ratified claim references at least one validated evidence item. |
| GI-004 | Deterministic replay | Replaying a frozen event sequence produces the recorded state root. |
| GI-005 | Append-only history | Existing ledger entries cannot be mutated or reordered. |
| GI-006 | Explicit uncertainty | Every scientific claim carries confidence and method metadata. |
| GI-007 | Refutation preservation | Refuted and superseded claims remain archaeologically retrievable. |
| GI-008 | Authorization | Every state transition is attributable to an authorized actor or deterministic system rule. |

An invariant is proven only over the enumerated validation domain. Claims over all possible configurations remain open until a formal model and exhaustive proof are supplied.
