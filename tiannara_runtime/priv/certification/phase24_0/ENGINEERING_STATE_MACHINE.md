# Engineering State Machine

## Purpose

Architect deterministic state transitions for engineering artifacts. States govern what operations are permitted at each lifecycle stage.

## State Model

```
Draft
    ↓
Proposed
    ↓
Reviewed
    ↓
Validated
    ↓
Approved
    ↓
Certified
    ↓
Frozen
    ↓
Archived
```

## State Properties

| State | Permitted Operations | Immutable |
|-------|---------------------|-----------|
| Draft | Edit, submit for review | No |
| Proposed | Review, return to draft | No |
| Reviewed | Validate, return to proposed | No |
| Validated | Approve, return for revision | No |
| Approved | Certify | No |
| Certified | Freeze | Yes (content) |
| Frozen | Archive | Yes |
| Archived | Read-only | Yes |

## Transition Rules

- Transitions never skip states
- Regression requires constitutional review
- Each transition records rationale
- Transition history is permanently preserved
