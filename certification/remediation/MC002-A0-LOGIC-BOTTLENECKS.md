# MC-002-A0 — Logic Bottleneck Analysis

**Gate:** MC-002-A0 (Observational) — READ-ONLY

## Ranked bottlenecks

| Rank | Bottleneck | Evidence | Why it matters |
|------|-----------|----------|----------------|
| **CRITICAL** | Broken `BeliefSystem` negation matcher feeds Loop B silently-wrong | `lib/tiannara/core/world_model/belief_system.ex:345-356`; consumed by `core/world_model/api.ex:39,71` | Produces false-positive/negative contradictions as if correct; discovery question-stream inherits the error. Silent wrongness is the worst epistemic hazard. |
| **CRITICAL** | Dangling `Audit.find_contradictions/1` at constitution probe | `lib/tiannara/constitution/registry.ex:118` vs `graph/audit.ex` (no such fn) | Governance probe crashes (`UndefinedFunctionError`) if reached; constitutional invariant suite cannot run that check. |
| **HIGH** | No canonical logic kernel; ≥5 duplicate contradiction impls + 2 conflict resolvers with diverging semantics | inventory sites; `TIANNARA_LOGIC_ARCHAEOLOGY.md:15-29` | No single semantics the system/certification can point to; duplicated code drifts (broken vs sound). Blocks truthful compositionality. |
| **HIGH** | Theatrical logical capability across substrate + CTL | `substrate/*.ex`; `ctl/paradox_resolver.ex:7-24`; `osk.ex:85-89` | Returns `:ok`/fabricated metrics for logic operations that don't compute → suite treats them as capability. Same fabrication pattern MC-001 removed from math. |
| **MEDIUM** | No proof object/checker or SAT/SMT layer | absence established in inventory | Prevents any honest claim of formal verification / theorem proving; not needed for the bounded kernel but blocks the "vision" layer. |
| **MEDIUM** | No symbolic representation layer | absence confirmed | Prevents term manipulation / rewriting / inference over formulas. |
| **MEDIUM** | Invariant aggregators inconsistent (first-fail vs collect-all) | architecture assessment; archaeology §2 | Diverging failure semantics across governance gate evaluation. |
| **LOW** | ContradictionAnalyzer heuristic impact | `discovery/contradiction_analyzer.ex` | Adds decision weight with estimated impact; acceptable within discovery, not as verification. |

## Cross-cutting

- **Unavailable-is-success risk:** substrate modules return `:ok` for no real work.
  Must be decommissioned (L2) and/or have explicit unavailable states (L4) like MC-001-M.
- **Shadow-run requirement:** since contradictions feed Loop B question-stream directly
  (`discovery_scheduler.ex:259-267`), any kernel cutover must diff the question stream.
- **Dependency on MC-001:** no logic path may assume formal verification / ODE /
  optimization availability (all now `{:error, :*_unavailable}`). Confirmed: no
  current logic site calls them as if available.