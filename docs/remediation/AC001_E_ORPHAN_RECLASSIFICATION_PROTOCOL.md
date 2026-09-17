# AC-001-E — Orphan Reclassification Protocol

**Gate:** AC-001-E (Orphan Resolution & Ontology Closure)
**Campaign:** Tiannara Remediation + Substrate Integration
**Class:** SEMANTIC_CLOSURE
**Mode:** AUTHORIZED_MUTATION (authorized by `c14_ac`, POL-CERT_AUTH_001)
**Status:** EXECUTED

## 0. Hard Stop

> **No broad semantic rewrite is permitted merely to achieve a clean grep result.**
> E is a *semantic closure* gate, not a textual cleanup gate. Every
> `:science` / `:mathematics` / `:logic` / `:cs` occurrence must be classified
> by semantic context and disposed accordingly.

Each occurrence was individually classified as one of:

| Classification | Disposition |
|---|---|
| CANONICAL_DOMAIN | Must be a member of the frozen 20-domain ontology |
| SUBSTRATE_REFERENCE | Preserved — references epistemic substrate (:logic, :mathematics) as method, not domain identity |
| METHODOLOGY_DOMAIN | Reclassified to `:methodology` (internal governance/immune vocabulary, NOT a canonical research domain) |
| DOCUMENTATION | Preserved as historical record / doctrine / doctest example |
| DEAD_CODE | Removed (no registered binding) |

## 1. Frozen Canonical Ontology (20 domains)

```
engineering, physics, chemistry, medicine, cybernetics, governance,
computation, agriculture, energy, logistics, cognition, materials,
robotics, economics, philosophy, sociology, linguistics, aerospace,
ecology, architecture
```

**Excluded:** `:science` (methodology), `:mathematics` (epistemic substrate),
`:logic` (epistemic substrate), `:cs` (merged into `:computation`).

## 2. E1 — Orphan Inventory & Resolution

- [x] Scanned all 32 `.ex` files in `lib/tiannara/domains/`.
- [x] Classified: 20 CANONICAL_DOMAIN, 1 MERGED, 11 INFRASTRUCTURE, **0 ORPHAN**.
- [x] **Resolved:** deleted `lib/tiannara/domains/computer_science.ex` (dead stub,
      `:cs` merged into `:computation`). No registered binding existed in
      CanonicalRegistry; zero consumers established in C1.
- [x] **Verified:** no phantom `Tiannara.Domains.{Mathematics,Logic,Science}` modules exist.
- [x] **Verified:** no `Domain`-named module outside `lib/tiannara/domains/` claims a
      canonical research domain role (all are subsystem-internal concepts).

## 3. E2 — :science Semantic Reclassification

Policy: `:science` never denotes a canonical research domain. Where it functioned
as methodology within a value domain, it was reclassified to `:methodology`
(an internal governance/immune-system role — **NOT** a canonical domain).
Where it denoted a concrete empirical domain, it was mapped per its semantics to
a canonical domain (`:physics`, `:engineering`, or `:methodology`).

Fate of the initial 25 occurrences (22 code + 3 documentation):
- 4 → documentation preserved (canonical_registry moduledoc, capability_checker
  doctest, governance_ledger example, institutional_provenance moduledoc)
- 6 → reclassified `:methodology` (immune system discoveries, governance_domains,
  genome_calculator flags)
- 4 → reclassified `:physics` (domain lists, domain_profile, program_binding)
- 6 → reclassified `:engineering` (domain lists, domain_profile, world fallback,
  institutions, niche, random list)
- 2 → removed from domain lists entirely (unioned, non-domain)

## 4. E3 — :mathematics Semantic Reclassification

Policy: `:mathematics` is an epistemic substrate, not a canonical domain.
Mathematical work products map into `:computation` (per A0 ComputerScience merge
and canonical ontology). Retained `:mathematics_ontology` as a **substrate
graph label**, not a domain identity.

Fate of the 29 initial occurrences (27 code + 2 documentation):
- 2 → documentation preserved (canonical_registry moduledoc, research_bridge moduledoc)
- ~20 → reclassified `:computation` (seed domains, institutions, lab→domain maps,
  program bindings, program generators, reasoning profiles, strategies, quality gaps,
  world template id, random selection, campaign scope, discovery asset multiplier)
- 1 → removed from cross-domain dependency map (redundant node)
- 1 → preserved `:mathematics_ontology` (substrate graph label, non-domain)

## 5. E4 — Ontology Closure Verification

- [x] CanonicalRegistry `all_records/0` returns **exactly 20**.
- [x] No `:science` / `:mathematics` / `:logic` / `:cs` in the domain list.
- [x] Every canonical domain has a `Tiannara.Domains.<Name>` module bound via `domain_module/1`.
- [x] No fake domain modules created.
- [x] `:cs` / ComputerScience fully removed from `lib/`.
- [x] Remaining `:science`/`:mathematics` occurrences in `lib/` are documentation/substrate
      references only, correctly preserved.

## 6. Verification Performed

- [x] `mix compile` — PASS (no compilation errors introduced)
- [x] Static scan (`:science`, `:mathematics`, `:computer_science`) — only
      documentation/substrate references remain
- [x] Domain module inventory — 0 orphans, 20 canonical, 1 merged removed
- [x] Runtime registry closure — verified via `mix run` (20 records)
