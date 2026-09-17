# MC-002-A0 — Logic Substrate Reconciliation Protocol

**Gate:** MC-002-A0 (Observational)
**Campaign:** Tiannara Remediation + Substrate Integration
**Predecessors:** MC-001-M CERTIFIED (BOUNDED); AC-001 FINAL CERTIFIED (BOUNDED)
**Mode:** READ-ONLY. No production mutation.
**Date:** 2026-08-29

## Governing Principles

- Evidence Before Confidence; Truth > confidence; Uncertainty never hidden.
- Verification First; capability must never outpace verification.
- Distinguish facts / evidence / assumptions / hypotheses / unknowns.
- **Logic is an epistemic substrate, NOT a canonical domain** (AC-001 invariant).
- "A function named verify is not verification merely because it returns a Boolean."
- Capability must be earned by execution and evidence, not by the existence of an API.
- An unavailable epistemic capability must never be interpreted as successful validation (MC-001-M precedent).

## Scope

Inventory and truth-classify the logical substrate: propositional/predicate logic,
inference, entailment, satisfiability, consistency, contradiction detection, rule
engines, symbolic rewriting, proof construction/checking, theorem proving,
constraint reasoning, formal verification, SAT/SMT, reasoning graphs, logical
components consumed by discovery/validation/governance, and logical open-world
prerequisites.

## Truth Classes

REAL / PARTIAL / THEATRICAL / FABRICATED / DUPLICATE / UNKNOWN / NO

REAL requires execution evidence that outputs derive from inputs. A passing test
of a theatrical implementation remains theatrical evidence.

## Capability-Inflation Checks (A0.6)

Boolean evaluation ≠ theorem proving; rule matching ≠ formal proof; symbolic
transformation ≠ proof; consistency heuristic ≠ formal verification; pattern
matching ≠ logical entailment. Record every inflation found.

## Reality-Divergence Note (this reconciliation corrects the archaeology)

The TIANNARA_LOGIC_ARCHAEOLOGY (baseline commit `3bd1601`) claimed
`Graph.Audit.find_contradictions/1` had "no module". Reconciliation found the
module EXISTS (`lib/tiannara/graph/audit.ex:1`) but the FUNCTION
`find_contradictions/1` is ABSENT from it — so the `constitution/registry.ex:118`
call still raises `UndefinedFunctionError` at runtime, but for a different reason
than recorded. Conclusions (broken ref) preserved; mechanism corrected.

## Forbidden

Production mutation; API/test/supervision/config/ontology changes; replacing
theatrical implementations; creating logic infrastructure; modifying MC-001/AC-001.

## Certification Rule

CERTIFIED (RECONCILIATION ONLY) only when all 11 conditions hold, including
independent verifier pass and explicitly recorded evidence limitations. It must
NOT imply logical capability, formal verification, theorem proving, autonomous
logical discovery, or general reasoning.
