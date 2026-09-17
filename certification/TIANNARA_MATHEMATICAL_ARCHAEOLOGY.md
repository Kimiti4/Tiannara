# Tiannara Mathematical Archaeology

Campaign: Remediation Architecture & Epistemic Foundation Certification (READ-ONLY)
Baseline commit: `3bd1601b9bb3c718f985d44ceaa8ef2e638d4ec6`
Scope: resolve **MC-001** (new numbering; prior register MC-002 "Math Proof Kernel")
Method: exhaustive grep + direct file reads + consumer tracing. All paths relative to repo root.

---

## 1. Verdict (gap-resolution categories)

| Category | Applicable? | Evidence |
|---|---|---|
| (A) Missing entirely | **No** | Math primitives exist and several are load-bearing |
| (B) Exists distributed across codebase | **Yes** | Entropy/correlation/distance/Bayes reimplemented in ≥9 modules outside `lib/tiannara/math/` |
| (C) Thin core, mostly unused | **Yes** | Core ~110 lines; only `bayes_update`, `cosine_similarity`, `shortest_path` have real consumers |
| (D) Duplication clusters | **Yes** | 9 entropy variants, ≥4 distance/correlation variants |
| Mock/stub contamination | **Yes** | `Optimization` fully mocked; one mock (`nash_equilibrium`) has a live consumer |

**Composite verdict:** Mathematics exists as *distributed infrastructure with a thin, partly-mocked core*. The correct remediation is **consolidation of evidenced kernels**, not greenfield construction.

## 2. Core inventory (`lib/tiannara/math/`)

| Module | Function(s) | Status | Consumers (file:line) |
|---|---|---|---|
| `probability.ex` | `bayes_update/3` | **LIVE** | ~8 call sites incl. `lib/tiannara/reasoning/belief_systems.ex:13`; guard `evidence_prob > 0` else `{:error, :evidence_probability_zero}` |
| `probability.ex` | `shannon_entropy/1` | **DEAD** (arity-1 variant) | zero callers; superseded by distributed variants |
| `statistics.ex` | `mean/2`, `variance/2`, `stddev/2` | **DEAD CODE** | zero callers repo-wide |
| `optimization.ex` | `gradient_descent/4` | **MOCK** | returns placeholder; zero callers; compiler warning (unused var) |
| `optimization.ex` | `nash_equilibrium/2` | **MOCK, CONSUMED** | `lib/tiannara/domains/economics.ex:12` calls it; returns hardcoded payoff matrix — economics domain "reasoning" rests on a stub |
| `graphs.ex` | `shortest_path/3` et al. | LIVE (narrow) | `lib/tiannara/domains/chemistry.ex` reaction-graph traversal |
| `math.ex` | `cosine_similarity/2` | **LIVE** | `lib/tiannara/aal/lexical_tensegrity_field.ex:29` |

## 3. Distributed implementations flagged for extraction

Private re-implementations of mathematical operations inside non-math modules:

- Entropy / information measures — **9 independent implementations**, including `substrate/mcal.ex`, `cis/collapse_predictor.ex`, discovery quality assessment, sentinel scoring.
- Bayesian update patterns duplicated beside `Probability.bayes_update`.
- Correlation / distance metrics reimplemented in wavefunction pruning (`physics/twp/pruning_engine.ex`), tensegrity fields, world-model similarity checks.
- Geometric-mean / variance-decay aggregates inside world-model and CEL scoring paths.

Full extraction table lives in the master report §4; every row carries file:line and proposed KEEP/EXTRACT/REDIRECT disposition.

## 4. CapabilityGraph integration status

- Production capability graph registers **zero math capabilities**.
- During U0 re-certification, `constitutional_mathematics` was registered **dynamically at probe runtime** and routed successfully (trace correlation `72110e79c618f109`, deterministic `math_result: 2.25`). This proves the routing mechanism works but also confirms the bounded claim `registry_fully_dynamic: false` — math availability today depends on who registers it, not on the system itself.

## 5. Target substrate boundary (proposed)

Consolidate ONLY evidenced primitives under a canonical `Tiannara.Math` facade backed by `CapabilityGraph` routing:

1. `Probability.bayes_update/3` (canonical; redirect the ~8 duplicate Bayesian sites)
2. `Math.cosine_similarity/2` + extracted correlation/distance set (redirect ≥4 duplicates)
3. Canonical Shannon entropy (single arity-correct implementation; delete or fold the other 9)
4. `Numerics` stable-form helpers already present (logsumexp-style guards)
5. Existing `InformationTheory` semantics folded under Math (alias for compatibility)

Explicitly **NOT built yet** (per POL-CERT-AUTH-001 bounded scope and YAGNI discipline): symbolic algebra, proof search, ODE solvers (`domains/physics.ex` `solve_ode` remains mock until MC-004 needs it), optimization beyond what a consumer demands (`nash_equilibrium` must either become real or its economics consumer must stop claiming equilibrium analysis).

## 6. Acceptance tests (proposed)

- M-AT-1: `mix compile --warnings-as-errors` passes after dead-code removal (`Statistics`, dead `shannon_entropy/1`, mock `gradient_descent`).
- M-AT-2: grep proves ≤1 entropy implementation and ≤1 Bayesian-update implementation under `lib/` (extraction complete).
- M-AT-3: every surviving public function has ≥1 live consumer OR an explicit contract entry in `priv/tiannara/probes/contracts/`.
- M-AT-4: `nash_equilibrium/2` either deleted together with its `economics.ex` consumer claim, or implemented with a property test (symmetric-game equilibrium existence check on a fixture matrix).
- M-AT-5: math capability registered in production CapabilityGraph supervision (not probe-only), rerun of `U0_recertification_with_math_substrate.py` yields identical `math_result: 2.25`.

## 7. Risks

- **Extraction regressions:** duplicated formulas may carry local tweaks (clamping, normalization). Mitigation: golden-value tests captured from each site BEFORE deletion.
- **Centralization bottleneck:** single facade becomes review chokepoint. Mitigation: facade is thin dispatch; implementations stay modular.
- **Silent semantic drift:** e.g., log-space vs linear entropy mixing. Mitigation: unit-dimension tags on numeric payloads (aligns with Information-substrate typing).
