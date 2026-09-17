# Governance Patterns

| ID | Pattern | Preconditions | Transition | Recovery/exit |
|---|---|---|---|---|
| GP-001 | Safety override | Verified safety invariant breach | Pause affected transitions and record authority/proof | Independent review and explicit resume event |
| GP-002 | Gradual migration | Frozen contract must evolve | Run versioned readers and dual-write verified formats | Cut over after replay roots agree |
| GP-003 | Evidence quarantine | Provenance or integrity check fails | Isolate claim and descendants | Restore from verified source or archive as invalid |
| GP-004 | Theory competition | Multiple hypotheses explain an observation | Allocate matched experiments using preregistered criteria | Promote, retain, or refute by evidence |
| GP-005 | Contradiction escalation | Valid evidence conflicts with an active theory | Preserve both chains and open a revision | Resolve by replication or narrow theory scope |
| GP-006 | Archaeological recovery | Current policy fails or repeats known conditions | Query immutable historical strata | Reuse only after present-context validation |

Patterns are templates, not automatic authorization. Every use must emit provenance and be replayable.
