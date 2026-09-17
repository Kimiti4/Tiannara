# Tiannara Remediation Matrix

Campaign: Remediation Architecture & Epistemic Foundation Certification (READ-ONLY)
Baseline commit: `3bd1601b9bb3c718f985d44ceaa8ef2e638d4ec6`
ID mapping: this campaign's MC-001..004 differ from the prior register (prior MC-001=Domain, MC-002=Math, MC-003=Logic, MC-004=P16). Mapping recorded in dependency graph; cross-referenced by content.

| Gap | Status | Verdict category | First remediation action | Acceptance test | Key risk |
|---|---|---|---|---|---|
| **R0** (new) — Fabricated-evidence loop live | OPEN-CRITICAL | Epistemic integrity violation in supervision tree | Feature-flag default-off / remove `Research.ResearchDirector.Pipeline.execute_experiment` random path + CEL constant steps from live wiring; purge noise-derived persistent-memory records with provenance audit | P16-AT(e): Loop A unreachable; provenance sweep finds no `:rand` ancestry records | Purge may delete legitimate adjacent records — scope by experiment_id lineage |
| **AC-001** DomainRegistry contradiction | CONFIRMED+EXTENDED | Dual ontology, phantom ids, orphan module, dead mutators, ~14 crash call sites | Adopt canonical 20-set (`-:science -:mathematics +:physics +:chemistry`); unify registries; fix call sites | D-AT-1..3 | Stored-reference migration for old ids |
| **MC-001** Mathematics | RESOLVED AS DISTRIBUTED (B+C+D) | Thin partly-mocked core; 9 entropy dupes; dead Statistics; mock consumed by economics | Consolidate evidenced kernels under `Tiannara.Math`; redirect consumers; delete dead code; make-or-delete nash_equilibrium | M-AT-1..5 | Golden-value capture before dedup deletion |
| **MC-002** Logic | RESOLVED AS DISTRIBUTED-THEATRICAL (B, partial E) | No namespace; sound Contradiction.Engine core; broken BeliefSystem matcher; dangling Graph.Audit ref at constitution/registry.ex:118 | Extract 6-function kernel; delegate/replace all other sites | L-AT-1..5 | Question-stream change in Loop B — shadow-run first |
| **MC-003** Phase16 execution | BREAK AT STAGE 7 | Three executor tiers (fabricated-live / real-narrow / built-dead); UnknownRegistry unstarted; OS director orphaned w/ latent deadlock | After R0: start registry stack (fix deadlock first), wire `submit_experiment`, uncertainty from evidence distributions | P16-AT(a)-(d) | Orchestrator becomes bottleneck — concurrency caps already present (:267-270) |
| **MC-004** Domain execution | UNIVERSAL STUBS | All domains return `{:ok, []}`; observatory shim hardcodes metrics | Physics pilot through orchestrator; replace ASC hardcode list | D-AT-4..5 | Premature activation before R0/AC-001 |

## Cross-cutting findings

| ID | Severity | Finding | Evidence |
|---|---|---|---|
| F-NEW-1 | CRITICAL | Live heartbeat loop persists random-data conclusions into persistent memory | research/research_director.ex:142-171 |
| F-NEW-2 | HIGH | Provenance theater: ledger identity hashes literal string "ScientificCapitalLedger"; two competing ledgers | os/recursive_civilization_runner.ex:352,:725-728; os/kernel/scientific_capital_ledger.ex |
| F-NEW-3 | HIGH | Fully-built resource-validated orchestrator never invoked (`submit_experiment` zero callers) | cel/kernel/service_registry.ex:295 vs repo grep |
| F-NEW-4 | MEDIUM | Uncertainty updates are fixed ±0.1 constants, not evidence-derived | discovery_scheduler.ex:200-204 |
| F-NEW-5 | MEDIUM | Dangling logic call constitution/registry.ex:118 → nonexistent module | direct read |
| F-NEW-6 | LOW | Dead math modules raise compile warnings; latent self-call deadlock in OS ResearchDirector | optimization.ex; os/research_director.ex:377-381 |

## Constraint compliance

- READ-ONLY honored: zero modifications to lib/, tests/, config/, schemas/, registries during this campaign.
- POL-CERT-AUTH-001: no ACTION taken; recommendations only. Production mutation requires future `ASC-*.human.yaml`.
- Verdicts derived from evidence; final recommendation not pre-selected.
