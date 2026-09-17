# AC-001-D: Migration Lineage

**Date:** 2026-08-26
**Gate:** AC-001-D
**Purpose:** Complete old → new disposition preserving evolutionary traceability

## Lineage Diagram

```text
Legacy Registry A (Tiannara.Domains.Registry)
│
├── all_domains/0 ────────────────► CanonicalRegistry.all/0
│                                    (returns domain IDs)
│
├── domain_names/0 ───────────────► CanonicalRegistry.all/0
│                                    + metadata.name extraction
│
└── [module authority] ───────────► DEPRECATED (raises on call)


Legacy Registry B (TiannaraOS.DomainRegistry)
│
├── list_all/0 ───────────────────► CanonicalRegistry.all/0 (IDs only)
│                                └► CanonicalRegistry.all_records/0 (records)
│
├── get/1 ────────────────────────► CanonicalRegistry.get/1
│
├── get_knowledge_capital/1 ──────► SEPARATE BOUNDARY
│                                    {:error, :knowledge_capital_unavailable}
│
├── get_portfolio_vector/1 ───────► SEPARATE BOUNDARY
│                                    {:error, :portfolio_unavailable}
│
├── add_program/2 ────────────────► RETIRED (dead, zero callers)
│
├── record_activity/3 ────────────► RETIRED (dead, zero callers)
│
├── get_all_domain_ids/0 ─────────► RETIRED (dead, zero callers)
│
├── [GenServer authority] ────────► RETIRED (was never started)
│
└── [module authority] ───────────► DEPRECATED (raises on call)


Canonical Registry (Tiannara.Domains.CanonicalRegistry)
│
├── all/0 ────────────────────────► Sole authority for domain ID enumeration
├── get/1 ────────────────────────► Sole authority for domain record lookup
├── get_metadata/1 ───────────────► Sole authority for domain metadata
├── get_module/1 ─────────────────► Sole authority for module binding
├── get_lifecycle/1 ──────────────► Sole authority for lifecycle state
├── all_records/0 ────────────────► Sole authority for bulk record access
├── ontology_version/0 ───────────► Sole authority for ontology version
│
├── Knowledge Capital ────────────► NOT OWNED (separate boundary)
├── Portfolio Vectors ────────────► NOT OWNED (separate boundary)
└── Research Metrics ─────────────► NOT OWNED (separate boundary)
```

## Authority Transfer Record

| Date | Event | Authority State |
|------|-------|----------------|
| Pre-remediation | Two registries exist | Competing (both broken) |
| AC-001-A | CanonicalRegistry created | Three registries (canonical + 2 legacy) |
| AC-001-B | CanonicalRegistry supervised | Canonical operational; legacy inert |
| AC-001-C1 | All 40 consumers migrated | Canonical sole consumer-facing authority |
| AC-001-D | Legacy deprecated | Canonical SOLE authority; legacy = historical artifacts |

## Lineage Preservation

All migration evidence preserved in:
- `certification/remediation/AC001-C1-MIGRATION-LEDGER.md`
- `certification/remediation/AC001-C-PREMIGRATION-MAP.md`
- `certification/remediation/AC001-C0-SEMANTIC-ANALYSIS.md`
- `certification/remediation/AC001_PREMUTATION_RECONCILIATION.md`
- `certification/remediation/AC001-D1-LEGACY-FREEZE.md`
- `certification/remediation/AC001-D-API-DISPOSITION.md`
