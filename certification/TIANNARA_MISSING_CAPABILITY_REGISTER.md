# Tiannara Missing Capability Register

**Baseline Commit:** 3bd1601b9bb3c718f985d44ceaa8ef2e638d4ec6  
**Timestamp:** 2026-08-25T00:15:00Z  

## 1. Critical Missing Capabilities (P0)

### MC-001
**Capability:** Operational Domain Execution (Physics, Chemistry, etc.)
**Status:** `PLACEHOLDER`
**Evidence:** EVID-0006
**Missing:**
- Executable research loops within domains (currently returning fixed arrays/metrics)
- Actual hypothesis generation logic (currently `{:ok, []}`)
- Simulation logic against real world/mathematics models
**Severity:** P0

### MC-002
**Capability:** Formal Mathematical Proof Kernel
**Status:** `PARTIAL`
**Evidence:** EVID-0001
**Missing:**
- Formal theorem dependency graph
- Pure symbolic proof verification system
- Proof replay and translation across domains
**Severity:** P0

## 2. Major Missing Capabilities (P1)

### MC-003
**Capability:** Dedicated Logic Substrate
**Status:** `MISSING`
**Evidence:** EVID-0002
**Missing:**
- Centralized `Tiannara.Logic` namespace
- Universal inference rule abstraction (currently distributed in BeliefSystems and CausalEngine)
- Contradiction detection abstracted away from specific domains
**Severity:** P1

### MC-004
**Capability:** Phase 16 Autonomous Execution Loop
**Status:** `PARTIAL`
**Evidence:** EVID-0007
**Missing:**
- End-to-end execution of a research loop entirely triggered by the Research Director.
- While planning and prioritization happen, the step that actually "runs" the experiment is stubbed.
**Severity:** P1

---

## REMEDIATION RECOMMENDATION

*Note: The following are architectural proposals and do not affect the certification verdicts above.*

### For MC-001 (Domain Execution)
**Proposed Architecture:** Refactor `Tiannara.Domains.Physics` and `Chemistry` to remove hardcoded metric returns. Introduce a standard `DomainEngine` that subscribes to the Research Director and uses standard `Tiannara.Math.Calculus` or simulation engines to return dynamically computed results.

### For MC-002 & MC-003 (Math/Logic Substrates)
**Proposed Architecture:** Create `lib/tiannara/logic/` and expand `lib/tiannara/math/proof/`. Migrate the inference logic out of `causal_engine.ex` and `belief_systems.ex` into the central logic substrate. Ensure that higher-order systems inject these substrates rather than reimplementing probability or calculus internally.

### For MC-004 (Phase 16)
**Proposed Architecture:** Wire the `ResearchDirector` output directly into the `ExperimentOrchestrator` such that prioritizing an unknown fires a pubsub event that boots a sandbox, runs a domain hypothesis, and records the result in the `DiscoveryLedger`.
