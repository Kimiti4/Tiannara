# Tiannara System Atlas (Phase R0)

Machine-readable architecture atlas for the Tiannara AI platform, built during **Phase R0 — Establish truth**
(read-only discovery) of the Tiannara System Unification and Closure Program.

**Start here:** `../audit/R0_UNIFICATION_REPORT.md` — the report, the deliverables index, and the recommended next batch.

## The seven registers

| Register | Artifact | Contents |
|---|---|---|
| 1 — File and artifact inventory | `file_inventory.csv` · `file_inventory_summary.json` | 207,028 rows: path, language, size, sha256, git state, classification, role, Elixir entry symbol. Every exclusion carries a reason code. |
| 2 — Capability-to-code traceability | `capability_register.csv` (+ per-section `capabilities_*.csv`) | 117 capabilities: evidence state, reconciliation, owner, implementation, entry points, consumers, tests, evidence, competing implementations, confidence. |
| 3 — Dependency views | `deps_code.json` · `deps_runtime.json` · `deps_governance.json` · `deps_build.json` | Code/package, runtime/data-flow, governance/authority, build/deploy. Every edge carries a basis label. |
| 4 — Canonical ownership and duplication | `ownership_duplicates.csv` · `ownership_duplicates.md` | 28 concepts: authoritative implementation, contract, state owner, permitted writers, consumers, competing copies, recommended outcome. |
| 5 — Findings and evidence ledger | `findings_ledger.csv` · `findings_ledger.md` | 130 findings with severity, confidence, evidence, root cause, remediation, acceptance criteria, status, duplicates, and 14 root-cause clusters. |
| 6 — Verification and certification evidence | `baseline.md` · `baseline.json` · `baseline_verification_report.md` | 15 verified claims bound to SHA + 9 explicit non-verifications. |
| 7 — Architecture decisions and exceptions | `decisions_register.md` · `decisions_GOV.md` | 20 decisions (10 governance design questions + 10 ownership proposals) and 6 active exceptions with expiry conditions. |

## Supporting artifacts

- `architecture.md` — Pass-3 reconstruction: entry points, boot/supervision, data ownership, message flows, state transitions, security boundaries, failure recovery, and a 33-row relationship-basis ledger.
- `capability_status_lists.md` — deliverable 7: verified / partially verified / disconnected / planned / missing lists, plus every CONTRADICTED and UNKNOWN capability.
- `spec_discrepancy_report.md` — deliverable 6: all 95 non-MATCHED capabilities grouped by discrepancy type.
- `remediation_backlog.md` — deliverable 8: 7 ordered batches + 5 operator actions with prerequisites, blast radius, and acceptance criteria.
- `target_architecture.md` — deliverable 9: 6 ownership rules, 8 dependency rules, target topology, verification layer, migration path.
- `problems_G.md` — architectural problem detection (§4G): F-ARC-001..025.
- `interfaces_schemas.md` — deliverable 4: interface and schema compatibility.
- `esap/` — **separate repository** inventory for `Kimiti4/autonomous-API-Gen`; never merged with the platform registers.
- `R0_SOURCE_PLAN.txt` — the governing operator instruction, preserved verbatim.

## Rules that govern this atlas

- Unknown is not PASS. Documentation is not implementation. A test definition is not proof a test ran.
- A passing unit test is not proof of end-to-end operation. Simulated success is not runtime evidence.
- Every verification result is bound to an exact revision and artefact hash.
- Every excluded path has a recorded reason. History is superseded with a marker, never erased.
- A code change is not a closed finding; only verification of the acceptance criteria closes it.

**Phase R0 is discovery. No capability in this atlas is certified; no finding is closed; no remediation has begun.**
