# AC-001-D Legacy Registry Deprecation Protocol

**Gate:** AC-001-D
**Campaign:** Tiannara Remediation + Substrate Integration
**Class:** DEPRECATION
**Mode:** AUTHORIZED_MUTATION

## Bounded Proposition

Tiannara no longer maintains competing executable domain-registry authorities. The canonical registry is the sole authoritative domain-identity mechanism. Legacy registries and APIs have explicit, auditable dispositions.

## Invariants

1. **CanonicalRegistry is sole authority** — no other module may determine domain identity
2. **No ontology mutation** — the 20-domain frozen ontology is untouched
3. **No boundary violation** — knowledge capital and portfolio remain separate
4. **No compatibility theater** — legacy APIs raise rather than fabricate
5. **Migration lineage preserved** — every disposition is documented

## Sub-Gates

| Gate | Mutation | Risk |
|------|----------|------|
| D1 | Legacy freeze baseline inventory | LOW |
| D2 | Legacy module deprecation + last consumer migration | MEDIUM |
| D3 | API disposition documentation | LOW |
| D4 | Verification and sealing | LOW |

## Hard Stops (NOT_CERTIFIED)

- Legacy registry still determines domain identity
- Production code still calls legacy registry
- Old APIs recreated for test compatibility
- Legacy deleted without disposition/lineage
- Frozen 20-domain ontology changed
- Knowledge capital absorbed into registry
- Portfolio absorbed into registry
- New D-induced test failure

## Execution Sequence

```text
D1 → freeze inventory
D2 → deprecate + migrate last consumer
D3 → API disposition
D4 → verify → verdict
```
