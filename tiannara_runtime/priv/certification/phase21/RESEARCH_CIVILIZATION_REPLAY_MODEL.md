# Research Civilization Replay Model (Phase 21.0)

## Purpose

Define the replay model for the research civilization. Replay reconstructs the complete civilization — all institutes, programs, missions, portfolios, scientific capital, and knowledge growth — with identical hashes required.

## Replay Scope

| Replay Type | Coverage | Description |
|-------------|----------|-------------|
| Full civilization | All institutes, programs, missions | Complete civilization reconstruction |
| Institute | Single institute lifecycle | Institute charter → evolution → archive |
| Program | Single program execution | Program proposal → completion |
| Mission | Single mission execution | Mission proposal → archive |
| Portfolio | Portfolio allocation and rebalancing | Portfolio evolution across generations |
| Capital ledger | Complete capital accounting | All capital transactions |

## Replay Hierarchy

```
Civilization Root
    │
    ├── Institute 1 → Programs → Missions → Discoveries
    ├── Institute 2 → Programs → Missions → Discoveries
    ├── ... (20 institutes)
    │
    ├── Portfolio 1 (Foundational Science)
    ├── Portfolio 2 (Applied Science)
    ├── ... (8 portfolios)
    │
    └── Capital Ledger (all transactions)
         │
         v
    CIVILIZATION REPLAY ROOT
```

## Replay Verification

For each replay target:
1. Load entity state from archaeology
2. Replay all operations deterministically
3. Compute output hash
4. Compare against recorded hash
5. Walk to child entities and repeat
6. Compute civilization replay root

## Identical Hash Requirements

- Full civilization replay must produce identical hashes
- All institute replays must match
- All program replays must match
- All mission replays must match
- Capital ledger replay must match
- Knowledge growth replay must match
