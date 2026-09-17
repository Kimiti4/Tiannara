# MC-002-A0 — Logic Capability Inventory

**Gate:** MC-002-A0 (Observational) — READ-ONLY
**Method:** static source inventory of `lib/`, `test/`, `priv/`, `docs/`, `config/`
using semantic keyword search plus behavioral inspection. Capability is classified
from implementation behavior, NEVER from names/API/docs alone.

## 1. Real logical capabilities (executable, output derived from input)

| # | Capability | Module | Evidence (file:line) | Notes |
|---|-----------|--------|----------------------|-------|
| L1 | Graph lineage (ancestor reachability) | `Tiannara.Graph.Audit.lineage/2` | `lib/tiannara/graph/audit.ex:11-16` | REAL BFS/DFS walker, `do_walk/4:33`; consumer-agnostic over `Graph.Behaviour` |
| L2 | Graph blast-radius (descendant reachability) | `Tiannara.Graph.Audit.blast_radius/2` | `lib/tiannara/graph/audit.ex:19-24` | REAL |
| L3 | Cycle detection | `Tiannara.Graph.Audit.has_cycle?/1` | `lib/tiannara/graph/audit.ex:27-31` | REAL DFS detect_cycle, `:58-68` |
| L4 | Pairwise value-conflict detection over claims | `Tiannara.Contradiction.Engine.detect/1` | `lib/tiannara/contradiction/engine.ex:38-48` | REAL; list-wise, returns `[Record]`; type/severity/confidence derived |
| L5 | Evidence-link contradiction detection | `Sentinel.Verification` (private `find_contradictions/3`) | `lib/tiannara/sentinel/verification.ex:307-349` | REAL; direct + cross-support, based on `contradicts`/`supports` links |
| L6 | Audit queries over provenance/debugger state | `Tiannara.Epistemic.Debugger.find_contradictions/1, find_unchecked/1, find_low_confidence/2` | `lib/tiannara/epistemic/debugger.ex:123-137` | REAL, narrow; simple filters over node state |
| L7 | Discovery contradiction ranking/classification | `Tiannara.Discovery.ContradictionAnalyzer` | `lib/tiannara/discovery/contradiction_analyzer.ex` | REAL; classify+rank, but impact is heuristic/estimated (PARTIAL as logic) |

## 2. Broken / dangling references

| # | Site | Evidence | Consequence |
|---|------|----------|-------------|
| B1 | `Audit.find_contradictions/1` call | `lib/tiannara/constitution/registry.ex:118` | `Tiannara.Graph.Audit` (audit.ex:1) defines `lineage/2, blast_radius/2, has_cycle?/1` but NO `find_contradictions/1` → `UndefinedFunctionError` if constitutional probe executes. NOTE: archaeology's "module missing" is imprecise; module exists, function missing. |

## 3. Theatrical / fabricated logical capabilities

| # | Capability | Module | Evidence | Nature |
|---|-----------|--------|----------|--------|
| T1 | "Paradox resolution" | `Tiannara.CTL.ParadoxResolver.resolve/2` | `lib/tiannara/ctl/paradox_resolver.ex:7-24` | Reads boolean flags (`:contradicts_base`,`:broken_downstream`) — no logical analysis; pushes fabricated metric `collapse_probability 0.9` |
| T2 | GCK "contradiction/paradox/axiom" detection & repair | `Tiannara.Substrate.GCK.*` | `lib/tiannara/substrate/gck.ex` | Logger-only + `Aggregator.push_event` hardcoded (`0.99`, `0.98`, `0.96`); no actual detection/repair computation |
| T3 | OSK "identity formal equivalence" | `Tiannara.Substrate.OSK.IdentityEquivalence.check_equivalence/2` | `lib/tiannara/substrate/osk.ex:85-89` | Unconditionally `:ok` |
| T4 | OSK "continuity audit / paradox suppression" | `Tiannara.Substrate.OSK.ContinuityAuditor.audit/2` | `lib/tiannara/substrate/osk.ex` (ContinuityAuditor) | Logger-only + hardcoded `push_event` (`1.0`, `0.22`) |
| T5 | mcal "alternative causality sandbox" | `Tiannara.Substrate.MCAL.*` | `lib/tiannara/substrate/mcal.ex` | Logger-only + hardcoded `push_event` (`0.98`,`0.96`,`0.97`) |
| T6 | Other substrate detectors (cof/euf/opc/ose/hsv) | `Tiannara.Substrate.{COF,EUF,OPC,OSE,HSV}.*` | `lib/tiannara/substrate/{cof,euf,opc,ose,hsv}.ex` | `detect/check_consistency/verify_integration` are scenario-keyword + Logger + hardcoded `push_event` |

## 4. Capabilities that DO NOT exist

| Claimed/existing category | Search result | Verdict |
|--------------------------|---------------|---------|
| Dedicated logic namespace | no `lib/tiannara/logic/` | NO |
| `Tiannara.Logic` module | none | NO |
| Proof construction/checking | `def check_proof`/`def verify_proof`: 0 hits | NO |
| Theorem proving / SAT / SMT | no `defmodule.*Prover`/`*TheoremProver`; no Z3/CVC | NO |
| Symbolic rewriting engine | no dedicated symbolic layer | NO |

## 5. Boundary with MC-001 (mathematics)

- `formal_verification.ex` (`verify_invariants/2`) → `{:error, :formal_verification_unavailable}` — **does not provide logic**; it is math-adjacent and already UNAVAILABLE.
- `calculus.ex` (`solve_ode/3`) → `{:error, :ode_solver_unavailable}`.
- `optimization.ex` → `{:error, :gradient_descent_unavailable}` / `{:error, :nash_equilibrium_unavailable}`.
- MC-002 logical components must NOT depend on any of these as if available.

## Evidence limitations

- Full cross-repo behavior execution NOT_EXECUTED; classifications are from static
  source reading (sufficient for the L1–L6/T1–T6/B1 judgments reached).
- Whether `registry.ex` probe B1 actually executes at runtime is NOT_EXECUTED; the
  compile-level absence of `find_contradictions/1` in `Graph.Audit` is established statically.
