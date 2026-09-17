# MC-002-A0 — Logic Consumer Map

**Gate:** MC-002-A0 (Observational) — READ-ONLY
**Format:** producer → consumer contracts, control-flow, failure behavior.
The MC-001-M precedent: an unavailable epistemic capability must never be
interpreted as successful validation.

## Producer: Contradiction.Engine (REAL)

Produced capability: `detect/1` (list of claims → list of `%Record{}` conflict
records), plus lifecycle helpers.

| Consumer | Location | Expected contract | Actual contract | Outcome if changed |
|----------|----------|-------------------|-----------------|--------------------|
| `Tiannara.Contradiction.dry_run` | `lib/tiannara/contradiction/dry_run.ex:77` | `case Engine.detect(claims)` | `Engine.detect/1` | Depends on `{:ok,_}/{:error,_}`-style atoms & Records; the `to_epistemic_event/1` path at `:49` |

## Producer: Graph.Audit (REAL, canvas)

Produced capability: `lineage/2`, `blast_radius/2`, `has_cycle?/1`.

| Consumer | Location | Notes |
|----------|----------|-------|
| (No production caller found by name) | — | The `blast_radius` matches found (`CapabilityGraph`, `UnifiedRealityGraph`) are different modules. `Graph.Audit` is currently UNCONSUMED in production logic paths; used in tests/demos only. Canvas-ready; safe kernel seed. |

## Producer: BeliefSystem (BROKEN contradiction path)

Produced capability: `add_belief/4` → runs `check_for_contradictions/2`
(`belief_system.ex:270`), which calls the broken negation matcher
(`are_direct_contradictions?/2`, `:345-356`).

| Consumer | Location | Hazard |
|----------|----------|--------|
| `Tiannara.Core.WorldModel.Api` | `lib/tiannara/core/world_model/api.ex:39,71` | `add_belief`, `get_high_confidence_beliefs`. Broken matcher yields false positives/negatives; can flag non-contradictory beliefs or miss real ones. In Loop B (discovery/question generation) this distorts the belief/contradiction stream. |

## Producer: Discovery.ContradictionAnalyzer (REAL/PARTIAL)

Produced capability: `analyze/1` (classify + rank contradictions by impact).

| Consumer | Location | Role |
|----------|----------|------|
| `DiscoveryScheduler.run_cycle/1` (Loop B) | `lib/tiannara/discovery/discovery_scheduler.ex:259-267` | `conflicts → ContradictionAnalyzer.analyze → contradiction_gaps → all_gaps → discoveries`. **Contradictions feed the discovery question-stream directly.** |
| `EpistemicSeeder` | `lib/tiannara/discovery/epistemic_seeder.ex:241` | `ContradictionAnalyzer.analyze` on seeder report. |

## Producer: constitution/registry.ex B1 (dangling)

Site: `lib/tiannara/constitution/registry.ex:118` calls `Audit.find_contradictions(g)`.

| Consumer | Location | Hazard |
|----------|----------|--------|
| Constitutional invariant suite / registry probes | `lib/tiannara/constitution/registry.ex` (probe functions `:110-121`) | `Graph.Audit` has no `find_contradictions/1` → `UndefinedFunctionError` if the probe executes. Governance-adjacent path; would surface as a crash, not silent wrongness. |

## Producer: Sentinel.Verification (REAL, private)

Produced capability: private `find_contradictions/3`.

| Consumer | Location | Notes |
|----------|----------|-------|
| Within `Sentinel.Verification` itself | `lib/tiannara/sentinel/verification.ex:169` | Internal use; risk isolation. Would be wrapped by a kernel adapter. |

## Autonomy failure-mode check (MC-001-M precedent)

Could Tiannara interpret an unavailable/broken logical capability as successful
validation?

- `BeliefSystem` broken matcher: returns a (wrong) Boolean, does NOT raise — so a
  bad resolution can be silently accepted into the belief/contradiction stream.
  This is the closest to the MC-001 "unavailable-as-validation" hazard, but as
  `false/true` misclassification rather than `verified: true`.
- `registry.ex:118` B1: raises (fail-loud) — safer than silent; still must be fixed.
- Substrate theatrical modules: return `:ok`/push fabricated metrics — treated as
  success by callers that ignore the absence of real computation.

## Certification significance of consumers

- Loop B (DiscoveryScheduler) is the highest-impact logical consumer: kernel
  adoption changes the question stream → shadow-run first (per register L-AT risk)
  before any mutation.
- Governance (constitution probes) depends on the dangling fix.
- World-model API (BeliefSystem) depends on the broken matcher replacement.
