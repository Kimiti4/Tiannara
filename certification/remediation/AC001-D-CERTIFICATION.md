# AC-001-D Certification Record

**Gate:** AC-001-D (Legacy Registry Deprecation)
**Campaign:** Tiannara Remediation + Substrate Integration
**Date:** 2026-08-26
**Status:** CERTIFIED

## Bounded Claim

Tiannara no longer maintains competing executable domain-registry authorities. The canonical registry is the sole authoritative domain-identity mechanism. Legacy registries and APIs have explicit, auditable dispositions. All production consumers have migrated. No compatibility theater or fabricated capability has been introduced. Migration lineage is preserved. No ontology, knowledge-capital, portfolio, or substrate boundaries were altered by this gate.

## Evidence Inventory

| Evidence Class | Source | Result |
|---------------|--------|--------|
| Static scan (production aliases) | grep lib/ for legacy registry aliases | 0 hits |
| Static scan (production calls) | grep lib/ for legacy registry function calls | 0 hits |
| Static scan (supervision) | grep application.ex for legacy registries | 0 hits |
| Static scan (test refs) | grep test/ for legacy registries | 0 hits |
| Compile | mix compile | PASS |
| Unit tests (domains) | test/tiannara/domains/ | 43/43 PASS |
| Unit tests (web + discoveries) | test/tiannara/web/ + test/tiannara/discoveries/ | 127/127 PASS |
| Runtime: CanonicalRegistry live | supervised in application.ex | PASS |
| D1 freeze report | AC001-D1-LEGACY-FREEZE.md | COMPLETE |
| D3 API disposition | AC001-D-API-DISPOSITION.md | COMPLETE |
| Migration lineage | AC001-D-MIGRATION-LINEAGE.md | COMPLETE |
| autonomous_discovery.ex migration | D2 — Registry.all_domains() → CanonicalRegistry.all_records() | MIGRATED |
| Registry A deprecated | raises on call, clear error messages | PASS |
| Registry B deprecated | raises on call, boundary APIs return unavailable | PASS |
| No ontology mutation | 20-domain ontology unchanged | PASS |
| No boundary violation | Knowledge capital + portfolio remain separate | PASS |

## Mutation Inventory

| Sub-gate | Mutation | Status |
|----------|----------|--------|
| D1 | Legacy freeze baseline | COMPLETE |
| D2 | Migrate autonomous_discovery.ex | COMPLETE |
| D2 | Deprecate Tiannara.Domains.Registry | COMPLETE |
| D2 | Deprecate TiannaraOS.DomainRegistry | COMPLETE |
| D3 | API disposition table | COMPLETE |
| D4 | Verification | COMPLETE |

## D1 Discovery

D1 found one production consumer not caught by C1: `autonomous_discovery.ex:48` calling `Registry.all_domains()`. This was migrated to `CanonicalRegistry.all_records()` during D2.

## D2 Implementation

### Tiannara.Domains.Registry
- All functions replaced with `raise` containing explicit deprecation messages
- Clear pointer to `Tiannara.Domains.CanonicalRegistry.all/0`

### TiannaraOS.DomainRegistry
- All identity functions (`list_all/0`, `get/1`) replaced with `raise`
- `get_knowledge_capital/1` returns `{:error, :knowledge_capital_unavailable}` (boundary preserved)
- `get_portfolio_vector/1` returns `{:error, :portfolio_unavailable}` (boundary preserved)
- Dead APIs (`add_program/2`, `record_activity/3`, `get_all_domain_ids/0`) replaced with `raise`
- GenServer behavior removed (module is inert)

## Residual Debt

| Item | Owner Gate | Status |
|------|-----------|--------|
| Broad :science/:mathematics reclassification (50+ files) | AC-001-E | BLOCKED pending D |
| Knowledge capital implementation | Future gate | NOT STARTED |
| Portfolio implementation | Future gate | NOT STARTED |
| 38 ASC boot failures | Pre-existing | UNRELATED to D |

## Known Limitations

- Legacy modules retained as deprecated stubs (not deleted) for migration lineage
- `get_knowledge_capital/1` and `get_portfolio_vector/1` return `{:error, ...}` rather than raising because they were established as boundary contracts in C1

## Verdict

**CERTIFIED**

All certification requirements satisfied:
- [x] CanonicalRegistry = sole executable authority
- [x] Zero production legacy references
- [x] Zero runtime legacy authority
- [x] Legacy modules deprecated with clear error messages
- [x] API dispositions complete
- [x] Migration lineage complete
- [x] Compile PASS
- [x] Tests PASS (170/170 across domains, web, discoveries)
- [x] No D-induced regression
- [x] No ontology mutation
- [x] No boundary violation
- [x] autonomous_discovery.ex migrated

## Authorization References

- Contract: `priv/tiannara/remediation/contracts/AC001_D_legacy_deprecation.contract.yaml`
- Authorization: `priv/tiannara/authorization/ASC-AC-001-D-LEGACY-DEPRECATION.human.yaml`
- D1 freeze: `certification/remediation/AC001-D1-LEGACY-FREEZE.md`
- Migration lineage: `certification/remediation/AC001-D-MIGRATION-LINEAGE.md`
- API disposition: `certification/remediation/AC001-D-API-DISPOSITION.md`

## Timestamp

2026-08-26T22:15:00Z
