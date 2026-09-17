# AE-009 Investigation Protocol: DiscoveryMetrics Lifecycle

## Objective
Establish WHY DiscoveryMetrics fails to start, and whether it is REQUIRED or
INTENTIONALLY OPTIONAL — from design-intent evidence, not convenience.

## Golden Rules
- Read-only. No patches, no contract changes, no forced healthy.
- The required/optional verdict must cite evidence of INTENT.
- "Optional because easier" is a constitutional violation.

---

## Phase A — Failure Mechanics

| Probe | What to capture |
|-------|-----------------|
| `start_child` result | `{:error, reason}` / `:ignore` / `{:error, {:already_started, pid}}` |
| Registration | `whereis(DiscoveryMetrics)` → pid or nil |
| Init crash | Crash reason from logs/sasl if it dies after start |
| Restart spec | `:permanent` / `:transient` / `:temporary` |
| Restart intensity | Did the supervisor hit `max_restarts` and stop retrying? |

**Interpretation:**
- `{:error, {:already_started, pid}}` + `whereis → nil` → started unregistered
  elsewhere, OR crashed immediately after start. Investigate both.
- `{:error, {:bad_dependency, _}}` or init crash → dependency problem (Phase B).
- `:ignore` → child deliberately refused; check its own init guard.
- Crash-loop + supervisor gave up → restart-intensity exhaustion.

## Phase B — Dependency & Ordering

| Probe | What to capture |
|-------|-----------------|
| Init dependencies | Services / DETS / ETS / config DiscoveryMetrics needs |
| Dependency availability | Is each dependency UP at DiscoveryMetrics start time? |
| Boot order | Where DiscoveryMetrics starts relative to its dependencies |
| Recent-change impact | Did AE-004 (health) or AE-007 (CIS) alter a dependency? |

**Interpretation:** If DiscoveryMetrics starts BEFORE a dependency is ready,
that is a startup-ordering defect (supports REQUIRED + fixable). If a dependency
was removed/changed, trace the change lineage.

## Phase C — Intent Discovery (the crux)

### Evidence Matrix for Intent Determination

| Evidence | Points to REQUIRED | Points to OPTIONAL |
|----------|:------------------:|:------------------:|
| Design/architecture doc says "must run" | ✓ | |
| Design doc says "best-effort / optional" | | ✓ |
| `@moduledoc` / `@spec` describes core role | ✓ | |
| Components actively consume its output | ✓ | |
| CEL/registry/health uses metrics for decisions | ✓ | |
| NO component consumes its output | | ✓ |
| Absence impairs Discovery's core job | ✓ | |
| Engine/Scheduler fully functional without it | | ✓ |
| Health contract penalizes absence | ✓ (validate!) | — |

### Critical nuance on the health contract
The current contract `[:degraded, [:discovery_metrics]]` penalizes absence.
This LEANS required, but it may itself be the mis-specification. Validate it
against design intent and actual consumers before trusting it:
- If consumers exist and docs say required → contract is CORRECT; startup is broken.
- If nothing consumes it and docs say best-effort → contract is OVER-STRICT;
  the contract (not the startup) is the error.

### Verdict Rules
- **A — REQUIRED:** design intent says must-run AND consumers exist AND
  (engine/scheduler or downstream) depend on metrics. → remediate startup.
- **B — OPTIONAL:** design intent says best-effort AND no hard dependents AND
  absence does not impair core function. → formalize contract for absence.
- **C — INSUFFICIENT_EVIDENCE:** intent cannot be established. → record UNKNOWN,
  escalate for explicit human design decision. Do NOT default to B for convenience.

## Deliverable
`ASC-AE-009_VERDICT.md` — records:
1. Phase A failure mechanics (start_child result, crash reason, restart state).
2. Phase B dependency/ordering findings.
3. Phase C evidence matrix filled with citations (docs, consumers, contract).
4. Verdict (A / B / C) with the design-intent evidence that justifies it.
5. The authorized next step (ASC-AE-010 remediation OR formalization OR escalation).
