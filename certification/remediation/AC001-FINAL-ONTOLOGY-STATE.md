# AC-001 FINAL Ontology State

**Date:** 2026-08-27
**Status:** CLOSED AND CERTIFIED

## Canonical Research Domains (20)

| # | Domain | Module | Lifecycle |
|---|--------|--------|-----------|
| 1 | :engineering | Tiannara.Domains.Engineering | active |
| 2 | :physics | Tiannara.Domains.Physics | active |
| 3 | :chemistry | Tiannara.Domains.Chemistry | active |
| 4 | :medicine | Tiannara.Domains.Medicine | active |
| 5 | :cybernetics | Tiannara.Domains.Cybernetics | active |
| 6 | :governance | Tiannara.Domains.Governance | active |
| 7 | :computation | Tiannara.Domains.Computation | active |
| 8 | :agriculture | Tiannara.Domains.Agriculture | active |
| 9 | :energy | Tiannara.Domains.Energy | active |
| 10 | :logistics | Tiannara.Domains.Logistics | active |
| 11 | :cognition | Tiannara.Domains.Cognition | active |
| 12 | :materials | Tiannara.Domains.Materials | active |
| 13 | :robotics | Tiannara.Domains.Robotics | active |
| 14 | :economics | Tiannara.Domains.Economics | active |
| 15 | :philosophy | Tiannara.Domains.Philosophy | active |
| 16 | :sociology | Tiannara.Domains.Sociology | active |
| 17 | :linguistics | Tiannara.Domains.Linguistics | active |
| 18 | :aerospace | Tiannara.Domains.Aerospace | active |
| 19 | :ecology | Tiannara.Domains.Ecology | active |
| 20 | :architecture | Tiannara.Domains.Architecture | active |

## Excluded Identities (Non-Domain)

| Identity | Classification | Legitimate Uses Preserved |
|----------|---------------|--------------------------|
| :science | methodology | Yes (moduledoc documentation, pipeline stage) |
| :mathematics | epistemic substrate | Yes (math subsystem, :mathematics_ontology label) |
| :logic | epistemic substrate | Yes (reasoning infrastructure) |
| :cs | merged → :computation | No active domain identity |

## Infrastructure Modules (11, non-domain)

Within `lib/tiannara/domains/`: `domain.ex` (behaviour),
`canonical_registry.ex`, `registry.ex` (DEPRECATED), `extruder.ex`,
`transfer_matrix.ex`, `knowledge_capital_boundary.ex`, `portfolio_boundary.ex`,
`research_director.ex` (+ extruder submodules under `extruder/`).

## Merged Modules

| Module | Disposition | Target |
|--------|-------------|--------|
| ComputerScience | MERGED | :computation |

## Ontology Invariants

- count = 20 ✅
- unique = true ✅
- exact_set = frozen ontology ✅
- No excluded identity functions as domain ✅
- No fake domain created ✅

## Future Substrates (Not Yet Implemented)

| Substrate | Owner Gate | Status |
|-----------|-----------|--------|
| Mathematics | MC-001 | UNLOCKED (not implemented) |
| Logic | MC-002 | BLOCKED (pending MC-001) |
| Information | Future | BLOCKED |

## Ontology Closure Declaration

The canonical domain ontology is CLOSED. No further domain additions,
removals, or reclassifications are permitted without a new authorized gate.
Mathematics, Logic, and Information are epistemic substrates, not domains.
Science is methodology, not a domain.
