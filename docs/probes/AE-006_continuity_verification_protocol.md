# AE-006 Phase C: Continuity Verification Protocol

## Objective
Prove that `ExecutiveMemory.get_lineage/1` and `find_lessons/1` can safely traverse large DETS tables without leaking continuation tuples, while preserving the U8 "Recovery Honesty" guarantee.

## Test 1: The Continuation Leak Check
**Action:** 
1. Append 5,000 linked events to the EventStore/DETS to force the table to span multiple internal pages/chunks.
2. Call `ExecutiveMemory.get_lineage(root_event_id)`.
**Baseline Behavior:** Crashes with `Protocol.UndefinedError (Enumerable, value: {:continue, ...})`.
**Candidate Requirement:** Must return a list of exactly 5,000 valid event maps. 
*Failure Condition:* If the output list contains *any* raw `{:continue, _}` tuples, or if it crashes, the test fails.

## Test 2: Recovery Honesty (The U8 Regression Check)
**Action:** 
1. Boot the isolated topology and persist a valid lineage.
2. `Process.exit(dets_pid, :kill)` or artificially corrupt the DETS file header to simulate unrecoverable state.
3. Call `ExecutiveMemory.get_lineage(root_event_id)`.
**Baseline Behavior:** Crashes or returns partial data.
**U8 Honest Behavior:** Returns `{:error, :lineage_unavailable}` (or catches the crash and reports the break).
**Candidate Requirement:** MUST match the U8 Honest Behavior. 
*Critical Failure Condition:* If the candidate "fixes" the crash by silently returning `[]` or a truncated list when the underlying DETS table is actually corrupted/unreadable, the candidate is **REJECTED**. We will not accept a fix that masks data loss as an "empty history."

## Test 3: Find Lessons Parity
**Action:** Run the same traversal tests against `ExecutiveMemory.find_lessons/1`.
**Candidate Requirement:** Must exhibit the exact same safety and honesty properties as `get_lineage/1`.
