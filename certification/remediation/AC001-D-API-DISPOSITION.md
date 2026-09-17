# AC-001-D3: Legacy API Disposition

**Date:** 2026-08-26
**Gate:** AC-001-D
**Purpose:** Explicit disposition for every legacy registry API

## Registry A APIs (Tiannara.Domains.Registry)

| API | Disposition | Canonical Replacement | Evidence |
|-----|-------------|----------------------|----------|
| `all_domains/0` | REPLACED | `CanonicalRegistry.all/0` | C1 ledger, D1 freeze |
| `domain_names/0` | REPLACED | `CanonicalRegistry.all/0` + name extraction | C1 ledger, D1 freeze |

## Registry B APIs (TiannaraOS.DomainRegistry)

| API | Disposition | Canonical Replacement | Evidence |
|-----|-------------|----------------------|----------|
| `list_all/0` | MIGRATED | `CanonicalRegistry.all/0` (IDs) or `all_records/0` (records) | C1 ledger, 23 sites |
| `get/1` | MIGRATED | `CanonicalRegistry.get/1` | C1 ledger, 3 sites |
| `get_knowledge_capital/1` | NOT_CARRIED_FORWARD | Boundary: `KnowledgeCapitalBoundary.get/1 → nil` | C1 ledger, 10 sites |
| `get_portfolio_vector/1` | NOT_CARRIED_FORWARD | Boundary: `PortfolioBoundary.get/1 → nil` | C1 ledger, 7 sites |
| `add_program/2` | DEAD → RETIRED | None | Zero callers (A0 evidence) |
| `record_activity/3` | DEAD → RETIRED | None | Zero callers (A0 evidence) |
| `get_all_domain_ids/0` | DEAD → RETIRED | None | Zero callers (A0 evidence) |

## Boundary Preservation

| Concept | Status | Boundary Expression |
|---------|--------|-------------------|
| Knowledge capital | EXPLICITLY UNAVAILABLE | `KnowledgeCapitalBoundary.get/1 → nil` |
| Portfolio vectors | EXPLICITLY UNAVAILABLE | `PortfolioBoundary.get/1 → nil` |
| Research metrics | NOT OWNED BY REGISTRY | Separate future capability |

## Dead API Disposition

| API | Callers | Disposition | Rationale |
|-----|---------|-------------|-----------|
| `add_program/2` | 0 | RETIRED | Never called; no migration needed |
| `record_activity/3` | 0 | RETIRED | Never called; no migration needed |
| `get_all_domain_ids/0` | 0 | RETIRED | Never called; no migration needed |

## Ontology Invariant

The frozen 20-domain ontology is UNCHANGED by D:
engineering, physics, chemistry, medicine, cybernetics, governance,
computation, agriculture, energy, logistics, cognition, materials,
robotics, economics, philosophy, sociology, linguistics, aerospace,
ecology, architecture.

Exclusions remain: :science (methodology), :mathematics (substrate),
:logic (substrate), :cs (merged into :computation).
