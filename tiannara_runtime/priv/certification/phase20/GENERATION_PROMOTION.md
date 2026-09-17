# Phase 20.9 — Generation Promotion

## Overview

Generation Promotion defines how an integration proposal progresses from a validated candidate to a frozen runtime generation. Each promotion stage requires deterministic evidence and constitutional authorization.

## Promotion Stages

### Stage 1 — Candidate Generation
The initial generation candidate containing the proposed integration.

| Property | Description |
|----------|-------------|
| Source | Validated optimization (20.8) or engineering artifact (20.6) |
| Content | Proposed changes packaged as generation delta |
| Status | Draft (not yet validated) |
| Replay | Proposed replay chain (projected, not yet verified) |

### Stage 2 — Validated Generation
The candidate has passed all compatibility and verification checks.

| Property | Description |
|----------|-------------|
| Source | Candidate Generation + CompatibilityReport |
| Content | Same as candidate, with verification artifacts |
| Status | Validated (compatibility confirmed) |
| Replay | Replay continuity verified |

### Stage 3 — Integration Ready Generation
The candidate is certified and ready for sandbox deployment.

| Property | Description |
|----------|-------------|
| Source | Validated Generation + Certificate |
| Content | Same as validated, with certification artifacts |
| Status | Integration Ready (certified) |
| Replay | Full replay verified |

### Stage 4 — Sandbox Generation
The candidate runs in an isolated sandbox runtime.

| Property | Description |
|----------|-------------|
| Source | Integration Ready Generation + Sandbox environment |
| Content | Sandbox runtime state, test results |
| Status | Sandbox (under testing) |
| Replay | Sandbox replay verified |

### Stage 5 — Canary Generation
The candidate runs in a limited canary runtime.

| Property | Description |
|----------|-------------|
| Source | Sandbox Generation (passed) + Canary environment |
| Content | Canary runtime state, metrics, observations |
| Status | Canary (under observation) |
| Replay | Canary replay verified |

### Stage 6 — Production Candidate Generation
The candidate is approved for production deployment.

| Property | Description |
|----------|-------------|
| Source | Canary Generation (passed) + Constitutional approval |
| Content | Transition plan, rollback plan, certification |
| Status | Production Candidate (approved) |
| Replay | Full system replay verified |

### Stage 7 — Current Generation
The candidate becomes the active production runtime.

| Property | Description |
|----------|-------------|
| Source | Production Candidate + Freeze |
| Content | Frozen runtime generation, archaeology records |
| Status | Current (active production) |
| Replay | Generation freeze verified, full replay confirmed |

### Stage 8 — Historical Generation
The generation is superseded and archived.

| Property | Description |
|----------|-------------|
| Source | Current Generation (replaced) |
| Content | Archived generation, cold storage manifest |
| Status | Historical (cold storage, replayable) |
| Replay | Cold storage replay verified |

## Generation Promotion Registry

| Function | Description |
|----------|-------------|
| register_candidate | Register a new generation candidate |
| advance_promotion | Advance generation to next promotion stage |
| get_promotion_status | Return current promotion stage and evidence |
| get_promotion_history | Return complete promotion history for a generation |
| verify_promotion | Verify promotion evidence integrity |
