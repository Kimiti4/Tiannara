# GenServer Inventory Reconciliation — Missed-Reference Verification

**Date:** October 14, 2026
**Input:** `GENSERVER_OWNERSHIP_INVENTORY.csv` — 146 rows flagged by the supplementary last-segment scan (88 from `2_started_no_other_callers`, 58 from `6_no_refs_at_all`).
**Output:** `GENSERVER_RECONCILIATION.csv` — per-row verified evidence and reclassification.
**Scope:** Reclassification only. **No module was retired, moved, or deleted.**

## Method

For each flagged row, the verification checked (in order):

1. **Direct call usage** — full module name used as a call qualifier (`Mod.func`) or struct (`%Mod{`) in the flagged file. Bare string presence (comments/docs) does **not** count.
2. **Alias-context reference** — an `alias <prefix>` line matching a proper prefix of the module path, plus unqualified remainder usage in the same file (`alias Tiannara.A.B` + `C.func(...)`), including `as:` renames. Full-module aliases whose bare last segment is used are recorded but tagged `segment-collision-risk` (weak evidence; shared segment names like `Registry`/`Engine` collide).
3. **Supervisor children-list evidence** — bare-module entries in any `*supervisor*.ex` children list (`{Mod, args}` or `Mod,`), a start pattern the original inventory's `start_link`-only scan missed.
4. **Application/config references** — full module name in `application.ex` or `config/*.exs`.
5. **Dynamic-resolution advisory** — `Module.concat` / `String.to_atom` / `String.to_existing_atom` co-occurring with the module's last segment in the flagged file (requires manual review).

## Results (146 rows)

| Reclassification | Count | Meaning |
|---|---|---|
| `confirmed_owned_with_alias_callers` | 31 | Supervised **and** flagged files really call it — original caller count was an undercount |
| `confirmed_referenced_no_start_path` | 33 | Real callers found; no start path — libraries or runtime-created processes, not dead |
| `supervised_via_children_list_no_callers` | 39 | Started via bare-module children list (missed start pattern); no callers found |
| `confirmed_zero_evidence` | **35** | No callers, no start path, no app/config, no dynamic pattern — strongest retirement candidates |
| `dynamic_resolution_possible_manual_review` | 6 | Dynamic-module construction possible; manual review required |
| `referenced_in_app_or_config` | 2 | Started or wired via `application.ex`/config |

### By original class

| Original class | Owned+callers | Referenced, no start | Children-list start | Zero evidence | Dynamic review | App/config |
|---|---|---|---|---|---|---|
| `2_started_no_other_callers` (88) | 31 | 16 | 39 | 0 | 1 | 1 |
| `6_no_refs_at_all` (58) | 0 | 17 | 0 | 35 | 5 | 1 |

## Key findings

1. **The original full-token scan undercounts real callers.** 64 flagged rows (31 + 33) were verified to have genuine direct or alias-context callers the scan missed. Treat every `ProdCallers` value in the original inventory as a **lower bound**, including on unflagged rows.
2. **A start pattern was systematically missed.** 39 rows are started via bare-module children-list entries that the `start_link`-only detection did not see (including 5 rows misclassified with empty `StartSites` despite supervisor entries: Council's ConstitutionalMonitor/ConstitutionRepository/PolicyRegistry, Sentinel's HumanCollaboration, and `Tiannara.Sandbox`).
3. **Only 35 of the original "98 no-refs" survive as true zero-evidence candidates** after verification. They remain candidates for retirement review — not proven unused (runtime-only entry points can still exist), and **no retirement has been performed**.
4. **6 rows need manual review** for dynamic module construction (`Module.concat`/`String.to_atom` co-occurrence): notably `Tiannara.CEL.Services.CapabilityRegistry` (3 files), `Tiannara.OS.PrincipleRegistry` and `Tiannara.Council.PrincipleRegistry` (both via `council/rule_engine.ex`), `TiannaraOS.CivilizationRuntime`, `TiannaraOS.ResearchEconomy`, `Tiannara.ASC.Research.Director`.

## The 35 zero-evidence candidates

```
Tiannara.ASC.Executive.PortfolioManager
Tiannara.ASC.Interface.EvolutionEngine
Tiannara.ASC.MetaLearning.Civilization
Tiannara.Autonomy.ConstitutionalAutonomy.Orchestrator
Tiannara.CEL.EventBus
Tiannara.CEL.Metrics
Tiannara.CEL.MissionDirector
Tiannara.CEL.Planner
Tiannara.Certification.Protocol
Tiannara.Executive.Cognitive.AttentionScheduler
Tiannara.Executive.Cognitive.ContextManager
Tiannara.Executive.Cognitive.HeartbeatEngine
Tiannara.Executive.Cognitive.WorkingMemory
Tiannara.Forecasting.DecisionRegistry
Tiannara.Forecasting.SignalRegistry
Tiannara.Graph.Persistent
TiannaraOS.Governance.Validation.AdapterRegistry
TiannaraOS.Governance.DeploymentOrchestrator
TiannaraOS.Governance.GovernanceEntropyTracker
TiannaraOS.Governance.ProposalLedger
TiannaraOS.Governance.RFCRegistry
TiannaraOS.ConstitutionalWatchdog
TiannaraOS.ConstitutionDashboard
TiannaraOS.DiscoveryRegistry
TiannaraOS.LawRegistry
TiannaraOS.ProgramRegistry
TiannaraOS.ProvenanceTracker
TiannaraOS.ResearchDirector
TiannaraOS.TheoryRegistry
TiannaraOS.UnknownDependencyGraph
Tiannara.REA.Epistemic.EcologicalMemory
Tiannara.Research.ResearchDirector.Pipeline
Tiannara.Sentinel.ObservationScheduler
Tiannara.World.ConflictResolver
Tiannara.World.WorldConsistencyValidator
```

Note: `Tiannara.Sentinel.ObservationScheduler` appears here, yet `lib/tiannara/sentinel/observation_scheduler.ex` exists and `observation_scheduler.ex` is referenced elsewhere as a *caller file* in the original inventory. Verify module-name vs file-name drift before any action on this row.

## Caveats

- Alias-context verification is heuristic (regex, not a compiler-aware pass). High-confidence rows use prefix aliases; full-module-alias rows are tagged collision-risk and were not promoted on that evidence alone.
- "Zero evidence" means zero **static** evidence in `lib/`, `test/`, `config/`, and `application.ex` at this commit. External callers (other repos, release scripts, IEx procedures) are out of scope.
- The 39 children-list rows are running processes; retiring them is a runtime-behavior decision, not a dead-code decision.
