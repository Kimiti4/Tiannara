# Stage 6 Engine Contract Matrix — Stage 3/4/5 Invocation Path (Analysis Only)

**Date:** October 14, 2026
**Baseline commit:** `b2db80d4`
**Scope:** Source-derived contract mapping of `Stage3MethodEvolution`, `Stage4InstitutionAdaptation`, `Stage5CivilizationAdaptation` and their adjacent "real-path" modules, against a seven-dimension contract. **No code was changed. Certification remains blocked.**

## Headline finding

The three `StageN*` modules are simulation layers over simulation, not production engines. The genuinely-structured path (`InstitutionKernel.adapt_institution/2 -> InstitutionAdaptationPipeline.execute_pipeline/3`) also simulates its critical steps. The honest integration point is the **data layer (episode retrieval)**, not the stage-call layer: wiring the current stage modules into the runner would risk laundering synthetic inputs into apparently genuine execution evidence.

## Contract matrix

### Stage 3 — `TiannaraOS.Stage3MethodEvolution` (461 lines)

| Dimension | Finding | Evidence |
|---|---|---|
| Invocation | Pure function `execute_stage_3(dir, institution_id \\ :all, opts)`; no GenServer; zero callers in lib/test | `stage3_method_evolution.ex:35` |
| Inputs | Filesystem directory; reads `Mission_Control_History.csv`, else fabricates 100 default episodes | `:66-82`, `:188-202` |
| Outputs | Map of MethodEvolutionResult structs; input synthesized via weighted-random outcomes | `:104-158`, `:58-63` |
| Effects | Filesystem read only | whole file |
| Governance | None | grep: zero hits outside comments |
| Evidence | Fabricated: does not call MethodEvolutionPipeline (`:241-243`); hardcodes `evidence_quality: :strong` (`:399`); supporting episodes are its own synthetic IDs | `:270-291`, `:389-403` |
| Integration | None viable — would bury simulation one layer deeper | — |

Real pipeline note: `MethodEvolutionPipeline.execute_pipeline/3` (`method_evolution_pipeline.ex:29`) has retrieval that unconditionally returns `[]` — "Placeholder" (`:87-107`). Analysis math is real; data supply is stubbed.

### Stage 4 — `TiannaraOS.Stage4InstitutionAdaptation` (779 lines)

| Dimension | Finding | Evidence |
|---|---|---|
| Invocation | Pure function `execute_stage_4/3`; zero callers. Moduledoc's advertised `InstitutionKernel.adapt_institution/3` is actually arity 2 and routes to the pipeline module | `:78`; `institution_kernel.ex:436` |
| Inputs | MethodEvolutionResult structs; "provenance validation" checks only non-empty episode list + evidence tag — fabricated episodes pass | `:158-176` |
| Outputs | InstitutionAdaptationResult + decisions; non-deterministic (`:rand` in pilots) | `:567-641` |
| Effects | Pure in-memory; "pilot deployment" = 20 synthetic `:rand` episodes (`:379-421`) | — |
| Governance | Theater: `:governance_reviewed` appended unconditionally (`:680`); rollback plan formulaic with hardcoded `rollback_confidence: 0.85` (`:716-744`); no authorization | — |
| Evidence | Hardcoded 0.6 baselines (`:499`, `:701`); moduledoc "Nothing fabricated" (`:8`) contradicted by implementation | — |

Genuine path note: `InstitutionKernel.adapt_institution/2` handler (`institution_kernel.ex:726`) calls `InstitutionAdaptationPipeline.execute_pipeline/3`, which also simulates (`institution_adaptation_pipeline.ex:97`, `:226-230` incl. hardcoded string "Applied to 150 historical episodes"). `validate_governance/3` (def `:3822`) guards `spawn_campaign` only, **not** adaptation.

### Stage 5 — `TiannaraOS.Stage5CivilizationAdaptation` (589 lines)

| Dimension | Finding | Evidence |
|---|---|---|
| Invocation | Pure function `execute_stage_5/3`; zero callers | `:49` |
| Inputs | InstitutionAdaptationResult structs; structural checks incl. `rollback_available` which defaults `true` in `new/2` — near-vacuous | `:146-163`; `institution_adaptation_result.ex:214` |
| Outputs | CivilizationAdaptationResult; **deterministic** (no `:rand` in module) | whole file |
| Effects | None; rollout plan formulaic (TODO admits stubbed helpers `:487-488`) | `:486-538` |
| Governance | Structural compliance check only | `:126-132`; `institution_adaptation_result.ex:591-609` |
| Evidence | Honest relative to inputs, but inputs contain synthetic pilots/hardcoded baselines (garbage-in, clean pedigree) | `:232-302` |
| Integration | Smallest adapter of the three (only genuinely computational module) | — |

Parallel-path note: `CivilizationAdaptationPipeline` (818 lines, called from `civilization_kernel.ex`) fabricates institutional improvements with `:rand.uniform()` (`civilization_adaptation_pipeline.ex:167-181`) — worse than the Stage 5 module.

## Runner compatibility (why wiring is not a swap)

| Runner output (`recursive_civilization_runner.ex:229-302`) | Engine expects | Gap |
|---|---|---|
| stage3 plain maps | Stage 3 wants a directory; MethodEvolutionPipeline wants populated EpisodeIndex | incompatible both ways |
| stage4 plain maps, `constitutional_compliance: true` boolean, no `rollback_available` | Stage 5 wants `%{is_compliant: true}` map, `rollback_available`, `stage_history >= 7` | naive rewiring yields **zero validated adaptations**, silently |
| stage5 plain maps, `Enum.random`-derived values | downstream reads same-named fields | structurally closest, values synthetic |

## Data-layer blocker

1. `EpisodeIndex` is a pure struct (`episode_index.ex:44-52`; `new/1:90`, `add_entry/2:113`), populated by `InstitutionKernel` at episode creation.
2. `MethodEvolutionPipeline.retrieve_episodes_for_analysis/2` unconditionally returns `[]` (`method_evolution_pipeline.ex:87-107`) regardless of population.
3. Therefore every "real" pipeline analyzes zero episodes, and empty analysis still yields confident-looking labels — silent failure mode.

## Smallest proposed integration sequence (proposal)

1. Un-stub retrieval behind explicit tests (real EpisodeIndex → episodes; empty → distinguishable no-evidence).
2. Reassess Stage 3/4 modules: retire or mark simulation-only (approval required; zero callers).
3. Wire Stage 5 only, on explicitly labeled simulated inputs, recorded as SIMULATED.
4. Real Stage 3 only after runner episodes become ResearchEpisode records registered in EpisodeIndex.
5. Governance before any Stage 4 authority: extend `validate_governance` to adaptation + effect ledger (mirror `5accf21a` physics-pilot pattern).
6. Certification stays blocked until gate items 1-4, 6, 7 are independently evidenced.

## Explicitly unknown

- Whether `CivilizationKernel`'s call to `CivilizationAdaptationPipeline.execute_pipeline` is reachable in production startup.
- Whether any runtime caller constructs Stage3/4/5 modules via dynamic module resolution (inventory scan advisory only).
- Completeness/provenance semantics of `KnowledgeGraph.get_episode/1` (next source-level question).
- Whether `validate_governance/3` would permit adaptation-class actions.

## Outcome

Analysis only. No runner wiring, no adaptation authorization, no certification change. Next implementation target: the Stage 3 data-retrieval contract (`certification/audit/` deliverable; implemented separately).
