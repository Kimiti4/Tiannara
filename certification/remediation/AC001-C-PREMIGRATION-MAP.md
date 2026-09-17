# AC-001-C: Pre-Migration Consumer Map

**Date:** 2026-08-26
**Evidence class:** E1 (repository inspection via grep/read)
**Status:** COMPLETE — awaiting human review before AC-001-C mutation

---

## 1. Consumer Inventory

### Legacy Registry 1: TiannaraOS.DomainRegistry (GenServer, never started)

| # | Consumer | File:Line | API Called | Canonical API | Semantic Equiv | Transformation | Test Coverage |
|---|----------|-----------|------------|---------------|----------------|----------------|---------------|
| 1 | `TiannaraOS.ResearchDirector` | `os/research_director.ex:229` | `list_all/0` | `CanonicalRegistry.all/0` | **APPROXIMATE** | Return type differs: `{:ok, [Domain.t()]}` → `[domain_id()]`. Callers access `domain.id` — must refactor to use atom directly. | Research director tests |
| 2 | `TiannaraOS.ResearchDirector` | `os/research_director.ex:403` | `list_all/0` | `CanonicalRegistry.all/0` | **APPROXIMATE** | Same as above | Research director tests |
| 3 | `TiannaraOS.ResearchDirector` | `os/research_director.ex:457` | `list_all/0` | `CanonicalRegistry.all/0` | **APPROXIMATE** | Same as above | Research director tests |
| 4 | `TiannaraOS.ResearchDirector` | `os/research_director.ex:460` | `get_knowledge_capital/1` | **NONE** | **REQUIRES_NEW_SERVICE** | Knowledge capital not owned by canonical registry. Must redirect to knowledge capital service (not yet built). | Research director tests |
| 5 | `TiannaraOS.ExecutiveDashboard` | `os/executive_dashboard.ex:87` | `list_all/0` | `CanonicalRegistry.all/0` | **APPROXIMATE** | Same return-type mismatch | No dedicated tests |
| 6 | `TiannaraOS.ExecutiveDashboard` | `os/executive_dashboard.ex:142` | `list_all/0` | `CanonicalRegistry.all/0` | **APPROXIMATE** | Same | No dedicated tests |
| 7 | `TiannaraOS.ExecutiveDashboard` | `os/executive_dashboard.ex:320` | `list_all/0` | `CanonicalRegistry.all/0` | **APPROXIMATE** | Same | No dedicated tests |
| 8 | `TiannaraOS.CivilizationAtlas` | `os/civilization_atlas.ex:181` | `get/1` | `CanonicalRegistry.get/1` | **APPROXIMATE** | Return type differs: `{:ok, Domain.t()}` → `{:ok, domain_record()}`. Field names differ (`domain.knowledge_capital` not in canonical record). | No dedicated tests |
| 9 | `TiannaraOS.CivilizationAtlas` | `os/civilization_atlas.ex:188` | `get_knowledge_capital/1` | **NONE** | **REQUIRES_NEW_SERVICE** | Knowledge capital not owned by canonical registry | No dedicated tests |
| 10 | `TiannaraOS.CivilizationAtlas` | `os/civilization_atlas.ex:290` | `list_all/0` | `CanonicalRegistry.all/0` | **APPROXIMATE** | Same return-type mismatch | No dedicated tests |
| 11 | `TiannaraOS.CivilizationAtlas` | `os/civilization_atlas.ex:307` | `list_all/0` | `CanonicalRegistry.all/0` | **APPROXIMATE** | Same | No dedicated tests |
| 12 | `TiannaraOS.CivilizationAtlas` | `os/civilization_atlas.ex:321` | `list_all/0` | `CanonicalRegistry.all/0` | **APPROXIMATE** | Same | No dedicated tests |
| 13 | `TiannaraOS.CivilizationAtlas` | `os/civilization_atlas.ex:335` | `list_all/0` | `CanonicalRegistry.all/0` | **APPROXIMATE** | Same | No dedicated tests |
| 14 | `TiannaraOS.CivilizationAtlas` | `os/civilization_atlas.ex:408` | `list_all/0` | `CanonicalRegistry.all/0` | **APPROXIMATE** | Same | No dedicated tests |
| 15 | `TiannaraOS.CivilizationAtlas` | `os/civilization_atlas.ex:444` | `list_all/0` | `CanonicalRegistry.all/0` | **APPROXIMATE** | Same | No dedicated tests |
| 16 | `TiannaraOS.CivilizationAtlas` | `os/civilization_atlas.ex:483` | `list_all/0` | `CanonicalRegistry.all/0` | **APPROXIMATE** | Same | No dedicated tests |
| 17 | `TiannaraOS.CivilizationAtlas` | `os/civilization_atlas.ex:486` | `get_knowledge_capital/1` | **NONE** | **REQUIRES_NEW_SERVICE** | Knowledge capital not owned by canonical registry | No dedicated tests |
| 18 | `TiannaraOS.MissionControl` | `os/mission_control.ex:118` | `list_all/0` | `CanonicalRegistry.all/0` | **APPROXIMATE** | Same return-type mismatch | No dedicated tests |
| 19 | `TiannaraOS.MissionControl` | `os/mission_control.ex:163` | `list_all/0` | `CanonicalRegistry.all/0` | **APPROXIMATE** | Same | No dedicated tests |
| 20 | `TiannaraOS.MissionControl` | `os/mission_control.ex:414` | `get_knowledge_capital/1` | **NONE** | **REQUIRES_NEW_SERVICE** | Knowledge capital not owned by canonical registry | No dedicated tests |
| 21 | `TiannaraOS.InstitutionSelfModel` | `os/institution_self_model.ex:574` | `get_knowledge_capital/1` | **NONE** | **REQUIRES_NEW_SERVICE** | Knowledge capital not owned by canonical registry | No dedicated tests |

**Summary:** 21 callers across 5 modules. 16 call `list_all/0`, 5 call `get_knowledge_capital/1`, 1 calls `get/1`.

### Legacy Registry 2: Tiannara.Domains.Registry (compile-time, functions don't exist)

| # | Consumer | File:Line | API Called | Canonical API | Semantic Equiv | Transformation | Test Coverage |
|---|----------|-----------|------------|---------------|----------------|----------------|---------------|
| 1 | `TiannaraWeb.CivilizationDynamicsLive` | `web/live/civilization_dynamics_live.ex:474` | `all/0` | `CanonicalRegistry.all/0` | **APPROXIMATE** | `Domains.Registry.all/0` does not exist. Call would crash. Redirect to `CanonicalRegistry.all/0`. | LiveView tests |
| 2 | `Tiannara.REA.Epistemic.GoalEcology` | `discoveries/goal_ecology.ex:130` | `all/0` | `CanonicalRegistry.all/0` | **APPROXIMATE** | Same — function doesn't exist. Has `Code.ensure_loaded?` guard with fallback. | Goal ecology tests |
| 3 | `Tiannara.REA.Epistemic.GoalEcology` | `discoveries/goal_ecology.ex:224` | `get_portfolio_vector/1` | **NONE** | **REQUIRES_NEW_SERVICE** | Portfolio vector not owned by canonical registry | Goal ecology tests |
| 4 | `Tiannara.Discoveries.PortfolioDynamics` | `discoveries/portfolio_dynamics.ex:535` | `all/0` + `get_knowledge_capital/1` | **PARTIAL** | **MIXED** | `all/0` → `CanonicalRegistry.all/0` (APPROXIMATE). `get_knowledge_capital/1` → REQUIRES_NEW_SERVICE. Has `Code.ensure_loaded?` guard. | No dedicated tests |
| 5 | (via alias DomReg) `TiannaraWeb.DomainsLive` | `web/live/domains_live.ex:10` | `all/0` | `CanonicalRegistry.all/0` | **APPROXIMATE** | Function doesn't exist. Redirect. | LiveView tests |
| 6 | (via alias DomReg) `TiannaraWeb.DomainsLive` | `web/live/domains_live.ex:14` | `get_portfolio_vector/1` | **NONE** | **REQUIRES_NEW_SERVICE** | Portfolio vector not owned by canonical registry | LiveView tests |
| 7 | (via alias DomReg) `TiannaraWeb.DomainsLive` | `web/live/domains_live.ex:15` | `get_knowledge_capital/1` | **NONE** | **REQUIRES_NEW_SERVICE** | Knowledge capital not owned by canonical registry | LiveView tests |
| 8 | (via alias DomReg) `TiannaraWeb.MissionControlLive` | `web/live/mission_control_live.ex:19` | `all/0` | `CanonicalRegistry.all/0` | **APPROXIMATE** | Function doesn't exist. Redirect. | LiveView tests |
| 9 | (via alias DomReg) `TiannaraWeb.MissionControlLive` | `web/live/mission_control_live.ex:43` | `get_knowledge_capital/1` | **NONE** | **REQUIRES_NEW_SERVICE** | Knowledge capital not owned by canonical registry | LiveView tests |
| 10 | (via alias DomReg) `TiannaraWeb.MissionControlLive` | `web/live/mission_control_live.ex:44` | `get_portfolio_vector/1` | **NONE** | **REQUIRES_NEW_SERVICE** | Portfolio vector not owned by canonical registry | LiveView tests |
| 11 | (via alias DomReg) `TiannaraWeb.DomainDetailLive` | `web/live/domain_detail_live.ex:15` | `get/1` | `CanonicalRegistry.get/1` | **APPROXIMATE** | `Domains.Registry.get/1` doesn't exist. Redirect. Return type differs. | LiveView tests |
| 12 | (via alias DomReg) `TiannaraWeb.DomainDetailLive` | `web/live/domain_detail_live.ex:18` | `get_portfolio_vector/1` | **NONE** | **REQUIRES_NEW_SERVICE** | Portfolio vector not owned by canonical registry | LiveView tests |
| 13 | (via alias DomReg) `TiannaraWeb.DomainDetailLive` | `web/live/domain_detail_live.ex:19` | `get_knowledge_capital/1` | **NONE** | **REQUIRES_NEW_SERVICE** | Knowledge capital not owned by canonical registry | LiveView tests |
| 14 | (via alias DomReg) `TiannaraWeb.CivilizationAtlasLive` | `web/live/civilization_atlas_live.ex:12` | `all/0` | `CanonicalRegistry.all/0` | **APPROXIMATE** | Function doesn't exist. Redirect. | LiveView tests |
| 15 | (via alias DomReg) `TiannaraWeb.CivilizationAtlasLive` | `web/live/civilization_atlas_live.ex:136` | `get_portfolio_vector/1` | **NONE** | **REQUIRES_NEW_SERVICE** | Portfolio vector not owned by canonical registry | LiveView tests |
| 16 | (via alias DomReg) `TiannaraWeb.CivilizationAtlasLive` | `web/live/civilization_atlas_live.ex:229` | `get/1` | `CanonicalRegistry.get/1` | **APPROXIMATE** | Function doesn't exist. Redirect. | LiveView tests |
| 17 | (via alias DomReg) `Tiannara.ASC.ResearchBridge` | `asc/research_bridge.ex:140` | `get_portfolio_vector/1` | **NONE** | **REQUIRES_NEW_SERVICE** | Portfolio vector not owned by canonical registry | No dedicated tests |
| 18 | (via alias DomReg) `TiannaraWeb.ResearchMapLive` | `web/live/research_map_live.ex:13` | `all/0` | `CanonicalRegistry.all/0` | **APPROXIMATE** | Function doesn't exist. Redirect. | LiveView tests |

**Summary:** 18 callers across 8 modules. 8 call `all/0`, 7 call `get_portfolio_vector/1`, 5 call `get_knowledge_capital/1`, 2 call `get/1`.

### Test consumers

| # | Consumer | File:Line | API Called | Transformation |
|---|----------|-----------|------------|----------------|
| 1 | `Tiannara.Domains.DomainProjectionTest` | `test/domains/domain_projection_test.exs:19` | `DomReg.all/0` | Redirect to `CanonicalRegistry.all/0` |
| 2 | `Tiannara.Domains.DomainProjectionTest` | `test/domains/domain_projection_test.exs:27` | `DomReg.get_portfolio_vector/1` | REQUIRES_NEW_SERVICE or retire test |
| 3 | `Tiannara.Domains.DomainProjectionTest` | `test/domains/domain_projection_test.exs:44` | `DomReg.get_knowledge_capital/1` | REQUIRES_NEW_SERVICE or retire test |

---

## 2. Dead Callers (to be removed, not migrated)

| # | Consumer | File:Line | API Called | Reason |
|---|----------|-----------|------------|--------|
| — | (none found) | — | `add_program/2` | Zero callers confirmed in A0 |
| — | (none found) | — | `record_activity/3` | Zero callers confirmed in A0 |
| — | (none found) | — | `get_all_domain_ids/0` | Zero callers confirmed in A0 |

Dead APIs exist only in `domain_registry.ex` definitions. No external callers. Safe to not reproduce.

---

## 3. Consumers Requiring New Service Integration

| # | Consumer | File:Line | Concept Needed | Target Service | Count |
|---|----------|-----------|----------------|----------------|-------|
| 1-5 | `ResearchDirector`, `CivilizationAtlas`, `MissionControl`, `InstitutionSelfModel` | Various `os/` files | `knowledge_capital` | Knowledge Capital Service (not yet built) | 5 callers |
| 6-12 | `GoalEcology`, `PortfolioDynamics`, `DomainsLive`, `MissionControlLive`, `DomainDetailLive`, `CivilizationAtlasLive`, `ResearchBridge` | Various `web/live/` + `discoveries/` + `asc/` files | `portfolio_vector` | Portfolio Vector Service (not yet built) | 7 callers |

**Total consumers deferred to new service:** 12 callers across 8 modules

---

## 4. Migration Batches

### Batch 1: `list_all/0` → `all/0` callers (EXACT identity, APPROXIMATE return type)

**Risk:** LOW-MEDIUM (return type differs, but most callers only iterate domains)

| # | Consumer | File:Line | Change Needed |
|---|----------|-----------|---------------|
| 1 | `ResearchDirector` | `os/research_director.ex:229` | `DomainRegistry.list_all()` → `{:ok, CanonicalRegistry.all()}` wrapper or refactor caller |
| 2 | `ResearchDirector` | `os/research_director.ex:403` | Same |
| 3 | `ResearchDirector` | `os/research_director.ex:457` | Same |
| 4 | `ExecutiveDashboard` | `os/executive_dashboard.ex:87` | Same |
| 5 | `ExecutiveDashboard` | `os/executive_dashboard.ex:142` | Same |
| 6 | `ExecutiveDashboard` | `os/executive_dashboard.ex:320` | Same |
| 7 | `CivilizationAtlas` | `os/civilization_atlas.ex:290` | Same |
| 8 | `CivilizationAtlas` | `os/civilization_atlas.ex:307` | Same |
| 9 | `CivilizationAtlas` | `os/civilization_atlas.ex:321` | Same |
| 10 | `CivilizationAtlas` | `os/civilization_atlas.ex:335` | Same |
| 11 | `CivilizationAtlas` | `os/civilization_atlas.ex:408` | Same |
| 12 | `CivilizationAtlas` | `os/civilization_atlas.ex:444` | Same |
| 13 | `CivilizationAtlas` | `os/civilization_atlas.ex:483` | Same |
| 14 | `MissionControl` | `os/mission_control.ex:118` | Same |
| 15 | `MissionControl` | `os/mission_control.ex:163` | Same |
| 16 | `CivilizationDynamicsLive` | `web/live/civilization_dynamics_live.ex:474` | `Domains.Registry.all()` → `CanonicalRegistry.all()` (drop `Enum.map(& &1.id)` — already atoms) |
| 17 | `GoalEcology` | `discoveries/goal_ecology.ex:130` | Same as above |
| 18 | `PortfolioDynamics` | `discoveries/portfolio_dynamics.ex:535` | Partial: `all()` → `CanonicalRegistry.all()`, but `get_knowledge_capital` deferred |
| 19 | `DomainsLive` | `web/live/domains_live.ex:10` | `DomReg.all()` → `CanonicalRegistry.all()` |
| 20 | `MissionControlLive` | `web/live/mission_control_live.ex:19` | Same |
| 21 | `CivilizationAtlasLive` | `web/live/civilization_atlas_live.ex:12` | Same |
| 22 | `ResearchMapLive` | `web/live/research_map_live.ex:13` | Same |
| 23 | `DomainProjectionTest` | `test/domains/domain_projection_test.exs:19` | Same |

**Estimated changes:** 23 call sites across 12 files
**Key decision:** `DomainRegistry.list_all()` returns `{:ok, [Domain.t()]}` while `CanonicalRegistry.all/0` returns `[domain_id()]`. Options:
- (A) Add `list_all/0` to `CanonicalRegistry` returning `{:ok, [%{id: atom()}]}` for compatibility
- (B) Refactor all 15 `os/` callers to use `all/0` directly (cleaner but more changes)
- (C) Add a wrapper function `list_all/0` on `CanonicalRegistry` that returns the old shape

**Recommendation:** Option (C) — add `list_all/0` to `CanonicalRegistry` returning `{:ok, Enum.map(@canonical_domains, &%{id: &1})}`. Minimal caller changes, preserves semantics.

### Batch 2: `get/1` callers (APPROXIMATE)

| # | Consumer | File:Line | Change Needed |
|---|----------|-----------|---------------|
| 1 | `CivilizationAtlas` | `os/civilization_atlas.ex:181` | `DomainRegistry.get(id)` → `CanonicalRegistry.get(id)`. Caller accesses `domain.knowledge_capital` — must be refactored since canonical record doesn't have it. |
| 2 | `DomainDetailLive` | `web/live/domain_detail_live.ex:15` | `DomReg.get(id)` → `CanonicalRegistry.get(id)`. Function didn't exist before — this was always broken. |
| 3 | `CivilizationAtlasLive` | `web/live/civilization_atlas_live.ex:229` | `DomReg.get(id)` → `CanonicalRegistry.get(id)`. Same — always broken. |

**Estimated changes:** 3 call sites across 3 files
**Risk:** MEDIUM — `civilization_atlas.ex:181` chains into `get_knowledge_capital` which is deferred. Must refactor the chain.

### Batch 3: `get_knowledge_capital/1` callers (REQUIRES_NEW_SERVICE)

| # | Consumer | File:Line | Status |
|---|----------|-----------|--------|
| 1 | `ResearchDirector` | `os/research_director.ex:460` | **DEFERRED** — knowledge capital service not yet built |
| 2 | `CivilizationAtlas` | `os/civilization_atlas.ex:188` | **DEFERRED** |
| 3 | `CivilizationAtlas` | `os/civilization_atlas.ex:486` | **DEFERRED** |
| 4 | `MissionControl` | `os/mission_control.ex:414` | **DEFERRED** |
| 5 | `InstitutionSelfModel` | `os/institution_self_model.ex:574` | **DEFERRED** |
| 6 | `PortfolioDynamics` | `discoveries/portfolio_dynamics.ex:535` | **DEFERRED** |
| 7 | `DomainsLive` | `web/live/domains_live.ex:15` | **DEFERRED** |
| 8 | `MissionControlLive` | `web/live/mission_control_live.ex:43` | **DEFERRED** |
| 9 | `DomainDetailLive` | `web/live/domain_detail_live.ex:19` | **DEFERRED** |
| 10 | `DomainProjectionTest` | `test/domains/domain_projection_test.exs:44` | **DEFERRED** |

**NOT migrated in AC-001-C.** Requires knowledge capital service design (separate gate).

### Batch 4: `get_portfolio_vector/1` callers (REQUIRES_NEW_SERVICE)

| # | Consumer | File:Line | Status |
|---|----------|-----------|--------|
| 1 | `GoalEcology` | `discoveries/goal_ecology.ex:224` | **DEFERRED** |
| 2 | `DomainsLive` | `web/live/domains_live.ex:14` | **DEFERRED** |
| 3 | `MissionControlLive` | `web/live/mission_control_live.ex:44` | **DEFERRED** |
| 4 | `DomainDetailLive` | `web/live/domain_detail_live.ex:18` | **DEFERRED** |
| 5 | `CivilizationAtlasLive` | `web/live/civilization_atlas_live.ex:136` | **DEFERRED** |
| 6 | `ResearchBridge` | `asc/research_bridge.ex:140` | **DEFERRED** |
| 7 | `DomainProjectionTest` | `test/domains/domain_projection_test.exs:27` | **DEFERRED** |

**NOT migrated in AC-001-C.** Requires portfolio vector service design (separate gate).

### Batch 5: Dead code removal

No external callers found for `add_program/2`, `record_activity/3`, `get_all_domain_ids/0`. These are definitions only in `domain_registry.ex`. Safe to deprecate in AC-001-D.

---

## 5. Semantic Drift Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| `DomainRegistry.list_all()` returns `{:ok, [Domain.t()]}` with full records; `CanonicalRegistry.all/0` returns `[domain_id()]` as atoms | **HIGH** | Add `list_all/0` to `CanonicalRegistry` returning `{:ok, [%{id: atom()}]}` for compatibility. Or refactor all callers. |
| `DomainRegistry.get/1` returns domain records with `knowledge_capital` field; `CanonicalRegistry.get/1` returns records without it | **MEDIUM** | Callers that access `knowledge_capital` are already in Batch 3 (deferred). Canonical record doesn't need it. |
| `Domains.Registry.all/0` doesn't exist — callers were always broken | **LOW** | Redirect to `CanonicalRegistry.all/0`. Fixes existing bug. |
| `Domains.Registry.get_portfolio_vector/1` doesn't exist — callers were always broken | **LOW** | Deferred to Batch 4. Callers were already broken. |
| `Domains.Registry.get_knowledge_capital/1` doesn't exist — callers were always broken | **LOW** | Deferred to Batch 3. Callers were already broken. |
| Domain atoms: legacy uses `:science`, `:mathematics`; canonical excludes them | **MEDIUM** | AC-001-E (orphan resolution) must reclassify `:science`/`:mathematics` references. Not part of C. |

---

## 6. Missing Test Coverage

| Module | Test Coverage | Risk |
|--------|---------------|------|
| `TiannaraOS.ExecutiveDashboard` | No dedicated tests | HIGH — migrations unverified |
| `TiannaraOS.CivilizationAtlas` | No dedicated tests | HIGH — 9 call sites, all unverified |
| `TiannaraOS.MissionControl` | No dedicated tests | HIGH — 3 call sites, all unverified |
| `TiannaraOS.InstitutionSelfModel` | No dedicated tests | HIGH — 1 call site, unverified |
| `Tiannara.ASC.ResearchBridge` | No dedicated tests | MEDIUM — 1 call site |
| All `TiannaraWeb.LiveView` modules | LiveView tests exist but may not exercise registry paths | MEDIUM |
| `Tiannara.Discoveries.PortfolioDynamics` | No dedicated tests | MEDIUM |
| `Tiannara.REA.Epistemic.GoalEcology` | Tests exist | LOW |

---

## 7. Decision Points Requiring Human Review

1. **`list_all/0` compatibility:** Should `CanonicalRegistry` gain a `list_all/0` returning `{:ok, [%{id: atom()}]}` for backward compatibility, or should all 15 `os/` callers be refactored to use `all/0`?

2. **Knowledge capital consumers:** The 10 `get_knowledge_capital/1` callers are currently broken (GenServer never started). Should they be:
   - (A) Left broken until knowledge capital service is built (separate gate)
   - (B) Given a stub/shim that returns empty data
   - (C) Temporarily wrapped with `case` that handles `{:error, :noproc}` gracefully

3. **Portfolio vector consumers:** Same question as above for 7 `get_portfolio_vector/1` callers.

4. **DomainProjectionTest:** 4 failing tests use undefined legacy APIs. Should they be:
   - (A) Migrated to use `CanonicalRegistry` (preserving test intent)
   - (B) Retired (the behavior they test was never real)
   - (C) Kept as-is as migration debt markers

5. **`:science`/`:mathematics` reclassification:** 26+ files reference `:science` as a domain atom. This is AC-001-E work, but should any of it be pulled into C?

---

## 8. Preliminary Counts

| Category | Count |
|----------|-------|
| Total unique consumers | 17 modules |
| Total call sites | 42 (21 DomainRegistry + 18 Domains.Registry + 3 test) |
| Batch 1 (list_all → all): EXACT/APPROXIMATE | 23 call sites, 12 files |
| Batch 2 (get/1): APPROXIMATE | 3 call sites, 3 files |
| Batch 3 (get_knowledge_capital): DEFERRED | 10 call sites, 8 files |
| Batch 4 (get_portfolio_vector): DEFERRED | 7 call sites, 6 files |
| Batch 5 (dead code): REMOVED | 0 external callers |
| New service consumers (deferred) | 17 call sites total |

---

*AC-001-C pre-migration map complete. Awaiting human review and batch authorization.*
