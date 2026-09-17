# AC-001-E — Reclassification Ledger

**Gate:** AC-001-E2/E3 (Semantic Reclassification)
**Status:** COMPLETE

Every occurrence classified by semantic context and disposed individually.

## :science — Disposition

| File:Line | Context | Disposition |
|---|---|---|
| edm/immune_system.ex:10-14 (3) | immune discovery: methodology | → :methodology |
| ecology/civilization.ex:14 | domain list | → :physics |
| domain_cortex.ex:11 | l1 discovery domains | → :physics |
| canonical_registry.ex:18 | moduledoc | preserved (documentation) |
| leoc/compression_engine.ex:49 | random list | → :cognition (removed non-domain) |
| discoveries/institution_ecology.ex:206 | focus_domain | → :engineering |
| sentinel/d2/epistemic_niche.ex:16 | niche domain | → :engineering |
| os/domain_profile.ex:92 | dispatch case | removed (no :science profile) |
| os/domain_profile.ex:389 | profile data | → :engineering (empirical mission) |
| capability_checker.ex:33 | doctest | preserved (documentation) |
| institution_kernel.ex:5229 | test scenario id `science_inst_12_8_s4` | preserved (atom prefix, not domain identity) |
| program_registry.ex:868 | unified_physics binding | → :physics |
| constitutional_institution.ex:22 | moduledoc | → :methodology (role label) |
| constitutional_institution.ex:79/115/187/223 | governance_domains | → :methodology |
| genome_calculator.ex:143/158 | domain classifier | → :methodology |
| world_manager.ex:127 | default fallback | → :engineering |
| governance_ledger.ex:114 | doc example | preserved (documentation) |
| institutional_provenance.ex:34 | moduledoc | preserved (documentation) |
| rfc_validation_laboratory.ex:242 | test genome | → :methodology |

**Result:** 0 code occurrences of `:science-as-research-domain` remain. Remaining
`:science` occurrences in lib/ are documentation/doctest only.

## :mathematics — Disposition

| File:Line | Context | Disposition |
|---|---|---|
| asc/research_planner.ex:36 | research program domain | → :computation |
| asc/research_bridge.ex:9 | moduledoc | preserved (documentation) |
| asc/research_bridge.ex:35 | seed domains | → :computation (removed) |
| ecology/civilization.ex:17 | domain list | → :chemistry |
| asc/research/institution_manager.ex:23 | institute creation | → :computation |
| domain_cortex.ex:11 | l1 discovery domains | → :chemistry |
| canonical_registry.ex:19 | moduledoc | preserved (documentation) |
| knowledge_graph/registry.ex:208 | node domains | → :computation |
| asc/domain_observer.ex:23 | seed domains | removed |
| asc/civilization_manager.ex:10 | default domains | → :computation |
| os/domain_profile.ex:107/914 | dispatch/profile | → :computation |
| os/domain_profile.ex:923 | knowledge_graph label | preserved (:mathematics_ontology, substrate) |
| os/discovery_asset_economy.ex:202 | domain multiplier | → :computation |
| os/dynamic_needs_evolution.ex:163 | dependency map node | removed (redundant) |
| program_registry.ex:876 | proof_verification binding | → :computation || institution_kernel.ex:2887/3026/3060/5447/5474/6509 | program gen/reasoning/strategies | → :computation |
| recursive_civilization_runner.ex:450 | random selection | → :computation |
| campaign_02...ex:21 | campaign scope | preserved (stage name, non-domain) |
| world_manager.ex:27-30 | lab→domain maps | → :computation |
| world_template.ex:104 | template id | → :computation |

**Result:** 0 code occurrences of `:mathematics-as-canonical-domain` remain.
`:mathematics_ontology` preserved as a substrate graph label.

## :logic — Classification (E3)

`:logic` occurrences remain **only** in non-domain roles:
- L2 cognitive operator (domain_cortex.ex:19) — operator, NOT domain
- Crucible failure taxonomy (~30 sites) — software failure category
- Audit task requirement lists — task requirement vocabulary
- Contradiction/clock/design `logical_*` — vocabulary words
- `:logic_lab` under `:computation` world template — lab id

No `:logic` is a canonical research domain. **No change required** beyond
verifying none participates in the canonical ontology.

## :cs / ComputerScience — Disposition

- `domains/computer_science.ex` — **DELETED** (all callbacks were no-op stubs;
  returned legacy `:cs`; metrics were fabricated constants; zero consumers)
- `:cs` merged into `:computation` per A0
- canonical_registry.ex:21 moduledoc documents the merge (preserved)

**Result:** zero `:cs` / `:computer_science` occurrences in lib/.

## Summary

| Resource | Before | After |
|---|---|---|
| `:science` code occurrences | 22 | 0 (reclassified/preserved as doc) |
| `:mathematics` code occurrences | 27 | 0 (reclassified/preserved as substrate label) |
| `:logic` canonical-domain occurrences | 0 | 0 (never canonical) |
| `:cs` / ComputerScience code | 1 module | 0 (deleted) |
| Canonical domains | 20 | 20 (unchanged) |
