# AC-001-C0: Semantic Migration Analysis

**Date:** 2026-08-26
**Commit:** HEAD
**Evidence class:** E1 (source inspection via read/grep)
**Status:** COMPLETE — no mutation performed

---

## 1. Consumer Usage Pattern Analysis

### list_all/0 consumers (16 sites on DomainRegistry, 7 on Domains.Registry)

**CRITICAL FINDING:** Most `list_all/0` consumers access **record fields** (`domain.id`, `domain.name`, `domain.active_programs`, `domain.last_research_activity`, `domain.discoveries`), not just IDs. This means `CanonicalRegistry.all/0` returning `[domain_id()]` is **insufficient** for the majority of callers.

| # | Consumer | File:Line | Uses IDs only | Uses record fields | Fields accessed | Chains to |
|---|----------|-----------|:---:|:---:|----------------|------------|
| 1 | `ResearchDirector.perform_priority_analysis` | `os/research_director.ex:229` | NO | YES | `domain.id`, `domain.active_programs`, `domain.last_research_activity` | `calculate_domain_priority/2` |
| 2 | `ResearchDirector.find_neglected_domains` | `os/research_director.ex:403` | NO | YES | `domain.id`, domain passed to `low_recent_activity?/1` | `UnknownRegistry`, `has_critical_unknowns?/1` |
| 3 | `ResearchDirector.generate_portfolio_health_report` | `os/research_director.ex:457` | NO | YES | `domain.id`, `domain.name` | `get_knowledge_capital`, `TheoryRegistry`, `DiscoveryRegistry`, `UnknownRegistry` |
| 4 | `ExecutiveDashboard.calculate_research_debt` | `os/executive_dashboard.ex:87` | YES | NO | `domain.id` | `calculate_domain_debt/1` |
| 5 | `ExecutiveDashboard.calculate_innovation_velocity` | `os/executive_dashboard.ex:142` | NO | YES | `domain.id`, `domain.discoveries` | `identify_top_domains_by_discovery/1` |
| 6 | `ExecutiveDashboard.calculate_portfolio_diversity` | `os/executive_dashboard.ex:320` | NO | YES | `domain.id`, `domain.active_programs` | `calculate_diversity_index/1` |
| 7 | `CivilizationAtlas.query_validated_discoveries` | `os/civilization_atlas.ex:290` | YES | NO | `domain.id` | `DiscoveryRegistry.list_by_domain/1` |
| 8 | `CivilizationAtlas.query_high_confidence_theories` | `os/civilization_atlas.ex:307` | YES | NO | `domain.id` | `TheoryRegistry.list_by_domain/1` |
| 9 | `CivilizationAtlas.query_low_confidence_theories` | `os/civilization_atlas.ex:321` | YES | NO | `domain.id` | `TheoryRegistry.list_by_domain/1` |
| 10 | `CivilizationAtlas.query_established_laws` | `os/civilization_atlas.ex:335` | YES | NO | `domain.id` | `LawRegistry.list_by_domain/1` |
| 11 | `CivilizationAtlas.query_critical_unknowns` | `os/civilization_atlas.ex:408` | YES | NO | `domain.id` | `UnknownRegistry.get_by_priority/2` |
| 12 | `CivilizationAtlas.query_cross_domain_transfers` | `os/civilization_atlas.ex:444` | YES | NO | `domain.id` | `DiscoveryRegistry.list_by_domain/1` |
| 13 | `CivilizationAtlas.query_domain_maturity_comparison` | `os/civilization_atlas.ex:483` | NO | YES | `domain.id`, `domain.name` | `get_knowledge_capital` |
| 14 | `MissionControl.get_portfolio_health` | `os/mission_control.ex:118` | YES | NO | `domain.id` | `get_knowledge_capital` |
| 15 | `MissionControl.get_dashboard_data` | `os/mission_control.ex:163` | YES | NO | `domain.id` | Multiple registries |
| 16 | `CivilizationDynamicsLive.list_domains` | `web/live/civilization_dynamics_live.ex:474` | YES | NO | `&1.id` | — |
| 17 | `GoalEcology.list_domains` | `discoveries/goal_ecology.ex:130` | YES | NO | `&1.id` | — |
| 18 | `PortfolioDynamics` | `discoveries/portfolio_dynamics.ex:535` | YES | NO | `&1.id` | `get_knowledge_capital` |
| 19 | `DomainsLive.mount` | `web/live/domains_live.ex:10` | NO | YES | `dom.id` | `get_portfolio_vector`, `get_knowledge_capital` |
| 20 | `MissionControlLive.mount` | `web/live/mission_control_live.ex:19` | YES | NO | `dom.id` | `get_knowledge_capital`, `get_portfolio_vector` |
| 21 | `CivilizationAtlasLive.mount` | `web/live/civilization_atlas_live.ex:12` | YES | NO | (implicit) | `get_portfolio_vector`, `get/1` |
| 22 | `ResearchMapLive.mount` | `web/live/research_map_live.ex:13` | YES | NO | (implicit) | — |
| 23 | `DomainProjectionTest.setup` | `test/domains/domain_projection_test.exs:19` | YES | NO | (implicit) | `get_portfolio_vector`, `get_knowledge_capital` |

### Summary: Record field usage

| Consumer | Uses IDs only | Uses record fields |
|----------|:---:|:---:|
| `ResearchDirector` (3 sites) | 0 | 3 |
| `ExecutiveDashboard` (3 sites) | 1 | 2 |
| `CivilizationAtlas` (7 sites) | 5 | 2 |
| `MissionControl` (2 sites) | 2 | 0 |
| Web LiveViews (5 sites) | 3 | 2 |
| Discoveries (2 sites) | 2 | 0 |
| Test (1 site) | 1 | 0 |
| **TOTAL** | **14** | **9** |

**9 out of 23 call sites access record fields** beyond just `domain.id`.

### get/1 consumers (3 sites)

| # | Consumer | File:Line | Uses record | Fields accessed | Chains to |
|---|----------|-----------|:-----------:|-----------------|-----------|
| 1 | `CivilizationAtlas.get_domain_knowledge_map` | `os/civilization_atlas.ex:181` | YES | `domain` (full record) | `get_knowledge_capital`, multiple registries |
| 2 | `DomainDetailLive.mount` | `web/live/domain_detail_live.ex:15` | YES | `dom.program_ids` | `get_portfolio_vector`, `get_knowledge_capital` |
| 3 | `CivilizationAtlasLive` | `web/live/civilization_atlas_live.ex:229` | Partial | returned as map value | — |

---

## 2. `all_records/0` Necessity Determination

**Verdict: REQUIRED**

**Evidence:**
- 9 of 23 `list_all/0` consumers access record fields (`domain.name`, `domain.active_programs`, `domain.last_research_activity`, `domain.discoveries`)
- 3 of 3 `get/1` consumers access record fields
- These are NOT just ID enumerations — they need the full domain record

**Implementation:**
- Add `all_records/0` to `CanonicalRegistry` as an **atomic GenServer operation**
- Do NOT implement as client-side N+1 (`all() |> Enum.map(&get/1)`)
- Return shape: `{:ok, [domain_record()]}` where `domain_record()` includes `id`, `name`, `description`, `module`, `metadata`, `lifecycle`
- Consumers that only need IDs continue to use `all/0`
- Consumers that need records use `all_records/0`

---

## 3. Knowledge Capital Boundary Analysis

### Existing implementation

| Aspect | Finding |
|--------|---------|
| Module | `TiannaraOS.KnowledgeCapital` (`lib/tiannara/os/knowledge_capital.ex`) |
| Type | Pure function module (not GenServer) — `calculate_capital/2`, `allocate_funding/1` |
| Runtime status | **Operational** — functions are callable, no GenServer dependency |
| Data source | Reads from `TiannaraOS.ResearchProgram` structs and `TiannaraOS.State` |
| Started in supervision? | NO — pure functions, no process needed |
| Relationship to `DomainRegistry.get_knowledge_capital/1` | **Different thing entirely.** `DomainRegistry` stores a static `knowledge_capital` map (principles, programs, theories, etc.) that is never written to. `KnowledgeCapital` module calculates capital scores from program data. |

### Critical distinction

```
DomainRegistry.get_knowledge_capital(:engineering)
  → Returns: %{principles: [], programs: [], theories: [], ...} (static, never written, inert)

TiannaraOS.KnowledgeCapital.calculate_capital(program, state)
  → Returns: float() (dynamic calculation from live program data)
```

These are **two different concepts** with the same name. The `DomainRegistry` version is inert data that was never populated. The `KnowledgeCapital` module is a live calculator.

### Boundary approach

- Do NOT route `get_knowledge_capital/1` consumers to `CanonicalRegistry` — it doesn't own this data
- Do NOT create a stub that returns the inert empty map — that would be fabrication
- Consumers should receive `{:error, :knowledge_capital_unavailable}` until a proper knowledge capital service is built
- The 10 call sites remain **deferred** to a separate gate

### Error contract

```elixir
# When knowledge capital data is unavailable:
{:error, :knowledge_capital_unavailable}
```

---

## 4. Portfolio Boundary Analysis

### Existing implementation

| Aspect | Finding |
|--------|---------|
| Modules | Multiple: `Tiannara.REA.TheoryPortfolio`, `Tiannara.ASC.Research.Portfolio`, `Tiannara.Discovery.Advanced.DiscoveryPortfolioOptimizer`, `Tiannara.MetaScience.PortfolioOptimizer`, `Tiannara.ASC.Executive.PortfolioManager` |
| Type | Various — some GenServer, some pure functions |
| Runtime status | Mixed — some started, some not |
| Relationship to `Domains.Registry.get_portfolio_vector/1` | **Function doesn't exist.** `Domains.Registry` never defined `get_portfolio_vector/1`. All 7 consumers call a nonexistent function. |

### Critical finding

`get_portfolio_vector/1` **never existed** on `Domains.Registry`. All 7 consumers were always broken. The `Code.ensure_loaded?` guard in some callers prevented crashes, but the functionality was never real.

### Boundary approach

- Do NOT create a portfolio vector function on `CanonicalRegistry` — it doesn't own this data
- Do NOT fabricate portfolio vectors
- Consumers should receive `{:error, :portfolio_unavailable}` until portfolio service is built
- The 7 call sites remain **deferred** to a separate gate

### Error contract

```elixir
# When portfolio data is unavailable:
{:error, :portfolio_unavailable}
```

---

## 5. DomainProjectionTest Intent Analysis

### Test 1: "dynamic portfolio vector projection and Knowledge Capital calculation"

- **Original intent:** Verify that domain portfolio vectors are correctly computed from the transfer matrix, and that knowledge capital returns a positive float
- **Original assertion:** `assert vector.transferability == 0.88` (specific value from seeded data), `assert capital > 0.0`
- **Registry dependency:** `DomReg.get_portfolio_vector(:engineering)`, `DomReg.get_knowledge_capital(:engineering)`
- **Verdict:** Tests a **nonexistent API** (`get_portfolio_vector/1`). The behavior being tested was never real. The knowledge capital assertion tests inert empty data.
- **Migration plan:** RETIRE this test. The behavior it tests (portfolio vector projection from transfer matrix) belongs to a future portfolio service gate. Cannot be migrated to `CanonicalRegistry` because the concept is out of scope.

### Test 2: "Research Director allocations, neglected domains, and portfolio balance"

- **Original intent:** Verify `Director.get_domain_allocations/0` returns a map summing to ~1.0, `Director.identify_neglected_domains/0` returns a list, `Director.balance_portfolio/0` returns entropy > 0
- **Original assertion:** `assert_in_delta total_pct, 1.0, 0.05`, `assert balance.entropy > 0.0`
- **Registry dependency:** Indirect — `Director` internally calls `DomainRegistry.list_all()`
- **Verdict:** Tests `Tiannara.Research.Director` behavior, not the registry directly. The Director module uses `DomainRegistry` internally.
- **Migration plan:** Migrate `Director` to use `CanonicalRegistry`, then these tests verify Director behavior through the canonical path. Preserve assertion semantics.

### Test 3: "Research Director experiment recommendations traverse Domain path"

- **Original intent:** Verify `Director.recommend_experiments/0` returns cross-domain transfer recommendations
- **Original assertion:** `assert length(recs) > 0`, `assert first_cross.target_domain_id != nil`
- **Registry dependency:** Indirect through `Director`
- **Verdict:** Same as Test 2 — tests Director behavior, not registry directly
- **Migration plan:** Same as Test 2

### Test 4: "Research Director closed-loop feedback propagates outcomes back to parent principles"

- **Original intent:** Verify `Director.evaluate_outcomes_and_update_principles/0` updates knowledge graph confidence
- **Original assertion:** `assert updated_conf > initial_conf`, `assert_in_delta updated_conf, initial_conf + 0.04, 0.01`
- **Registry dependency:** Indirect through `Director` and `KG`
- **Verdict:** Tests knowledge graph feedback loop, not registry
- **Migration plan:** No registry migration needed. This test doesn't directly use `DomReg`. Verify it still passes after Director migration.

### Summary

| Test | Directly uses DomReg? | Behavior tested | Migration action |
|------|:---:|-----------------|------------------|
| Test 1 | YES | Portfolio vector + knowledge capital (nonexistent APIs) | **RETIRE** — behavior was never real |
| Test 2 | NO (indirect via Director) | Director allocations/neglect/balance | **PRESERVE** — migrate Director internals |
| Test 3 | NO (indirect via Director) | Director experiment recommendations | **PRESERVE** — migrate Director internals |
| Test 4 | NO (indirect via Director/KG) | Knowledge graph feedback loop | **PRESERVE** — no registry migration needed |

---

## 6. Identity Reclassification Map

### :science usages (26 files)

All 26 usages treat `:science` as a **domain identity atom**. Per the frozen ontology, `:science` is a methodology, not a domain.

| # | File:Line | Current treatment | Correct classification | Required change |
|---|-----------|-------------------|------------------------|-----------------|
| 1 | `edm/immune_system.ex:10-14` | Domain in capability list | Methodology | Reclassify or remove from domain lists |
| 2 | `ecology/civilization.ex:14` | Domain in civilization list | Methodology | Remove from domain list |
| 3 | `domain_cortex.ex:11` | Domain in cortex list | Methodology | Remove from domain list |
| 4 | `leoc/compression_engine.ex:49` | Random domain selection | Methodology | Remove from domain pool |
| 5 | `discoveries/institution_ecology.ex:206` | Focus domain | Methodology | Reclassify |
| 6 | `discoveries/goal_ecology.ex:132` | Domain in list | Methodology | Remove from domain list |
| 7 | `web/live/civilization_dynamics_live.ex:476` | Domain in list | Methodology | Remove from domain list |
| 8 | `os/domain_registry.ex:88` | `@twenty_domains` entry | Methodology | Remove from canonical list |
| 9 | `os/domain_profile.ex:92` | Profile mapping | Methodology | Reclassify |
| 10 | `sentinel/d2/epistemic_niche.ex:16` | Niche domain | Methodology | Reclassify |
| 11 | `os/governance/constitutional_institution.ex:22,79,115,187,223` | Governance domain | Methodology | Reclassify |
| 12 | `os/governance/capability_checker.ex:33` | Authorization domain | Methodology | Reclassify |
| 13 | `os/program_registry.ex:868` | Program domain | Methodology | Reclassify |
| 14 | `os/governance/genome_calculator.ex:143,158` | Genome domain | Methodology | Reclassify |
| 15 | `os/world_manager.ex:127` | Lab domain mapping | Methodology | Reclassify |
| 16 | `os/governance/governance_ledger.ex:114` | Ledger domain | Methodology | Reclassify |
| 17 | `os/governance/institutional_provenance.ex:34` | Provenance domain | Methodology | Reclassify |
| 18 | `os/governance/rfc_validation_laboratory.ex:242` | RFC affected domain | Methodology | Reclassify |

**Scope note:** This is AC-001-E work (orphan resolution). C should only reclassify usages that are directly in the migration path. Full `:science` reclassification is out of C scope.

### :mathematics usages (30+ files)

All usages treat `:mathematics` as a domain identity. Per the frozen ontology, `:mathematics` is an epistemic substrate.

**Scope note:** Same as `:science` — full reclassification is AC-001-E work. C should only address usages directly in the migration path.

### :cs / ComputerScience usages

| # | File:Line | Current treatment | Correct classification | Required change |
|---|-----------|-------------------|------------------------|-----------------|
| 1 | `domains/computer_science.ex:7` | Returns `%{domain: :cs}` | Computation specialization | MERGED into `:computation` — module deprecated |

**Already resolved in AC-001-A:** `ComputerScience` is orphaned, `:cs` has zero consumers. No migration needed.

---

## 7. Migration Plan Summary

### C1: Add `all_records/0` to CanonicalRegistry

- Add atomic GenServer operation `all_records/0` returning `{:ok, [domain_record()]}`
- Record includes: `id`, `name`, `description`, `module`, `metadata`, `lifecycle`
- 9 consumers that access record fields will use this API

### C2: Migrate domain-ID consumers (14 sites)

- `CivilizationAtlas` (5 ID-only sites), `MissionControl` (2), `ExecutiveDashboard` (1), LiveViews (3), Discoveries (2), Test (1)
- Change: `DomainRegistry.list_all()` → `CanonicalRegistry.all()` or `{:ok, CanonicalRegistry.all()}`
- Pattern: `{:ok, domains} = DomainRegistry.list_all()` → `domains = CanonicalRegistry.all()`
- Most only access `domain.id` — can be refactored to use atom directly

### C3: Migrate domain-record consumers (9 sites)

- `ResearchDirector` (3), `ExecutiveDashboard` (2), `CivilizationAtlas` (2), LiveViews (2)
- Change: `DomainRegistry.list_all()` → `{:ok, CanonicalRegistry.all_records()}`
- Or refactor to use `all_records/0` and adjust pattern matching

### C4: Establish knowledge-capital boundary (10 sites)

- Replace `DomainRegistry.get_knowledge_capital(id)` with explicit `{:error, :knowledge_capital_unavailable}`
- Do NOT create stubs or fake data
- Consumers become explicitly unavailable rather than silently broken

### C5: Establish portfolio boundary (7 sites)

- Replace `DomReg.get_portfolio_vector(id)` with explicit `{:error, :portfolio_unavailable}`
- Do NOT create stubs or fake data
- All 7 callers were already broken (nonexistent function)

### C6: Migrate DomainProjectionTest

- **RETIRE Test 1** (portfolio vector + knowledge capital — behavior was never real)
- **PRESERVE Tests 2-4** (Director behavior — migrate Director internals to use CanonicalRegistry)
- Tests 2-4 don't directly use DomReg — they test Director which uses DomainRegistry internally
- Migrate `Tiannara.Research.Director` to use `CanonicalRegistry` (this is part of C3)

### C7: Identity reclassification (limited scope)

- Only reclassify `:science`/`:mathematics` usages that are directly in the migration path
- Full reclassification is AC-001-E work
- For C: ensure no new canonical domain references use `:science` or `:mathematics`

---

## 8. Risks and Open Questions

| Risk | Severity | Mitigation |
|------|----------|------------|
| `all_records/0` adds new API surface to CanonicalRegistry | LOW | Justified by 9 consumers needing records. Atomic GenServer op, not N+1. |
| `ResearchDirector` has complex internal logic using domain records | MEDIUM | Must carefully refactor to use `all_records/0` without breaking allocation/neglect logic |
| `ExecutiveDashboard` uses `try/with` and error fallbacks | LOW | Replace `DomainRegistry.list_all()` with `CanonicalRegistry.all()` in the `with` chain |
| DomainProjectionTest retirement loses test coverage | LOW | Tests 2-4 preserved. Test 1 tested nonexistent behavior. |
| `:science`/`:mathematics` reclassification touches 50+ files | HIGH | Scoped to migration path only in C. Full reclassification in E. |
| Knowledge capital consumers will now explicitly fail | LOW (by design) | Better than silent `noproc` crash. Observable, repairable. |
| Portfolio consumers will now explicitly fail | LOW (by design) | Better than calling nonexistent function. Observable, repairable. |

---

*C0 semantic analysis complete. No mutation performed. Awaiting human review before C1 begins.*
