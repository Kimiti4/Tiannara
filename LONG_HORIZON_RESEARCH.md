# Phase 16.97 — Long-Horizon Research Evolution (Spec)

document_version: 16.06.0

phase: 16

status: Frozen

owner: Constitutional Research Council

depends_on:
  - RESEARCH_RUNTIME_FREEZE.md
  - AUTONOMOUS_RESEARCH_VALIDATION.md
  - INDEPENDENT_RESEARCH_AUDIT.md

supersedes: null

## Purpose
Specify the **long-horizon constitutional validation** for Phase 16 autonomous constitutional research.

This spec ensures the system remains:
- replay-stable over multi-year horizons
- portfolio-diverse (no collapse to a narrow research attractor)
- uncertainty-reducing under evidence-first gates
- archaeologically explainable for each derived decision
- constitutionally compliant under frozen contracts

---

## Constitutional Simulation Principle
Long-horizon research evolution must be simulated as a deterministic replay of research cycles from immutable inputs.

No “live” learning without evidentiary gates:
- if evidence closure fails, downstream integration is fail-closed
- theory integration occurs only via certified paths (later implementation)

---

## Horizon Scenarios (Deterministic)
Define four horizon simulations:

- **H10y** — 10 years
- **H25y** — 25 years
- **H50y** — 50 years
- **H100y** — 100 years

Each horizon scenario must:
- consume immutable ledgers / frozen contracts
- deterministically simulate the autonomous pipeline at the contract level
- produce measurable portfolio and knowledge growth metrics

---

## Metrics (Required Outputs)

### M1 — Knowledge Growth Velocity
- growth of:
  - validated knowledge nodes
  - theory confidence updates
  - resolved knowledge gaps
- report as:
  - total count vs time-step index
  - rate of discovery by category (e.g., observational vs theoretical vs engineering)

### M2 — Unanswered Questions Persistence
- track distribution of:
  - open knowledge gaps
  - unresolved contradictions
  - evidence shortages
- report if growth stagnates or explodes.

### M3 — Discovery Velocity
- measure:
  - number of research programs completed per cycle window
  - success rate by program type (questioning, planning, evidence collection, validation)
- must be computed deterministically from ledgers.

### M4 — Portfolio Diversity
- ensure portfolio diversification:
  - entropy of selected program categories
  - diversity of domain coverage
  - evidence source diversity
- detect collapse into repeated near-duplicates.

### M5 — Theory Convergence / Divergence
- track:
  - number of superseding vs merging theory updates
  - contradiction density over time
- ensure the system resolves contradictions rather than oscillating indefinitely.

### M6 — Engineering Productivity Proxy (Spec Metric)
Phase 16 does not yet do full engineering intelligence, but it must still discover engineering opportunities.

Track proxy metrics:
- count of research outcomes tagged as engineering-impact capable
- count of evidence bundles referencing engineering constraints
- feasibility scores improvement (deterministic proxy)

---

## Replay + Archaeology Coverage Requirements
For every horizon simulation run, the spec requires:

- every autonomous selection decision has:
  - deterministic priority trace
  - lineage proof entry linking to knowledge gap origin
- replay reconstruction must be possible:
  - at stage granularity (question→plan→evidence map)
  - and at program granularity (program inclusion/exclusion)
- archaeology coverage must output:
  - `coverage_complete`
  - `coverage_partial`
  - `coverage_missing` counts per node type

---

## Determinism & Fail-Closed Rules
- Any ambiguity in stage contracts must yield:
  - explicit failure artifacts
  - and no integration
- if evidence closure fails:
  - knowledge integration is prohibited in the simulation ledger trace

---

## Relationship to Acceptance Criteria
This document supports acceptance requirements by proving that over long durations:

- autonomous research decisions remain deterministic and replayable
- research portfolios remain healthy and diverse
- uncertainty reduction continues under evidence-first gating
- knowledge growth improves without uncontrolled drift
- archaeology remains explainable, auditable from immutable artifacts

---

## Frozen Interfaces Appendix

### Frozen Schemas

Observation, Question, Hypothesis, Experiment, Theory, Research Portfolio, Knowledge Gap, Research Certificate

### Frozen APIs

ObservationRegistry, QuestionGenerator, HypothesisEngine, ExperimentPlanner, TheoryEngine, ReplayEngine, KnowledgeGraph, ScientificCapital

### Frozen Behaviors

ObservationBehaviour, HypothesisBehaviour, ExperimentBehaviour, TheoryBehaviour, ReplayBehaviour, CertificateBehaviour

---

## Status
Spec-only: simulation contracts and metrics definitions. No implementation.
