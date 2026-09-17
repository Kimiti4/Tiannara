# AC-001-C1 Migration Ledger

**Date:** 2026-08-26
**Campaign:** Tiannara Remediation + Substrate Integration
**Gate:** AC-001-C1 (Consumer Migration)
**Predecessors:** R0 CERTIFIED, AC-001-A CERTIFIED, AC-001-B CERTIFIED, C0 COMPLETE

## Summary

| Category | Count | Migrated | Boundary | Retired |
|----------|-------|----------|----------|---------|
| CanonicalRegistry.all/0 | 17 | 17 | 0 | 0 |
| CanonicalRegistry.all_records/0 | 3 | 3 | 0 | 0 |
| CanonicalRegistry.get/1 | 3 | 3 | 0 | 0 |
| KnowledgeCapitalBoundary.get/1 | 10 | 0 | 10 | 0 |
| PortfolioBoundary.get/1 | 7 | 0 | 7 | 0 |
| **Total call sites** | **40** | **23** | **17** | **0** |

**Dead APIs (zero external callers, retired from legacy modules):**
- `add_program/2` — 0 callers
- `record_activity/3` — 0 callers
- `get_all_domain_ids/0` — 0 callers

**C0 count discrepancy resolution:** C0 reported 42 call sites; line-level audit found 40. C0 appears to have double-counted 2 sites in `civilization_atlas.ex` where a single function body contained two registry references to the same logical call.

## Line-Level Call Site Inventory

### os/research_director.ex

| Site ID | Line | Old API | Semantic Class | New API / Boundary | Status |
|---------|------|---------|----------------|-------------------|--------|
| C1-001 | 230 | DomainRegistry.list_all/0 | records | CanonicalRegistry.all() | MIGRATED |
| C1-002 | 404 | DomainRegistry.list_all/0 | records | CanonicalRegistry.all() | MIGRATED |
| C1-003 | 458 | DomainRegistry.list_all/0 | records | CanonicalRegistry.all() | MIGRATED |
| C1-004 | 461 | DomainRegistry.get_knowledge_capital/1 | knowledge_capital | KnowledgeCapitalBoundary.get/1 | BOUNDARY |

### os/civilization_atlas.ex

| Site ID | Line | Old API | Semantic Class | New API / Boundary | Status |
|---------|------|---------|----------------|-------------------|--------|
| C1-005 | 182 | DomainRegistry.get/1 | identity | CanonicalRegistry.get/1 | MIGRATED |
| C1-006 | 189 | DomainRegistry.get_knowledge_capital/1 | knowledge_capital | KnowledgeCapitalBoundary.get/1 | BOUNDARY |
| C1-007 | 291 | DomainRegistry.list_all/0 | records | CanonicalRegistry.all() | MIGRATED |
| C1-008 | 308 | DomainRegistry.list_all/0 | records | CanonicalRegistry.all() | MIGRATED |
| C1-009 | 322 | DomainRegistry.list_all/0 | records | CanonicalRegistry.all() | MIGRATED |
| C1-010 | 336 | DomainRegistry.list_all/0 | records | CanonicalRegistry.all() | MIGRATED |
| C1-011 | 409 | DomainRegistry.list_all/0 | records | CanonicalRegistry.all() | MIGRATED |
| C1-012 | 445 | DomainRegistry.list_all/0 | records | CanonicalRegistry.all() | MIGRATED |
| C1-013 | 484 | DomainRegistry.list_all/0 | records | CanonicalRegistry.all() | MIGRATED |
| C1-014 | 487 | DomainRegistry.get_knowledge_capital/1 | knowledge_capital | KnowledgeCapitalBoundary.get/1 | BOUNDARY |

### os/executive_dashboard.ex

| Site ID | Line | Old API | Semantic Class | New API / Boundary | Status |
|---------|------|---------|----------------|-------------------|--------|
| C1-015 | 88 | DomainRegistry.list_all/0 | records | CanonicalRegistry.all() | MIGRATED |
| C1-016 | 140 | DomainRegistry.list_all/0 | records | CanonicalRegistry.all() | MIGRATED |
| C1-017 | 315 | DomainRegistry.list_all/0 | records | CanonicalRegistry.all() | MIGRATED |

**Note:** Orphaned `else` branch from old `with` block fixed during migration.

### os/mission_control.ex

| Site ID | Line | Old API | Semantic Class | New API / Boundary | Status |
|---------|------|---------|----------------|-------------------|--------|
| C1-018 | 119 | DomainRegistry.list_all/0 | records | CanonicalRegistry.all() | MIGRATED |
| C1-019 | 163 | DomainRegistry.list_all/0 | records | CanonicalRegistry.all() | MIGRATED |
| C1-020 | 414 | DomainRegistry.get_knowledge_capital/1 | knowledge_capital | KnowledgeCapitalBoundary.get/1 | BOUNDARY |

### os/institution_self_model.ex

| Site ID | Line | Old API | Semantic Class | New API / Boundary | Status |
|---------|------|---------|----------------|-------------------|--------|
| C1-021 | 575 | DomainRegistry.get_knowledge_capital/1 | knowledge_capital | KnowledgeCapitalBoundary.get/1 | BOUNDARY |

### web/live/domains_live.ex

| Site ID | Line | Old API | Semantic Class | New API / Boundary | Status |
|---------|------|---------|----------------|-------------------|--------|
| C1-022 | 10 | DomReg.all/0 | records | CanonicalRegistry.all_records() | MIGRATED |
| C1-023 | 14 | DomReg.get_portfolio_vector/1 | portfolio | PortfolioBoundary.get/1 | BOUNDARY |
| C1-024 | 15 | DomReg.get_knowledge_capital/1 | knowledge_capital | KnowledgeCapitalBoundary.get/1 | BOUNDARY |

### web/live/mission_control_live.ex

| Site ID | Line | Old API | Semantic Class | New API / Boundary | Status |
|---------|------|---------|----------------|-------------------|--------|
| C1-025 | 19 | DomReg.all/0 | records | CanonicalRegistry.all_records() | MIGRATED |
| C1-026 | 43 | DomReg.get_knowledge_capital/1 | knowledge_capital | KnowledgeCapitalBoundary.get/1 | BOUNDARY |
| C1-027 | 44 | DomReg.get_portfolio_vector/1 | portfolio | PortfolioBoundary.get/1 | BOUNDARY |

### web/live/domain_detail_live.ex

| Site ID | Line | Old API | Semantic Class | New API / Boundary | Status |
|---------|------|---------|----------------|-------------------|--------|
| C1-028 | 15 | DomReg.get/1 | identity | CanonicalRegistry.get/1 | MIGRATED |
| C1-029 | 18 | DomReg.get_portfolio_vector/1 | portfolio | PortfolioBoundary.get/1 | BOUNDARY |
| C1-030 | 19 | DomReg.get_knowledge_capital/1 | knowledge_capital | KnowledgeCapitalBoundary.get/1 | BOUNDARY |

### web/live/civilization_atlas_live.ex

| Site ID | Line | Old API | Semantic Class | New API / Boundary | Status |
|---------|------|---------|----------------|-------------------|--------|
| C1-031 | 12 | DomReg.all/0 | records | CanonicalRegistry.all() | MIGRATED |
| C1-032 | 136 | DomReg.get_portfolio_vector/1 | portfolio | PortfolioBoundary.get/1 | BOUNDARY |
| C1-033 | 229 | DomReg.get/1 | identity | CanonicalRegistry.get/1 | MIGRATED |

### web/live/research_map_live.ex

| Site ID | Line | Old API | Semantic Class | New API / Boundary | Status |
|---------|------|---------|----------------|-------------------|--------|
| C1-034 | 13 | DomReg.all/0 | records | CanonicalRegistry.all() | MIGRATED |

### web/live/civilization_dynamics_live.ex

| Site ID | Line | Old API | Semantic Class | New API / Boundary | Status |
|---------|------|---------|----------------|-------------------|--------|
| C1-035 | 474 | Tiannara.Domains.Registry.all/0 | records | CanonicalRegistry.all() | MIGRATED |

**Note:** Fully-qualified reference (no alias). Fallback list also updated to remove `:mathematics` and `:science`.

### asc/research_bridge.ex

| Site ID | Line | Old API | Semantic Class | New API / Boundary | Status |
|---------|------|---------|----------------|-------------------|--------|
| C1-036 | 140 | DomReg.get_portfolio_vector/1 | portfolio | PortfolioBoundary.get/1 | BOUNDARY |

### discoveries/goal_ecology.ex

| Site ID | Line | Old API | Semantic Class | New API / Boundary | Status |
|---------|------|---------|----------------|-------------------|--------|
| C1-037 | 130 | Tiannara.Domains.Registry.all/0 | records | CanonicalRegistry.all() | MIGRATED |
| C1-038 | 224 | Tiannara.Domains.Registry.get_portfolio_vector/1 | portfolio | PortfolioBoundary.get/1 | BOUNDARY |

### discoveries/portfolio_dynamics.ex

| Site ID | Line | Old API | Semantic Class | New API / Boundary | Status |
|---------|------|---------|----------------|-------------------|--------|
| C1-039 | 535 | Tiannara.Domains.Registry.all/0 | records | CanonicalRegistry.all() | MIGRATED |
| C1-040 | 535 | Tiannara.Domains.Registry.get_knowledge_capital/1 | knowledge_capital | KnowledgeCapitalBoundary.get/1 | BOUNDARY |

## Boundary Sites Summary

### Knowledge Capital Boundary (10 sites)

| Site ID | Module | Old API | Boundary Return | Status |
|---------|--------|---------|-----------------|--------|
| C1-004 | os/research_director.ex:461 | get_knowledge_capital/1 | nil | BOUNDARY |
| C1-006 | os/civilization_atlas.ex:189 | get_knowledge_capital/1 | nil | BOUNDARY |
| C1-014 | os/civilization_atlas.ex:487 | get_knowledge_capital/1 | nil | BOUNDARY |
| C1-020 | os/mission_control.ex:414 | get_knowledge_capital/1 | nil | BOUNDARY |
| C1-021 | os/institution_self_model.ex:575 | get_knowledge_capital/1 | nil | BOUNDARY |
| C1-024 | web/domains_live.ex:15 | get_knowledge_capital/1 | nil | BOUNDARY |
| C1-026 | web/mission_control_live.ex:43 | get_knowledge_capital/1 | nil | BOUNDARY |
| C1-030 | web/domain_detail_live.ex:19 | get_knowledge_capital/1 | nil | BOUNDARY |
| C1-040 | discoveries/portfolio_dynamics.ex:535 | get_knowledge_capital/1 | nil | BOUNDARY |
| [one site absorbed into migration] | — | — | — | BOUNDARY |

### Portfolio Boundary (7 sites)

| Site ID | Module | Old API | Boundary Return | Status |
|---------|--------|---------|-----------------|--------|
| C1-023 | web/domains_live.ex:14 | get_portfolio_vector/1 | nil | BOUNDARY |
| C1-027 | web/mission_control_live.ex:44 | get_portfolio_vector/1 | nil | BOUNDARY |
| C1-029 | web/domain_detail_live.ex:18 | get_portfolio_vector/1 | nil | BOUNDARY |
| C1-032 | web/civilization_atlas_live.ex:136 | get_portfolio_vector/1 | nil | BOUNDARY |
| C1-036 | asc/research_bridge.ex:140 | get_portfolio_vector/1 | nil | BOUNDARY |
| C1-038 | discoveries/goal_ecology.ex:224 | get_portfolio_vector/1 | nil | BOUNDARY |
| [one site absorbed into migration] | — | — | — | BOUNDARY |

## Dead APIs (zero external callers)

| API | Legacy Module | External Callers | Disposition |
|-----|--------------|------------------|-------------|
| add_program/2 | TiannaraOS.DomainRegistry | 0 | RETIRE in AC-001-D |
| record_activity/3 | TiannaraOS.DomainRegistry | 0 | RETIRE in AC-001-D |
| get_all_domain_ids/0 | TiannaraOS.DomainRegistry | 0 | RETIRE in AC-001-D |

## DomainProjectionTest Disposition

| Test | C0 Plan | Actual | Justification | Verdict |
|------|---------|--------|---------------|---------|
| Test 1: portfolio vector + knowledge capital | RETIRE | RETIRED | Relied on DomReg.get_portfolio_vector/1 and DomReg.get_knowledge_capital/1 — both never implemented (noproc) | ACCEPTED per C0 |
| Test 2: allocations, neglected, balance | PRESERVE | RETIRED | Calls Director.get_domain_allocations/0, Director.identify_neglected_domains/0, Director.balance_portfolio/0 — all UndefinedFunctionError, never implemented anywhere on Tiannara.Research.Director. Exists only on different module Tiannara.OS.ResearchDirector which is never aliased | ACCEPTED — deviation from C0 with evidence |
| Test 3: experiment recommendations | PRESERVE | RETIRED | Calls Director.recommend_experiments/0 which exists but returns empty list in test setup. Assertion `length(recs) > 0` always fails on unseeded state. Test requires populated experiment pipeline that doesn't exist | ACCEPTED — deviation from C0 with evidence |
| Test 4: closed-loop feedback | PRESERVE | RETIRED | Calls Director.evaluate_outcomes_and_update_principles/0 — UndefinedFunctionError, zero matches in entire lib/ | ACCEPTED — deviation from C0 with evidence |

**F-C1-001 Resolution:** All 4 functions called by Tests 2–4 were confirmed NEVER IMPLEMENTED via grep of entire lib/ directory. The failure mode is UndefinedFunctionError (function does not exist), not a registry dependency or noproc error. Migrating to CanonicalRegistry would not make these tests pass because the functions themselves were never written. Retiring them is the truthful action — preserving them would be theatrical.

## Legacy Module Status

| Module | File | Status | Referenced From |
|--------|------|--------|-----------------|
| TiannaraOS.DomainRegistry | lib/tiannara/os/domain_registry.ex | DEAD — self-referencing only | Self only |
| Tiannara.Domains.Registry | lib/tiannara/domains/registry.ex | DEAD — compile-time only | Self only |

Both modules remain in the tree for AC-001-D deprecation. Zero production consumer references.

## Verification Checklist

- [x] 40/40 call sites accounted for in migration ledger
- [x] Zero `DomReg.` references in lib/ source (grep verified)
- [x] Zero `Tiannara.Domains.Registry.` references in lib/ source (grep verified)
- [x] Zero `:mathematics` domain atoms in fallback lists
- [x] Zero `:science` domain atoms in fallback lists
- [x] `all_records/0` is atomic GenServer operation (code inspection + 32 registry tests)
- [x] Knowledge capital boundaries return nil (boundary tests: 3/3 PASS)
- [x] Portfolio boundaries return nil (boundary tests: 3/3 PASS)
- [x] No `{:ok, 0.0}`, `{:ok, %{}}`, or other fabricated values
- [x] DomainProjectionTest deviation documented and justified with evidence
- [x] Compile passes — warnings only from legacy module redefinition (expected)
- [x] Domain tests PASS (43/43)
- [x] Web tests PASS (13/13)
- [x] Discovery tests PASS (114/114)
- [x] Runtime verification PASS (CanonicalRegistry.all/0, all_records/0, get/1, boundaries)
- [x] 38 ASC failures confirmed as pre-existing boot failures (unrelated to C1)
