# Research Portfolio Replay Model (Phase 21.1)

## Purpose

Define the replay model for the research portfolio governance system. Replay reconstructs the complete portfolio, program priorities, capital allocation, resource scheduling, program succession, and portfolio evolution — with identical hashes required.

## Replay Scope

| Replay Type | Coverage | Description |
|-------------|----------|-------------|
| Full portfolio | All portfolios, programs, allocations | Complete governance reconstruction |
| Program | Single program lifecycle | Program proposal → archive |
| Capital | Capital allocation across programs | Allocation decisions replay |
| Allocation | Single allocation decision | Input scores → output allocation |
| Succession | Program succession chain | Predecessor → successor lineage |

## Replay Hierarchy

```
Portfolio Governance Root
    │
    ├── Portfolio 1 (Foundational Mathematics)
    │   ├── Program A → lifecycle → missions → discoveries
    │   ├── Program B → lifecycle → missions → discoveries
    │   └── ...
    ├── Portfolio 2 (Foundational Physics)
    │   └── ...
    ├── ...
    │
    ├── Capital Allocations (per generation)
    ├── Resource Schedules (per generation)
    └── Program Successions (lineage chain)
         │
         v
    PORTFOLIO REPLAY ROOT
```

## Verification

For each replay target:
1. Load entity state from archaeology
2. Replay all governance decisions deterministically
3. Compute output hash
4. Compare against recorded hash
5. Walk to child entities and repeat
6. Compute portfolio replay root
