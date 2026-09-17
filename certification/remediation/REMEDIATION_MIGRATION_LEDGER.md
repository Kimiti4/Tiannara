# Remediation Migration Ledger

Campaign: Remediation + Substrate Integration
Generated: 2026-08-25
Purpose: track every production mutation, its justification, and its verification status.

---

## R0 — Evidence Truth / Fabricated Result Quarantine ✅ CERTIFIED

**Authorization:** `priv/tiannara/authorization/ASC-R0.human.yaml`

### Mutation 1 (R0-A): Provenance schema

| Detail | Value |
|---|---|
| File created | `lib/tiannara/evidence/provenance.ex` |
| Class | ADDITIVE — no existing behavior changed |
| Justification | All scientific artifacts must carry explicit, auditable provenance |
| Verification | `test/tiannara/evidence/r0_test.exs` R0-A section (9 tests) |

### Mutation 2 (R0-A): Certification gate

| Detail | Value |
|---|---|
| File created | `lib/tiannara/evidence/certification_gate.ex` |
| Class | ADDITIVE — new enforcement layer |
| Justification | Downstream discovery/research must reject fabricated evidence |
| Verification | `test/tiannara/evidence/r0_test.exs` R0-C section (8 tests) |

### Mutation 3 (R0-A): Historical quarantine

| Detail | Value |
|---|---|
| File created | `lib/tiannara/evidence/historical_quarantine.ex` |
| Class | ADDITIVE — dry_run scanner for existing fabricated records |
| Justification | Legacy fabricated records must never be treated as certified knowledge |
| Verification | `test/tiannara/evidence/r0_test.exs` R0-D section (1 test) |

### Mutation 4 (R0-A): Observational heartbeat

| Detail | Value |
|---|---|
| File created | `lib/tiannara/research/heartbeat.ex` |
| Class | ADDITIVE — replaces behavioral contract without modifying existing code |
| Justification | Heartbeat must observe, not fabricate; carries unknown provenance |
| Verification | `test/tiannara/evidence/r0_test.exs` R0-B section (4 tests) |

### Mutation 5 (R0-B): Fabricated executor quarantine

| Detail | Value |
|---|---|
| File modified | `lib/tiannara/research/research_director.ex` |
| Lines removed | 173–185 (`execute_experiment/1`) |
| Lines changed | 152–171 → quarantine path; 119–123 init includes `total_quarantined: 0` |
| Class | BEHAVIOR_CHANGE — fabricated path deleted |
| Justification | Function fabricated random observations and fed them into evidence-integration pipeline |
| Verification | `test/research/r0_quarantine_test.exs` AT1, AT2 |

### Mutation 6 (R0-C/D): Execution-mode provenance guard

| Detail | Value |
|---|---|
| File modified | `lib/tiannara/research/knowledge_integrator.ex` |
| Change | `integrate/3` gains `execution_mode` option; two sequential guards (execution_mode == `:real_execution`, confidence ≥ threshold); `handle_continue :quarantine_historical`; `real_knowledge/1` API |
| Class | BEHAVIOR_CHANGE + DATA_MIGRATION |
| Justification | All knowledge must carry execution provenance; only real-execution evidence qualifies; historical records tagged |
| Verification | `knowledge_integrator_test.exs` tests; `r0_quarantine_test.exs` AT3–AT4b, AT5 |

---

## AC-001-A — Canonical Identity Registry 🟢 PENDING CERTIFICATION

**Authorization:** `priv/tiannara/authorization/ASC-AC-001-A-CANONICAL-REGISTRY.human.yaml`

### Mutation 1 (AC-001-A): Canonical domain registry

| Detail | Value |
|---|---|
| File created | `lib/tiannara/domains/canonical_registry.ex` |
| Class | ADDITIVE — new GenServer, no existing code modified |
| Justification | Establish authoritative 20-domain ontology as foundation for MC-001/MC-002/MC-003/MC-004 |
| Scope | Identity layer only: domain ID, metadata, module binding, lifecycle, ontology version |
| Frozen ontology | 20 domains (engineering, physics, chemistry, medicine, cybernetics, governance, computation, agriculture, energy, logistics, cognition, materials, robotics, economics, philosophy, sociology, linguistics, aerospace, ecology, architecture) |
| Excluded | :science (methodology), :mathematics (substrate), :logic (substrate), :cs (merged into :computation) |
| Dead APIs NOT carried forward | add_program/2, record_activity/3, get_all_domain_ids/0, get_knowledge_capital/1, get_portfolio_vector/1 |
| Verification | `test/tiannara/domains/canonical_registry_test.exs` — 22 tests, 0 failures |

### Not yet certified (pending human review)
- AC-001-A is ADDITIVE only — no supervision, consumer migration, or legacy deprecation claimed
- Existing test suite: 87 tests, 4 failures (all pre-existing in DomainProjectionTest — tests undefined legacy APIs)

---

## AC-001-B — Supervision Tree Integration 🟢 PENDING CERTIFICATION

**Authorization:** `priv/tiannara/authorization/ASC-AC-001-B-SUPERVISION.human.yaml`

### Mutation 1 (AC-001-B): Add registry to supervision tree

| Detail | Value |
|---|---|
| File modified | `lib/tiannara/application.ex` |
| Change | Added `Tiannara.Domains.CanonicalRegistry` to `core_children/0` list (after Core subsystem supervisors, before Sentinel) |
| Class | BEHAVIOR_CHANGE — registry now starts at application boot |
| Justification | Registry must be a supervised runtime component, not just code that exists |
| Verification | `test/tiannara/domains/canonical_registry_supervision_test.exs` — 6 tests, 0 failures |

### Evidence
- Application starts successfully with registry in supervision tree
- Registry process is alive after boot
- Registry restarts automatically if killed (OTP supervisor semantics)
- Registry remains queryable after restart
- Registry state is reinitialized after restart (not preserved across crash)
- 28 canonical registry tests pass (22 identity + 6 supervision)
- Broader suite: 93 tests, 4 failures (all pre-existing DomainProjectionTest — known migration debt)
