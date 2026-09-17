# AC-001-D1: Legacy Registry Freeze Report

**Date:** 2026-08-26
**Campaign:** Tiannara Remediation + Substrate Integration
**Purpose:** Baseline inventory before D2 mutation

## Registry A: Tiannara.Domains.Registry

### Source location
`lib/tiannara/domains/registry.ex` (34 lines → now deprecated stub)

### Known APIs
- `all_domains/0`
- `domain_names/0`

### Current references (production)
- `lib/tiannara/asc/autonomous_discovery.ex:10` — alias (MIGRATED during D2 to CanonicalRegistry)
- `lib/tiannara/asc/autonomous_discovery.ex:48` — `Registry.all_domains()` call (MIGRATED during D2)

After D2 migration: **0 production consumers**

### Current references (test)
**0** — no test files reference Tiannara.Domains.Registry

### Current references (docs/certification — PERMITTED)
- `lib/tiannara/asc/research_bridge.ex:8` — moduledoc comment
- `lib/tiannara/domains/portfolio_boundary.ex:10` — moduledoc comment
- `lib/tiannara/domains/knowledge_capital_boundary.ex:11` — moduledoc comment

## Registry B: TiannaraOS.DomainRegistry

### Source location
`lib/tiannara/os/domain_registry.ex` (360 lines → now deprecated stub)

### Known APIs (historical)
- `list_all/0`
- `get/1`
- `get_knowledge_capital/1`
- `get_portfolio_vector/1`
- `add_program/2`
- `record_activity/3`
- `get_all_domain_ids/0`

### Supervision status
NOT SUPERVISED — confirmed in AC-001-A0

### Current references (production)
**0** — no production consumers after C1 migration

### Current references (test)
**0** — no test files reference TiannaraOS.DomainRegistry

### Current references (docs/certification — PERMITTED)
- `lib/tiannara/os/research_strategy_result.ex:42` — moduledoc comment
- `lib/tiannara/os/institution_self_model.ex:539` — doc comment
- `lib/tiannara/domains/portfolio_boundary.ex:9` — moduledoc comment
- `lib/tiannara/domains/knowledge_capital_boundary.ex:10` — moduledoc comment

## Freeze Verification

- [x] Zero production consumers of Registry A (after D2 migration of autonomous_discovery.ex)
- [x] Zero production consumers of Registry B
- [x] Neither registry is supervised
- [x] Neither registry is started at boot
- [x] All remaining references are historical/certification/documentation only

## Classification Rules

| Reference type | Allowed? | Found |
|----------------|----------|-------|
| Production dependency | ❌ | 0 |
| Runtime domain lookup | ❌ | 0 |
| New consumer | ❌ | 0 |
| Historical migration ledger | ✅ | cert artifacts |
| Deprecation documentation | ✅ | moduledocs |
| Certification evidence | ✅ | ledger files |
| Test explicitly verifying absence | ✅ | 0 (none needed) |
| Archived migration artifact | ✅ | D1 report |
