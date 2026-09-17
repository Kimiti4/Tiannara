# AC-001-A0: Pre-Mutation Repository Reconciliation

**Gate:** AC-001 (Canonical Domain Ontology)
**Sub-phase:** A0 (Discovery before Design)
**Status:** COMPLETE
**Generated:** 2026-08-25
**Protocol:** User-locked pre-mutation reconciliation — no code mutation authorized until this artifact is complete and the canonical registry contract is frozen from evidence.

---

## 1. Scope

This reconciliation answers 15 discovery questions about the **actual** state of domain identity, registry ownership, knowledge capital, and API callers in the repository. All answers are backed by file:line evidence. This artifact is the prerequisite for AC-001-A (first mutation).

---

## 2. Registry Inventory

### 2.1 Two Registries Exist

| Registry | Module | Type | File | Line |
|----------|--------|------|------|------|
| **Domains.Registry** | `Tiannara.Domains.Registry` | Compile-time `@domains` module attribute | `lib/tiannara/domains/registry.ex` | 1–34 |
| **DomainRegistry** | `TiannaraOS.DomainRegistry` | GenServer (DETS-backed) | `lib/tiannara/os/domain_registry.ex` | 1–360 |

### 2.2 Neither Registry Is Started

`lib/tiannara/application.ex` (lines 73–188) defines `core_children/0`. Neither `TiannaraOS.DomainRegistry` nor `Tiannara.Domains.Registry` appears in the supervision tree. The only domain-related child is `Tiannara.Domains.ResearchDirector` (line 163).

**Consequence:** `TiannaraOS.DomainRegistry` GenServer never starts. All `GenServer.call` to it would crash with `noproc`. `Tiannara.Domains.Registry` is compile-time (no process needed), but its API surface is incomplete (see §4).

---

## 3. Domain Atom Inventory

### 3.1 `TiannaraOS.DomainRegistry.@twenty_domains` (line 83–104)

```elixir
[:engineering, :medicine, :governance, :computation, :science,
 :agriculture, :energy, :logistics, :cognition, :materials,
 :robotics, :economics, :philosophy, :sociology, :linguistics,
 :aerospace, :ecology, :cybernetics, :architecture, :mathematics]
```

Contains `:science` and `:mathematics`. Missing `:physics` and `:chemistry`.

### 3.2 `Tiannara.Domains.Registry.@domains` (line 4–25)

Lists 20 module atoms. Includes `Tiannara.Domains.Physics` and `Tiannara.Domains.Chemistry`. Does NOT include any "science" or "mathematics" module. Extracts domain names via `to_string() |> String.split(".") |> List.last() |> String.to_atom()` — producing atoms like `:Physics`, `:Chemistry` (PascalCase), NOT `:physics`, `:chemistry` (snake_case).

**Critical mismatch:** `DomainRegistry` uses snake_case atoms (`:physics`), `Domains.Registry` would produce PascalCase atoms (`:Physics`). No consumer uses PascalCase domain atoms.

### 3.3 `ComputerScience` — Orphaned

`lib/tiannara/domains/computer_science.ex:7` — returns `%{domain: :cs, ...}`. The atom `:cs` is never used as a domain identifier by any other module. grep for `:cs\b` returns only this one match. `ComputerScience` is listed in `Domains.Registry.@domains` but is completely disconnected from the rest of the system.

### 3.4 `:science` — Pervasive but Incorrect

`:science` appears as a domain atom in **26 files** across the codebase (immune_system, civilization, domain_cortex, leoc, discoveries, web LiveViews, domain_registry, domain_profile, governance modules, program_registry, world_manager, etc.).

Per the user-ratified canonical ontology, `:science` is a **methodology**, not a domain. All 26 references must be reclassified.

### 3.5 `:mathematics` — Pervasive, Substrate Classification Disputed

`:mathematics` appears in **30+ files** as a domain atom. Per user instruction, mathematics is a **substrate**, not a domain. However, it is deeply embedded in domain lists, governance institutions, program registries, and knowledge graphs.

**User-decided resolution:** `:mathematics` must be reclassified as substrate. Domain identity must be separated from substrate identity.

---

## 4. API Caller Analysis

### 4.1 `TiannaraOS.DomainRegistry` (GenServer — never started)

| API | Callers (outside self) | Files |
|-----|----------------------|-------|
| `list_all/0` | **15** | research_director.ex:3, mission_control.ex:2, executive_dashboard.ex:3, civilization_atlas.ex:7 |
| `get_knowledge_capital/1` | **5** | civilization_atlas.ex:2, research_director.ex:1, mission_control.ex:1, institution_self_model.ex:1 |
| `get/1` | **1** | civilization_atlas.ex:1 |
| `get_all_domain_ids/0` | **0** | — |
| `add_program/2` | **0** | — |
| `record_activity/3` | **0** | — |
| `start_link/1` | **0** | Never started in supervision tree |

**All 21 callers would crash at runtime** (`noproc` — GenServer never started).

### 4.2 `Tiannara.Domains.Registry` (compile-time)

| API | Callers | Files |
|-----|---------|-------|
| `all_domains/0` | **0** | — |
| `domain_names/0` | **0** | — |
| `all/0` | **3** | civilization_dynamics_live.ex:1, portfolio_dynamics.ex:1, goal_ecology.ex:1 |
| `get_knowledge_capital/1` | **1** | portfolio_dynamics.ex:1 |
| `get_portfolio_vector/1` | **1** | goal_ecology.ex:1 |

**Critical:** `Domains.Registry` does NOT define `all/0`, `get_knowledge_capital/1`, or `get_portfolio_vector/1`. These calls would raise `UndefinedFunctionError` at runtime. The `Code.ensure_loaded?` guards pass (module is compiled), but the functions don't exist.

### 4.3 Summary: Dead APIs

| API | Status |
|-----|--------|
| `DomainRegistry.add_program/2` | Zero callers — dead code |
| `DomainRegistry.record_activity/3` | Zero callers — dead code |
| `DomainRegistry.get_all_domain_ids/0` | Zero callers — dead code |
| `DomainRegistry.start_link/1` | Zero callers — never supervised |
| `Domains.Registry.all_domains/0` | Zero callers — dead code |
| `Domains.Registry.domain_names/0` | Zero callers — dead code |
| `Domains.Registry.all/0` | 3 callers — **function does not exist** |
| `Domains.Registry.get_knowledge_capital/1` | 1 caller — **function does not exist** |
| `Domains.Registry.get_portfolio_vector/1` | 1 caller — **function does not exist** |

---

## 5. Knowledge Capital Ownership

### 5.1 Who Owns Knowledge Capital Data?

`TiannaraOS.DomainRegistry` stores `knowledge_capital` as part of its in-memory domain state (line 65, 76, 307, 315). The `initialize_knowledge_capital/0` function (line 315) creates the initial map.

**But the GenServer is never started.** So this data store is completely inert.

### 5.2 Who Reads Knowledge Capital?

Five modules call `DomainRegistry.get_knowledge_capital/1`:
- `TiannaraOS.CivilizationAtlas` (lines 188, 486)
- `TiannaraOS.ResearchDirector` (line 460)
- `TiannaraOS.MissionControl` (line 414)
- `TiannaraOS.InstitutionSelfModel` (line 574)

All would crash at runtime due to `noproc`.

### 5.3 Who Writes Knowledge Capital?

Zero external callers of `add_program/2` or `record_activity/3`. The only writes would be internal to the GenServer's `handle_call` callbacks — which never execute.

### 5.4 Who Reads Portfolio Vectors?

Six callers of `get_portfolio_vector/1` (via `DomReg` alias or direct module reference):
- `Tiannara.ASC.ResearchBridge` (line 140)
- `TiannaraWeb.MissionControlLive` (line 44)
- `TiannaraWeb.DomainDetailLive` (line 18)
- `TiannaraWeb.DomainsLive` (line 14)
- `TiannaraWeb.CivilizationAtlasLive` (line 136)
- `Tiannara.REA.Epistemic.GoalEcology` (line 224)

These call through `Domains.Registry.get_portfolio_vector/1` — which does not exist.

---

## 6. Supervision Tree Analysis

### 6.1 Domain-Related Children in `application.ex`

| Child | Line | Status |
|-------|------|--------|
| `Tiannara.Domains.ResearchDirector` | 163 | Started (separate from `TiannaraOS.ResearchDirector`) |
| `Tiannara.Research.ResearchDirector` | 175 | Started (R0-certified) |

**Neither domain registry is supervised.**

### 6.2 Implications

The canonical registry must either:
1. Be added to the supervision tree (new child), OR
2. Replace an existing unsupervised module

Since both registries are currently unsupervised dead code, option (1) is cleaner — no migration needed, just boot the new canonical registry.

---

## 7. ComputerScience Resolution

`Tiannara.Domains.ComputerScience` (`lib/tiannara/domains/computer_science.ex`):
- Returns `%{domain: :cs}` — atom never consumed elsewhere
- Listed in `Domains.Registry.@domains` — but `all_domains/0` has zero callers
- Has a `@behaviour Tiannara.Domains.Domain` — but no module calls this behaviour's callbacks
- Uses `InformationTheory.shannon_entropy/1` — this function exists in `Tiannara.Foundations.InformationTheory`

**Resolution (evidence-based):** `ComputerScience` is an orphan. The user must decide:
- **Option A:** Merge into `:computation` (the canonical domain). Delete `computer_science.ex`.
- **Option B:** Reclassify as a separate domain with atom `:computer_science` (not `:cs`). Add to canonical 20.
- **Option C:** Classify as a substrate (like mathematics). Remove from domain list entirely.

---

## 8. Canonical Registry Contract Boundary (Frozen)

Based on reconciliation evidence, the minimum canonical registry must own:

### 8.1 IN SCOPE (must be in canonical registry)
- **Domain identity** — canonical atom, display name, description
- **Domain metadata** — maturity tier, epistemic posture, substrate requirements
- **Module binding** — which `Tiannara.Domains.*` module implements this domain
- **Lifecycle** — active/suspended/archived status
- **Ontology version** — which version of the domain list this registry reflects

### 8.2 OUT OF SCOPE (must NOT be in canonical registry)
- **Knowledge capital** — theories, discoveries, laws, applications, unknowns. Callers exist (5 modules) but data store is inert. Knowledge capital should remain a separate service that the registry does NOT own. Callers should migrate to a dedicated knowledge capital store.
- **Portfolio vectors** — diversity metrics, research allocation vectors. 6 callers exist. Should remain a separate service.
- **Research metrics** — discovery rates, validation success, innovation velocity. Consumers (mission_control, executive_dashboard) compose these from multiple sources. Registry should not absorb this.
- **Program management** — `add_program/2` has zero callers. Dead API. Do not carry forward.
- **Activity recording** — `record_activity/3` has zero callers. Dead API. Do not carry forward.

### 8.3 MIGRATION REQUIRED
- 21 callers of `DomainRegistry` GenServer (all would crash) → must be redirected to new canonical registry or appropriate service
- 5 callers of nonexistent `Domains.Registry` functions → must be redirected
- `:science` atom → must be reclassified (26 files)
- `:mathematics` atom → must be reclassified as substrate (30+ files)
- `ComputerScience` → must be resolved (user decision required)

---

## 9. Risk Register

| Risk | Severity | Evidence |
|------|----------|----------|
| GenServer never started — 21 callers crash at runtime | **CRITICAL** | `application.ex` lines 73–188, no `DomainRegistry` child |
| `Domains.Registry.all/0` called but undefined | **HIGH** | `civilization_dynamics_live.ex:474`, `portfolio_dynamics.ex:535`, `goal_ecology.ex:130` |
| `:science` misclassified as domain (26 files) | **HIGH** | User-ratified ontology: science is methodology |
| `:mathematics` misclassified as domain (30+ files) | **HIGH** | User-ratified ontology: mathematics is substrate |
| `ComputerScience` orphaned (`:cs` atom unused) | **MEDIUM** | `computer_science.ex:7`, zero consumers of `:cs` |
| DomainRegistry `@twenty_domains` missing `:physics`, `:chemistry` | **MEDIUM** | `domain_registry.ex:83–104` |
| Domains.Registry produces PascalCase atoms | **LOW** | `registry.ex:30–32` — but zero callers use result |
| `add_program/2`, `record_activity/3`, `get_all_domain_ids/0` dead | **LOW** | Zero callers confirmed |

---

## 10. Recommendations for AC-001-A

1. **Create canonical `Tiannara.Domains.Registry` GenServer** — single source of truth for domain identity, metadata, module binding, lifecycle, ontology version. Add to supervision tree.
2. **Delete `TiannaraOS.DomainRegistry`** — GenServer never started, all callers crash, dead mutator APIs. Replace with new canonical registry.
3. **Delete `ComputerScience`** — orphaned module, `:cs` atom unused. If computation domain needs computer science capabilities, merge into `Tiannara.Domains.Computation`.
4. **Do NOT absorb knowledge capital or portfolio vectors** into canonical registry — keep these as separate services. Redirect 21+5 callers to appropriate service.
5. **Reclassify `:science`** — 26 files must be updated to use correct domain atoms.
6. **Reclassify `:mathematics`** — 30+ files must be updated. Mathematics becomes substrate, not domain.
7. **Freeze ontology version** — canonical registry should declare `ontology_version: "2.0"` reflecting the user-ratified 20-domain + substrate classification.

---

## 11. Authorization

This reconciliation is a **read-only discovery artifact**. No code mutations were made. All evidence gathered via grep, read, and search tools.

**Next step:** User reviews this reconciliation, confirms contract boundary, then authorizes AC-001-A (first mutation: canonical registry implementation).

---

*AC-001-A0 complete. Awaiting user review and AC-001-A authorization.*
