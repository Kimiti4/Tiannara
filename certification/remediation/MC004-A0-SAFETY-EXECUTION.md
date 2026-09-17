# MC-004-A0 — Safety & Execution

**Gate:** MC-004-A0 (Reconciliation) — **Date:** 2026-08-31 — **Mode:** READ-ONLY

## 1. Execution-safety of physics paths (does the path gate, sandbox, bound, timeout, audit?)

| Path | Authn/Authz | Sandbox | Resource bound | Timeout/Cancel | Audit trail | Classification |
|---|---|---|---|---|---|---|
| `Domains.Physics.simulate/2` (physics.ex:17) | NONE | NONE | NONE | NONE | NONE | **UNGATED** |
| `Domains.Physics.validate/1` (physics.ex:28) | NONE | NONE | NONE | NONE | NONE | **UNGATED** |
| `Domains.Physics.evaluate/1` (physics.ex:12) | NONE | NONE | NONE | NONE | NONE | **UNGATED** (low risk: pure Bayes) |
| OPC subsystem callbacks (opc.ex:472-475) | NONE | NONE | NONE | NONE | ETS state only | **UNGATED, THEATRICAL** |
| IRD coordination (ird.ex:595) | NONE | NONE | NONE | NONE | ETS state only | **UNGATED, THEATRICAL** |
| TWP predictions (twp.ex:337-340) | NONE | NONE | NONE | NONE | ETS state only | **UNGATED, THEATRICAL** |

## 2. Exposure analysis

- Today: **no live caller** reaches these paths. ADE is dead (`autonomous_discovery.ex:15`); dashboards read metadata only; `ResearchDirector` registry is empty. Effective risk exposure is LOW, **purely because nothing invokes the surfaces**.
- Latent risk: the surfaces are **completely unprotected**. If ADE (or any future consumer) were wired without gating, `simulate` would execute ungated, unsandboxed, unlimited, un-audited, and its validation would run ungated too. Under real execution this becomes a HIGH-critically vector.
- The theatrical subsystem is supervised (`physics/supervisor.ex`) and stateful: any process crash risk is contained by OTP, but numbers it emits are unreliable and could poison any future consumer that assumes capability.

## 3. Execution-reality summary

- Physics performs **no execution** (no side effect, no I/O, no subprocess, no deployment) anywhere in the audited paths — consistent with the MC-003-A0 execution-reality rules.
- "Completion" of a physics operation is solely a function return. For `simulate`/`validate` it is a truthful error; for subsystem calls it is theater.
- The MC-003-M gate left `:real_execution_enabled` **FALSE**; Phase4 gateway requires that flag plus authorization. Physics has no bridge to that gateway regardless.

## 4. Safety classification

| Dimension | Verdict |
|---|---|
| Operating risk today | LOW (dead/disconnected) |
| Latent risk if wired | HIGH (ungated, unsandboxed, un-audited) |
| Execution capability | NONE (no side effects; truthful errors) |
| Isolation from real world | GOOD (fully disconnected from Phase4/RealExecution) |
| Fabrication risk | MEDIUM (subsystem theater is supervised; must not be consumed before decommission) |

## 5. Safety requirements for MC-004-M / MC-004-P (recommendations only)

1. Route any physics execution through the Phase4 gated gateway (`submit_experiment`) with `:real_execution_enabled` still FALSE until MC-004-P authorization.
2. If a physics computation path becomes live, wrap it with timeout + resource bounds; physics callbacks are pure functions so a bounded-time wrapper is trivial.
3. Require provenance attachment before ANY physics result is allowed to feed knowledge/integration (closing the step-8 gap).
4. Decommission/quarantine theatrical subsystem outputs before any consumer wiring so fabricated numbers can never reach decisions.
5. Never wire ADE's hardcoded gravity/time_dilation placeholder (`autonomous_discovery.ex:68`) as-is; use the pilot experiment spec instead.