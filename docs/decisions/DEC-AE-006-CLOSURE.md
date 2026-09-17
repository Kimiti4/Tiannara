# Decision: AE-006 Closure & Blocker Map Update

**Decision ID:** DEC-AE-006-CLOSURE
**Timestamp:** 2026-08-21
**Authority:** Human operator (via ASC-AE-006-ADOPTION.human.yaml)
**Status:** CLOSED (ADOPTED)

## Resolution
F8 (lineage retrieval DETS continuation leak) is remediated and adopted.
`ExecutiveMemory.get_lineage/1` and `find_lessons/1` now use `:dets.foldl`
with `try/catch → {:error, :lineage_unavailable}`, eliminating the
`Protocol.UndefinedError ({:continue})` crash.

## Epistemic Property Preserved
The fix maintains the U8 Recovery Honesty distinction:
- `[]` = genuinely empty lineage (absence of lineage)
- `{:error, :lineage_unavailable}` = retrieval failed / storage corrupted
  (absence of history — explicitly reported, never masked)

## Updated Blocker Map
| Finding | Status | Notes |
|---------|--------|-------|
| F8  | ✅ REMEDIATED + ADOPTED | Regression coverage pending |
| F10 | ✅ REMEDIATED + ADOPTED | Regression coverage pending |
| F12 | ✅ REMEDIATED + ADOPTED | Regression coverage pending |
| F9  | ✅ RESOLVED via F12      | Regression coverage pending |
| F11 | 🔴 OPEN / ARCHITECTURAL | CIS production residency — NEXT |
| F13 | 🟠 OPEN                 | Discovery supervisor lifecycle — AFTER F11 |
| CEL-1 | ⏸️ DEFERRED           | Dynamic delegation — AFTER F13 |

## Next Mission
ASC-AE-007 — F11 CIS Production Residency (production topology mission).
