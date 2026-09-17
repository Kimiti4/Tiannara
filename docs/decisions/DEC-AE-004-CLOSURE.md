# Decision: AE-004 Closure & F13 Registration

**Decision ID:** DEC-AE-004-CLOSURE
**Timestamp:** 2026-08-21
**Authority:** Human operator (via ASC-AE-004-ADOPTION.human.yaml)
**Status:** CLOSED (ADOPTED)

## Resolution
The F12 (stale DETS health contract) and F9 (false EOS emergency) defects have been successfully remediated, adopted into production, and verified under full boot.

### Evidence of Resolution
- `EventStore.healthy?/0` and `ExecutiveMemory.health/0` now correctly report `true`/`:healthy` on a healthy topology.
- EOS boot report no longer classifies live services as `failed`/`emergency`.
- The "silence the alarm" anti-fix was avoided: sensitivity to genuine faults is preserved.

## New Finding Registered: F13
**Status:** OPEN / DIAGNOSIS REQUIRED
**Description:** `discovery_supervisor` reports `:degraded` due to a nested `already_started` condition. 
**Context:** This fault was previously masked by the global F9 false emergency. With F9 resolved, F13 is now honestly classified as a medium-severity localized degradation rather than a critical system failure.
**Disposition:** Deferred to P3 (post-F10, F8, F11). Do not patch blindly; determine if this is a topology defect, an expected nested-start condition, or another stale lifecycle contract.
