# TCP-002 — The Cognitive Execution Spine

**Checkpoint:** TCP-002 — W0: Cognitive Capability Activation
**Status:** ACTIVE — TCP-002.1 and TCP-002.2 delivered; TCP-002.3…002.6 open
**Date:** 2026-11-12

---

## 1. What the Spine is

The Cognitive Execution Spine is **the integration contract through which
Tiannara's existing cognitive subsystems cooperate**. It is deliberately *not* a
subsystem:

- it contains **no reasoning of its own** — every stage is a call into an engine
  that already exists;
- it does not compete with the existing architecture — it sequences it;
- it does not replace the constitutional authority — it *asks* for a mandate
  through a port that, by default, refuses.

It exists because TCP-002.1 measured a specific and surprising condition:

> **336 runtime modules — 24 % of the runtime — contained substantial,
> implemented capability that no process ever called.**

The failure was not missing capability. It was missing *composition*.

## 2. TCP-002.1 finding: the activation problem is not a supervision problem

`tools/tcp/tcp002_activation_map.py` classifies every module in
`tiannara_runtime/lib/tiannara_runtime/{cognitive,world_model}`.

| Kind | Modules |
|---|---|
| `library` | 282 |
| `behaviour` | 38 |
| `behaviour_implementation` | 16 |
| `struct_only` | 2 |
| `genserver` | **1** (the Spine host, added by TCP-002.2) |

**Before TCP-002.2, not one of the 336 was a process.** They are stateless
library functions and behaviour contracts. Supervision is therefore not the
activation mechanism for any of them — there is nothing to supervise. The
activation mechanism is **composition**: a governed sequence in which one
engine's output becomes the next engine's input.

### 2.1 Role split — capability vs data plumbing

| Role | Modules | Meaning |
|------|---------|---------|
| `engine` | 154 | Exposes a real operation: delegates to another module or transforms data. **Candidate capability.** |
| `value_object` | 40 | Constructors, validators, fingerprints. Real code, but data. |
| `scaffold` | 107 | A struct or constructor with nothing else. |
| `behaviour_contract` | 38 | A callback contract needing an implementation (29 have none). |

The role split exists so that *"the module is reachable"* can never be mistaken
for *"the capability works"*. Only the 154 engines are candidate capability,
and each must still be shown to do the work it claims.

### 2.2 Reachability, before and after

| Measure | TCP-002.1 | After TCP-002.2 |
|---------|-----------|-----------------|
| Modules mapped | 336 | 339 |
| Processes required to reach the cluster | 0 (none existed) | **1** |
| Modules with no external reference | 297 (88 %) | 297 (88 %) |
| Modules with no test reference | 286 (85 %) | 285 |
| Subpackages with all engines tested | `world_model/pipeline` (11/11) | unchanged |
| Subpackages with **no** tested engine | `cognitive/engines` (23), `cognitive/decision` (8), `cognitive/metacognition` (7), `cognitive/reflection` (7), `cognitive/runtime` (6), `world_model/counterfactual` (17), `world_model/prediction` (9) | unchanged |

The last row is the honest limit of TCP-002.2: the Spine now *reaches* those
engines, but most of them had no test, and the Spine's own tests exercise only
the paths it uses. The remaining engines are **reachable but unverified**.

## 3. The cycle

```
  PERCEIVE & CONTEXT ──▶ context
          │
          ▼
  DOMAIN KNOWLEDGE ────▶ world_model
          │
          ▼
  HYPOTHESIS & PLAN ───▶ hypothesis
          │
          ▼
  FORECAST & UNCERTAINTY▶ forecast
          │
          ▼
  DECIDE ───────────────▶ decision
          │
          ▼
  EVIDENCE ─────────────▶ evidence
          │
          ├─▶ RETAIN ────▶ knowledge   (gate)
          └─▶ ACT ───────▶ authorize   (gate)
```

| Stage | Engines invoked | Status |
|-------|-----------------|--------|
| `:context` | `Cognitive.Engines.ContextBuilder` → `Cognitive.CognitiveContext` | working |
| `:world_model` | `WorldModel.Pipeline.PipelineOrchestrator` (10 stages: ingest → variables → structure → equations → parameters → assemble → validate → certify → deploy) | working, all 11 engines tested |
| `:hypothesis` | `Cognitive.Planning.GoalDecomposer` → `TaskPlanner` | working, 7/8 engines tested |
| `:forecast` | `Cognitive.Metacognition.ConfidenceEstimator` → `UncertaintyAnalyzer` | working, 0/7 tested |
| `:decision` | `Cognitive.Decision.DecisionManager` → `DecisionEvaluator` (11-dimension score) | working, 0/8 tested |
| `:evidence` | `Cognitive.Runtime.EvidenceRouter` (hashed evidence chain) | working, 0/6 tested |
| `:knowledge` | knowledge port | **gate** — refuses by default |
| `:authorize` | authority port | **gate** — refuses by default |

## 4. Gate semantics

The first six stages are a **chain**: a failure stops the chain and the error
is returned with the trace produced up to that point.

The last two are **gates**. They are always attempted, they never abort the
investigation, and their refusal is a legitimate outcome. An unwired Spine
completes its investigation and reports that it could not retain knowledge and
could not obtain a mandate. It does not pretend otherwise, and it does not
weaken the fail-closed behaviour of the subsystems it calls.

This satisfies the programme's prohibitions directly:

| Prohibition | How the Spine complies |
|-------------|------------------------|
| No third cognitive core | Every stage calls an existing engine; the Spine has no reasoning of its own. |
| No mass supervision | 1 process for 339 modules, and that process owns configuration and lifecycle, not capability. |
| No fake activation | Stage outputs are asserted to be the *engines'* real outputs (observation counts, certificate status, confidence values, score dimensions). |
| No synthetic research execution | The Spine runs no experiment; the `:authorize` gate is the only path to action, and it refuses by default. |
| No bypassing governance | Authority is injected through a port; the Spine cannot authorise anything by itself. |
| No weakening of fail-closed behaviour | Unavailable capabilities stay unavailable: unwired gates report `{:error, :authority_unavailable}` / `{:error, :knowledge_store_unavailable}`. |
| No duplicate authorities | The Spine composes; it does not reimplement. Where two engines disagreed (see §6) the Spine normalised at the seam rather than forking a second path. |

## 5. Where it lives

| Component | Location | Role |
|-----------|----------|------|
| Spine contract | `tiannara_runtime/lib/tiannara_runtime/cognitive/spine/cognitive_execution_spine.ex` | Pure sequencing function over existing engines. |
| Ports | `.../spine/ports.ex` | `Authority` and `Knowledge` behaviours + refusing defaults. |
| Host | `.../spine/spine_server.ex` | The single process: owns adapter configuration and lifecycle. |
| Supervision | `tiannara_runtime/lib/tiannara_runtime/runtime_layers/supervisors.ex` | `TiannaraRuntime.Execution.Supervisor`, via `optional_child/1`. |
| Tests | `tiannara_runtime/test/cognitive/spine/cognitive_execution_spine_test.exs` | 16 tests. |

The Spine sits in the runtime because that is where the engines live. The
*authority* lives in the application stack (Council, CEL, the machine-grant
chain). The port is what joins them — and joining them is TCP-002.5's work,
not TCP-002.2's.

## 6. Defects found by activation (not by inspection)

Wiring the Spine into live engines exposed four defects that no amount of
reading the code had surfaced, because the code had never run:

| # | Defect | Evidence | Fix |
|---|--------|----------|-----|
| **D1** | `CognitiveContext.compute_fingerprint/1` (both the root and the `Runtime` copy) piped a struct through `Map.drop/2` and then `Enum.sort_by/2`. `Map.drop/2` preserves `:__struct__`, so the result is still a struct and is not `Enumerable` — the function raised for every input. | `protocol Enumerable not implemented for type TiannaraRuntime.Cognitive.CognitiveContext` | `Map.from_struct/1` before `Map.drop/2`. |
| **D2** | `Cognitive.Engines.ContextBuilder.build_context/3` passed 3 of the 7 fields that `CognitiveContext.new/1` reads by dot access, so it raised `KeyError` for **every** caller. | `key :world_models not found` | Pass the complete field set. |
| **D3** | `Cognitive.CognitiveContext` and `Cognitive.Runtime.CognitiveContext` are duplicate modules with different shapes, and `ContextBuilder` targets the first while the rest of the runtime has no consumer of either. | Two `defmodule`s, two struct layouts | Registered as `TCP-B-037`; not merged in TCP-002.2 because both are in use. |
| **D4** | Two contract mismatches at the seams: `CognitiveContext.generate_id/1` interpolates the mission, so it requires a **string**, while `GoalDecomposer.decompose/1` reads `mission.objective`, so it requires a **map**; and `ConfidenceEstimator.estimate/1` takes evidence **records** while `UncertaintyAnalyzer.aleatoric/1` takes plain **numbers**. | `protocol String.Chars not implemented for type Map`; `bad argument in arithmetic expression` | The Spine normalises at the seam. The engines are left unchanged and the mismatch is registered. |

**D1 and D2 are the clearest evidence for the W0 thesis**: these modules were
not merely unwired, they were *broken*. Nothing could have found that by
counting them. It took an integration that actually called them.

## 7. What TCP-002.2 does not claim

- **The Spine is not a complete cognitive cycle.** It covers six stages plus
  two gates. The research-specific stages (question generation, competing
  explanations, evidence acquisition) and the knowledge-promotion stages live
  in the application stack and in the orphaned `Memory.Ladder` mechanism, and
  are **not** yet part of the Spine.
- **Most engines it reaches are unverified.** 89 of the 154 engines have no
  test. The Spine's tests cover the paths it exercises, not the engines'
  correctness.
- **No experiment is executed.** The Spine does not run experiments; the
  `:authorize` gate is the only route to action and it refuses by default.
- **No knowledge is retained.** The knowledge port refuses by default.
- **The application stack's forecasting chain is still orphaned.** The 51
  modules of `lib/tiannara/forecasting/` have no caller outside their own
  directory. That is TCP-002.3.

## 8. Next

**TCP-002.3 — forecasting integration.** Wire `lib/tiannara/forecasting/` into
a real research and decision workflow so that the forecast → outcome →
calibration → model-update chain actually fires, producing persisted,
evidence-bound calibration records. The components exist and are well built;
they have never run.
