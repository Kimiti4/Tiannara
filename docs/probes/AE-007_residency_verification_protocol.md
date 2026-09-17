# AE-007 Phase C: CIS Production Residency Verification Protocol

## Objective
Prove that CIS.Supervisor is genuinely resident in the canonical production
supervision tree and behaves constitutionally, WITHOUT regressing F12/F9
observability or corrupting C2/C3 continuity.

## Precondition
Baseline (Phase A) must confirm `whereis(CIS.Supervisor) -> nil` before the
candidate topology is applied. If CIS is already present, F11 is misdiagnosed
and the mission halts for re-characterization.

---

## Group 1: Residency & Topology (Criteria 1, 2, 3)

### T1 — Residency
**Action:** Canonical production boot → `whereis(CIS.Supervisor)`.
**Pass:** Returns a live PID.
**Fail:** Returns `nil` (candidate did not actually insert CIS).

### T2 — Supervision Parentage
**Action:** Inspect the parent supervisor's child specs.
**Pass:** CIS.Supervisor appears as a child of the INTENDED production parent
(e.g., CEL Kernel Supervisor or the designated service supervisor), not an
ad-hoc or test parent.
**Fail:** CIS.Supervisor is orphaned, under a test harness, or under the wrong parent.

### T3 — Restart Semantics
**Action:** `Supervisor.terminate_child(parent, CIS.Supervisor)` → observe restart.
**Pass:** Supervisor restarts CIS.Supervisor per its restart spec (`:permanent`
or `:transient` as designed), within bounded restart intensity.
**Fail:** CIS.Supervisor does not restart, or restarts in an unbounded loop.

---

## Group 2: Implementation Fidelity (Criterion 4)

### T4 — Grounded Risk Implementation
**Action:** Inspect the live CIS risk-assessment call path.
**Pass:** CIS calls the grounded `assess_risk/1` (telemetry-weighted +
quarantine). `nil`/missing telemetry → `{:unknown, :insufficient_evidence}`.
**Fail:** Any `:rand.uniform` or stochastic path is reachable from CIS.
*This is a hard F10 regression gate.*

---

## Group 3: Constitutional Behavior (Criteria 5, 6)

### T5 — Fault Detection Without C14 Bypass
**Action:** Inject a bounded fault (e.g., terminate a non-critical test service).
**Pass:** CIS detects the fault, classifies it, and any consequential action
requires C14 authorization. No autonomous bypass.
**Fail:** CIS takes corrective production action without C14, or fails to detect.

### T6 — Bounded Recovery
**Action:** Observe CIS's response to the injected fault.
**Pass:** CIS emits recovery PROPOSALS (log-only or gated), not autonomous
production mutations.
**Fail:** CIS mutates production state directly.

---

## Group 4: Isolation & Continuity (Criterion 7)

### T7 — Continuity Isolation
**Action:** Kill CIS.Supervisor; inspect C2 (UnifiedRealityGraph) and C3
(Knowledge) state before and after.
**Pass:** C2 canonical state and C3 knowledge/lineage are intact and unchanged
by CIS's failure/restart.
**Fail:** CIS failure corrupts, clears, or shadows C2/C3 state.

---

## Group 5: Telemetry Integrity / Regression (Criteria 8, 9)

### T8 — EOS Accuracy
**Action:** Healthy canonical boot → parse EOS health report.
**Pass:** All live services (including CIS.Supervisor) classified healthy.
`failed_critical = []`.
**Fail:** Any live service misclassified as failed/emergency.

### T9 — F12/F9 Regression (HARD GATE)
**Action:** Healthy canonical boot → query `EventStore.healthy?/0`,
`ExecutiveMemory.health/0`, EOS runtime status.
**Pass:** `healthy? = true`, `health = :healthy`, no false emergency.
**Fail:** Any return to `false`/`:unhealthy`/`:emergency` on a healthy topology.
*If T9 fails, the candidate is REJECTED regardless of T1–T8. Integrating the
telemetry-consuming subsystem must not reintroduce the telemetry defect.*

---

## Verdict Rules
- **PASS:** All of T1–T9 pass.
- **PARTIAL:** T1–T8 pass but T9 fails → REJECT (regression guard).
- **FAIL:** Any of T1–T8 fails → candidate does not establish residency.

## Regression Note (F13 Boundary)
This mission MUST NOT modify `discovery_supervisor`. If applying the candidate
topology changes discovery_supervisor's observed state (currently `:degraded`
per F13), record it as a NEW FINDING — do not silently fix it. F13 is a
separate mission (AE-008).
