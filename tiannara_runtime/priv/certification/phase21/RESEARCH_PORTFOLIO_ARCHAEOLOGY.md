# Research Portfolio Archaeology (Phase 21.1)

## Purpose

Define the archaeology model for research portfolio governance. Portfolio archaeology answers the essential questions about why portfolio decisions were made.

## Seven Essential Questions

| Question | Answer Source |
|----------|--------------|
| Why was this program created? | Program proposal, evidence chain, gap analysis |
| Why was it funded? | Capital allocation record, priority score |
| Why did priority change? | Priority recomputation, dimension changes |
| Why was it retired? | Retirement review, completion evidence |
| Which discoveries resulted? | Mission output records, discovery registry |
| Which successor inherited the work? | Program succession record |
| How did it influence civilization? | Cross-domain citation analysis, impact metrics |

## Archaeology Artifacts

| Artifact | Content | Hash Reference |
|----------|---------|---------------|
| Program creation | Proposal, evaluation, approval | program_creation_hash |
| Program funding | Allocation record, priority scores | allocation_hash |
| Priority change | Re-prioritization record, dimension delta | priority_change_hash |
| Program retirement | Retirement decision, closure evidence | retirement_hash |
| Program succession | Predecessor/successor linkage | succession_hash |
| Portfolio rebalance | Rebalancing proposal and execution | rebalance_hash |

## Archaeology Hierarchy

```
Portfolio Archaeology Root
    │
    ├── Portfolio 1 Archaeology
    │   ├── Program Archaeologies
    │   │   ├── Creation → Funding → Milestones → Review → Succession/Retirement
    │   │   └── ...
    │   └── Balance records
    │
    ├── Capital Allocation Archaeology
    │   └── Per-generation allocation records
    │
    └── Succession Lineage Archaeology
        └── Full program evolution tree
```

## Preservation

- All portfolio archaeology is content-addressed
- Archaeology chain is continuous from portfolio creation
- Archaeology is independently reconstructible from cold storage
