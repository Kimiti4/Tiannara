# Phase 20.5 — Runtime Branching

## Overview

Runtime Branching defines constitutional branches that isolate different lines of operating system evolution. Each branch has a distinct purpose, lifecycle, and merge policy. No branch modifies Production directly.

## Supported Branches

| Branch | Purpose | Base | Merge Target |
|--------|---------|------|--------------|
| Production | Active runtime serving production load | Genesis | N/A (root) |
| Experimental | Innovation testing and validation | Production | Production (after certification) |
| Research | Long-term research and exploration | Production | Experimental |
| Simulation | Isolated simulation runs | Production | N/A (ephemeral) |
| Laboratory | Controlled sandbox for integration testing | Production | Experimental |
| Emergency | Urgent fixes for production issues | Production | Production (expedited certification) |

## Branch Properties

### Production
- Only branch that serves live production workload
- Receives merges only from Experimental (certified) or Emergency (expedited certification)
- Always has exactly one active generation
- Every generation is frozen before replacement

### Experimental
- Receives innovations from Laboratory and Research
- Merges into Production only after full constitutional certification
- May have multiple active generations in parallel
- All generations are replayable for comparison

### Research
- Long-term exploration without production constraints
- No merge deadline or certification requirement
- Merges into Experimental when research matures
- Supports branching from Research (sub-branches)

### Simulation
- Ephemeral branches for isolated simulation runs
- Automatically pruned after simulation completes
- Results preserved in evidence chain
- No merge to other branches (results inform candidates)

### Laboratory
- Controlled environment for integration testing
- Receives candidates from Evolution Engine (Phase 20.3)
- Runs full Integration Pipeline (Phase 20.4) before promoting to Experimental
- All results are immutable and replayable

### Emergency
- Expedited branch for critical production issues
- Requires immediate constitutional notification
- Follows abbreviated certification (audit still required)
- Merged changes must be fully certified retroactively
- Maximum lifetime is constitutionally bounded

## Branching Rules

1. **No branch modifies Production directly** — all changes flow through the constitutional pipeline
2. **All merges require constitutional certification** — no exception for any branch
3. **Emergency merges require retroactive certification** — expedited but not waived
4. **Branch divergence is allowed** — branches may evolve independently
5. **Branch convergence requires certification** — merging divergent branches requires full compatibility analysis
6. **Simulation branches are ephemeral** — automatically pruned; results preserved in evidence
7. **Branch lineage is preserved** — every branch maintains complete generation ancestry

## Merge Policy

| Source | Target | Certification Required | Audit Required |
|--------|--------|----------------------|----------------|
| Laboratory | Experimental | Yes | Yes |
| Research | Experimental | Yes | Yes |
| Experimental | Production | Yes | Yes |
| Emergency | Production | Expedited | Yes (retroactive) |
| Simulation | Any | N/A (ephemeral) | N/A |

## Branch Registry

| Function | Description |
|----------|-------------|
| create | Create a new branch from a source generation |
| fork | Fork a branch from another branch's generation |
| list_active | List all active generations on a branch |
| merge | Merge source branch generation into target branch |
| close | Close a branch (move to historical) |
