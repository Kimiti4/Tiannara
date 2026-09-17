# AC-001 FINAL Authority Closure

**Date:** 2026-08-27

## Sole Authority

Tiannara.Domains.CanonicalRegistry is the SOLE authoritative domain-identity
mechanism. Supervised (application.ex:132), operational, returns exactly 20
canonical domains.

## Legacy Authority Elimination

| Legacy Registry | Status | Authority |
|----------------|--------|-----------|
| Tiannara.Domains.Registry | DEPRECATED | NONE |
| TiannaraOS.DomainRegistry | DEPRECATED | NONE |

Both legacy modules:
- Cannot determine domain identity (raise on identity calls)
- Not supervised
- 0 production consumers
- 0 aliases
- 0 live identity flows

Retained only for migration lineage and historical traceability.

## Dead API Final Disposition

| API | Disposition |
|-----|-------------|
| add_program/2 | RETIRED (zero callers) |
| record_activity/3 | RETIRED (zero callers) |
| get_all_domain_ids/0 | RETIRED (zero callers) |
| get_knowledge_capital/1 | NOT_CARRIED_FORWARD → explicit boundary (nil / {:error, :knowledge_capital_unavailable}) |
| get_portfolio_vector/1 | NOT_CARRIED_FORWARD → explicit boundary (nil / {:error, :portfolio_unavailable}) |
| all_domains/0 | REPLACED → CanonicalRegistry.all/0 |
| domain_names/0 | REPLACED → CanonicalRegistry.all/0 |
| list_all/0 | MIGRATED → CanonicalRegistry.all/0 or all_records/0 |
| get/1 | MIGRATED → CanonicalRegistry.get/1 |

## Boundary Integrity

- `KnowledgeCapitalBoundary.get/1` → `nil` (unavailable)
- `PortfolioBoundary.get/1` → `nil` (unavailable)
- `available?/0` → `false`, `status/0` → `:unavailable` (both)
- No fabricated values ({:ok, 0}, {:ok, 0.0}, {:ok, %{}}) introduced

## Production Reference Scan (final)

References to `Tiannara.Domains.Registry` / `TiannaraOS.DomainRegistry` in
`lib/` are confined to:
- Their own module definitions (deprecation raises — correct)
- Boundary module moduledocs (documentation)
- Two docstring comments (institution_self_model.ex:539, research_strategy_result.ex:42)

**Live production legacy authority references: 0**

## Migration Lineage Preserved

All migration evidence retained in:
- AC001_PREMUTATION_RECONCILIATION.md
- AC001-C-PREMIGRATION-MAP.md
- AC001-C0-SEMANTIC-ANALYSIS.md
- AC001-C1-MIGRATION-LEDGER.md
- AC001-D-MIGRATION-LINEAGE.md
- AC001-D-API-DISPOSITION.md
- AC001-E-ORPHAN-INVENTORY.md
- AC001-E-RECLASSIFICATION-LEDGER.md

## Authority Transfer Record

| Gate | Event | Authority State |
|------|-------|----------------|
| Pre-remediation | Two broken registries | Competing (both non-functional) |
| AC-001-A | CanonicalRegistry created | Three registries |
| AC-001-B | CanonicalRegistry supervised | Canonical operational |
| AC-001-C1 | Consumers migrated (40/40) | Canonical sole consumer-facing |
| AC-001-D | Legacy deprecated | Canonical sole authority |
| AC-001-E | Orphans resolved, ontology closed | Canonical sole authority, ontology final |
| AC-001-FINAL | Closure certified | AUTHORITY CLOSED |
