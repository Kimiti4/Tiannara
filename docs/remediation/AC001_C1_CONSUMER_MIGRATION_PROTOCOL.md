# AC-001-C1 Consumer Migration Protocol

**Gate:** AC-001-C1
**Campaign:** Tiannara Remediation + Substrate Integration
**Class:** CONSUMER_MIGRATION
**Mode:** AUTHORIZED_MUTATION

## Bounded Proposition

All production consumers that previously depended on the two non-canonical domain registries (`TiannaraOS.DomainRegistry` and `Tiannara.Domains.Registry`) are migrated to `Tiannara.Domains.CanonicalRegistry` without semantic loss, fabricated data, compatibility theater, or hidden fallback behavior.

Knowledge capital and portfolio state remain explicitly unavailable boundaries until their own real services exist.

## Invariants

1. **1 consumer operation → 1 coherent registry snapshot** (no N+1)
2. **No fabricated defaults** — `{:ok, 0.0}`, `{:ok, %{}}`, or invented fallback values are forbidden
3. **Unavailable means unavailable** — boundary modules return `nil`, not fake data
4. **No semantic loss** — every consumer receives the identity information it actually requires
5. **No compatibility theater** — consumers do not receive wrapper-shaped stubs

## Architecture

```text
CanonicalRegistry
    owns:
      identity
      metadata
      module binding
      lifecycle
      ontology version

KnowledgeCapitalBoundary
    status: EXPLICITLY_UNAVAILABLE

PortfolioBoundary
    status: EXPLICITLY_UNAVAILABLE
```

## Sub-Gates

| Gate | Mutation | Verdict |
|------|----------|---------|
| C1-A | Atomic `all_records/0` | PASS |
| C1-B | Domain-ID consumer migration | PASS |
| C1-C | Domain-record consumer migration | PASS |
| C1-D | Knowledge-capital boundary migration | PASS |
| C1-E | Portfolio boundary migration | PASS |
| C1-F | Test migration/retirement | PASS |
| C1-G | Limited identity reclassification | PASS |
| C1-H | Independent verification | PASS |

## Verification Classes (C1-H)

1. **Static** — legacy registry references in lib/ = 0 (except self-modules)
2. **Compile** — `mix compile` warnings from migrated code = 0
3. **Unit/Integration** — domains, web, discoveries test suites all PASS
4. **Runtime** — boot app → call CanonicalRegistry → verify correct results
5. **Semantic inventory** — every C0 call site receives a disposition in migration ledger

## Completion Criterion

```text
CERTIFIED only if:
  40/40 call sites accounted for
  + all applicable consumers migrated
  + all_records atomic
  + zero unexplained legacy production references
  + zero fabricated capability
  + knowledge capital explicitly unavailable
  + portfolio explicitly unavailable
  + DomainProjectionTest correctly retired with justification
  + compile PASS
  + relevant tests PASS
  + runtime verification PASS
  + authorization/hash valid
  + migration ledger complete

Otherwise: QUALIFIED_PARTIAL or NOT_CERTIFIED
```
