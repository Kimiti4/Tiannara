# Phase 20.0 — Architectural Archaeology Specification

## Overview

Architectural Archaeology is the COS function that preserves complete architectural lineage for every subsystem. Every generation of every subsystem is fully reconstructable and replayable. Nothing is ever lost.

## Core Questions

The archaeology system must be able to answer:

1. **Why was this architecture created?**
   - Which bottleneck or opportunity motivated its creation?
   - Which observation triggered its evolution pipeline entry?

2. **What problem did it solve?**
   - What specific limitation did it address?
   - How was the limitation measured before the change?

3. **What replaced it?**
   - Which architecture succeeded it?
   - What was the evolutionary path?

4. **Why was replacement justified?**
   - What evidence demonstrated the replacement's superiority?
   - Which benchmarks, experiments, or audits supported the change?

5. **Which experiments proved superiority?**
   - Complete reference to the constitutional experiment artifacts
   - All observations, hypotheses, predictions, and results

## Archaeology Record Schema

Each generation of each subsystem produces an archaeology record containing:

### Identity
- **subsystem_id:** UUID
- **generation_id:** UUID
- **generation_number:** Monotonically increasing integer
- **status:** {active, superseded, retired}

### Temporal
- **created:** ISO 8601 timestamp of constitutional certification
- **superseded:** ISO 8601 timestamp of replacement (nullable)
- **retired:** ISO 8601 timestamp of retirement (nullable)

### Artifacts
- **source:** Complete source code or equivalent specification
- **configuration:** Complete configuration snapshot
- **interfaces:** Complete interface specifications
- **dependencies:** Complete dependency tree with versions
- **documentation:** All associated documentation

### Performance
- **benchmarks:** Complete benchmark results from constitutional evaluation
- **baselines:** Performance baselines measured during production
- **comparisons:** Cross-generation comparison metrics

### Behavioral
- **recordings:** Behavioral traces from sandbox, canary, and production
- **replay_scripts:** Scripts required to reproduce behavior

### Certification
- **certification_ref:** Reference to constitutional certification
- **experiment_ref:** Reference to constitutional experiment
- **audit_ref:** Reference to independent audit

### Evolution
- **predecessor_generation_id:** UUID of previous generation
- **successor_generation_id:** UUID of next generation (nullable)
- **change_description:** What changed from predecessor
- **rationale:** Why the change was made

## Deterministic Replay

Every archaeology record must support deterministic replay:
- The subsystem can be instantiated in its exact archived state
- Dependencies are recreated at their exact archived versions
- Configuration is applied exactly as archived
- Behavioral traces can be verified against replay output
- Any discrepancy indicates a replay infrastructure failure

## Preservation Guarantees

- No subsystem generation is ever deleted
- No artifact within a generation is ever deleted
- Archaeological records are immutable after creation
- Archaeological records are stored redundantly
- Archaeological records are verifiable via cryptographic hash
- Archaeological records are traversable in both lineage directions
