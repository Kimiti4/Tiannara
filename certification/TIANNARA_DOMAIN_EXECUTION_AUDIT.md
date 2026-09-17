# Tiannara Domain Execution Audit (incl. AC-001 Registry Contradiction)

Campaign: Remediation Architecture & Epistemic Foundation Certification (READ-ONLY)
Baseline commit: `3bd1601b9bb3c718f985d44ceaa8ef2e638d4ec6`
Scope: resolve **MC-004** (domain execution; prior register MC-001) and **AC-001** (DomainRegistry ontology mismatch).

---

## 1. AC-001 — The registry contradiction, verified and extended

Two divergent registries claim authority over the same concept:

| Aspect | `lib/tiannara/domains/registry.ex` | `lib/tiannara/os/domain_registry.ex` |
|---|---|---|
| Canon | `@domains` = **20 module atoms** incl. Physics, Chemistry (:4-25) | `@twenty_domains` = 20 ids incl. **`:science` and `:mathematics`**, EXCLUDING `:physics`/`:chemistry` (:83-104) |
| API | Only `all_domains/0` (:27), `domain_names/0` (:29-33) | Full GenServer API (`get`, `add_program`, `record_activity`, ...) |
| Runtime | Static compile-time list; no process | GenServer defined (`start_link` :111) but **never started anywhere** |
| Mutation | Impossible | Mutators `add_program/2` (:182), `record_activity/3` (:197) have **zero callers** → `knowledge_capital` map (:315-327) permanently zeros |

**Consequences verified:**
1. **Phantom domains:** `asc/research_bridge.ex` seeds research programs under `:science` and `:mathematics` — ids that have NO implementing module and NO live registry entry.
2. **Orphan module:** `lib/tiannara/domains/computer_science.ex` self-registers id `:cs`; neither registry contains it; overlaps existing `:computation`.
3. **~14 crash-path call sites:** web LiveViews and services call `Tiannara.Domains.Registry.get_domain/1`, `list_domains/0`-style APIs **that do not exist** on that module → any runtime hit raises UndefinedFunctionError.
4. **Observatory shim:** `observatory/metrics/domains.ex` hardcodes metric numbers rather than reading either registry.
5. Per the target architecture ratified for this campaign, Mathematics is an **epistemic substrate** and Science a **methodology**, not members of the 20-domain set.

## 2. Domain execution reality

All 20+1 domain modules (`lib/tiannara/domains/*.ex`) are universal stubs:
- `generate_hypotheses/2` → `{:ok, []}`
- `design_experiments/3` → `{:ok, []}` (hardcoded empty metric structs where present)
- No domain executes or produces evidence today.

Partial real math inside domains (from MC-001 audit): chemistry uses real `Graphs.shortest_path/3`; economics consumes mocked `nash_equilibrium/2`; physics declares mock `solve_ode`.

## 3. First-domain activation recommendation

**Pilot domain: PHYSICS.** Rationale:
- Richest existing integration surface: `Probability.bayes_update` consumers, ODE slot awaiting implementation, targeted by the (orphaned) ASC hardcoded experiment list (`asc/autonomous_discovery.ex:55-61`) — replacing that hardcode with registry-driven selection kills two defects at once.
- Divergence-measurement executor (`Discovery.Steps.ExperimentStep`) is already domain-agnostic over world-model entities; physics observations are seedable.
- Clear acceptance signal: gravity-style hypothesis → prediction → measured divergence → verdict, end-to-end via Phase4 orchestrator.

Sequence: **Physics pilot → Chemistry second** (real graph kernel already used) → **first cross-domain pair ecology→economics** via existing TransferMatrix seed row (0.80) to satisfy CEL-1 style cross-pollination acceptance.

## 4. AC-001 resolution proposal (for remediation phase)

1. Canonical ontology = OS `@twenty_domains` **minus** `:science`, `:mathematics` **plus** `:physics`, `:chemistry` (restores 20; aligns with substrate/methodology reclassification).
2. Resolve ComputerScience orphan: merge into `:computation` (delete module) or register as alias — decide at remediation review.
3. Start `DomainRegistry` GenServer in supervision tree; wire mutators to actual program/activity events.
4. Reconcile `Domains.Registry` into a thin adapter over OS registry (single source of truth); fix all ~14 nonexistent-API call sites.
5. Redirect `asc/research_bridge.ex` phantom seeds to canonical ids.
6. Replace observatory shim hardcode with registry reads.

## 5. Acceptance tests (proposed)

- D-AT-1: exactly one domain ontology in code; grep finds no `:science`/`:mathematics` domain registrations; `:physics`/`:chemistry` present.
- D-AT-2: DomainRegistry started; `add_program/record_activity` invoked by ≥1 live path; knowledge_capital reflects recorded activity after a Loop-B cycle.
- D-AT-3: all LiveView/service calls resolve against the unified registry API (no UndefinedFunctionError paths).
- D-AT-4: Physics pilot executes one full lifecycle stage-chain through Phase4 orchestrator with Tier-2-or-better evidence (links MC-003 P16-AT).
- D-AT-5: ecology→economics transfer event recorded with provenance (seed row exercised, not hardcoded output).

## 6. Risks

- Ontology swap breaks stored references keyed by old ids → migration map required before cutover.
- Domain activation before MC-003 quarantine would let fake executors masquerade as domain science → ordering constraint enforced in dependency graph.
