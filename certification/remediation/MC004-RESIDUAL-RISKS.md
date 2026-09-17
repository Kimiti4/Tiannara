# MC-004 Residual Risk / Deferred Capability Register

**Gate:** MC-004 SETTLEMENT / Phase 4 — campaign settlement
**Campaign:** Tiannara Remediation + Substrate Integration
**Date:** 2026-08-31

This register records residual risks and deferred capabilities explicitly. It does not
conflate "implemented", "exercised", "validated", "formally proven", or "deployed".

## Residual risks

| ID | Risk | Severity | Mitigation / status |
| --- | --- | --- | --- |
| RR-1 | RK4 is not formally error-bounded; results are validated against analytic pins only | Medium | Structural checks + analytic test pins; formal verification explicitly out of scope (MC-001) |
| RR-2 | Large-dt / stiff configurations can hit `:non_finite_state` truthfully, not adaptively | Low | Solver returns honest error rather than a confident wrong answer; bounded to supported `:first_order_system` specs |
| RR-3 | OPC/NDE/IRD/TWP engine submodules remain dormant servers (no callers) | Low | Documented technical debt; surfaces quarantined to `:physics_substrate_unavailable`; not decommissioned |
| RR-4 | Full one-shot repository test suite cannot run on this machine (>30 min) | Low (env) | Recorded per-directory targeted suites; ENVIRONMENT_BLOCKED, not PASS |
| RR-5 | Pre-existing corpus failures (`:already_started`, dead constitutional probes, ASC races) | Low (untouched) | Tracked in MC-003-M matrix; not introduced by MC-004 |
| RR-6 | `:real_execution_enabled` is an application-env flag; a future operator must not leave it true | Low | Defaults false; set true only within authorized gate/test scope; documented |
| RR-7 | Simulation-only provenance (`:simulation`) could be mistaken for `:real_execution` outside the pilot path | Low | Distinct kinds; `:real_execution` only emitted by the two gated providers |

## Deferred capabilities (NOT established)

| Capability | Status |
| --- | --- |
| Formal mathematical proof of solver correctness | NOT PROVIDED (explicitly unavailable) |
| Unrestricted autonomous physics experimentation | NOT ESTABLISHED (single bounded pilot only) |
| General scientific discovery from the pilot | NOT ESTABLISHED |
| Production deployment of any physics capability | NOT PERFORMED (deployment separately gated) |
| Adaptive/stiff-integration or multi-domain physics | NOT IMPLEMENTED |
| Formal verification revival | NOT PERFORMED (MC-001 pin, per contract) |

## Capability-state distinction (explicit)

| State | MC-004 status |
| --- | --- |
| Capability implemented | Real bounded RK4 + physics domain wiring: YES |
| Capability exercised | Single authorized pilot executed: YES |
| Capability validated | Structural checks + analytic pins: YES |
| Capability formally proven | NO |
| Capability deployed | NO |

## Campaign close

The **R0 → AC-001 → MC-001 → MC-002 → MC-003 → MC-004** remediation sequence now has an
evidence-backed settlement record rather than merely a collection of implementation claims.
Residual risks above are the honest remainder; no risk is silently converted to an all-clear.
