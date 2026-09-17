# Phase 20.3 — Evolution Archaeology Model

## Overview

Every evolution object must be archaeologically recoverable. Evolution archaeology answers existential questions about every architectural decision — why a bottleneck was addressed, which candidate was chosen, which evidence supported the choice, and what eventually replaced it.

## The Seven Archaeological Questions (Evolution)

Every evolution object must answer:

1. **Why was I created?** — The originating bottleneck or evolution opportunity that triggered this object's creation.

2. **Which observations produced me?** — The specific ObservationRecords and telemetry data that motivated this object.

3. **Which evidence justified me?** — The EvolutionEvidence (simulation results, benchmark measurements, audit reports) that supported the decision to create this object.

4. **Which hypothesis generated me?** — The ArchitecturalHypothesis that formally proposed the resolution mechanism this object implements.

5. **Which generation integrated me?** — The EvolutionGeneration that first included this object, with full generation context.

6. **What replaced me?** — The generation(s) or candidates that superseded this one, with timestamps and rationale.

7. **Why was replacement accepted?** — The evidence, metrics, and constitutional decision that justified the replacement.

## Evolution Archaeology Registry

| Function | Description |
|----------|-------------|
| register | Register an evolution object's archaeological record |
| explain | Given an object id, return answers to all 7 archaeology questions |
| lineage | Return the full evolutionary lineage (ancestors and descendants) |
| generation_history | Return complete generation timeline from genesis |
| bottleneck_lineage | Return all candidates that addressed a specific bottleneck |

## Reconstruction Property

Evolution archaeology must be reconstructable from evidence and replay alone. No runtime state is required:

- Given only `evidence_root` and `replay_root`, any evolution object's full history can be reconstructed
- The EvolutionArchaeologyRegistry indexes this information for efficient querying
- If the registry is lost, it can be rebuilt entirely from replay and evidence chains
- Cold storage contains sufficient information for full archaeological reconstruction

## Archaeology Root

- Each evolution object's `archaeology_root` = SHA-256(answers_to_7_questions)
- The root links the object to its full historical context within the evolution lineage
- Archaeology roots form a chain traversable backward through all generations
- Root chains from different objects converge at shared ancestors (generations, bottlenecks)

## Generation Archaeology

Every EvolutionGeneration stores:

- `archaeology_root`: SHA-256 of the complete generation archaeological record
- `parent_archaeology`: Reference to parent generation's archaeology root
- `lineage_map`: Complete ancestor chain from genesis
- `decision_log`: Every EvolutionDecision made during this generation's lifecycle
- `candidate_history`: All candidates considered (accepted, rejected, rolled back)
- `metric_timeline`: EvolutionMetrics at freeze time

## Lineage Traversal

The lineage is a directed acyclic graph rooted at generation 0:

```
Generation 0 (genesis)
    ↓
Generation 1 (candidate A)
    ↓
Generation 2 (candidate B)
    ↓
Generation 3 (rollback to 2, candidate C)
    ↓
Generation 4 (candidate D)
    ↓
...
```

Each node stores:
- generation number
- parent generation number
- constitutional_hash
- archaeology_root
- list of candidates considered
- bottlenecks resolved in this generation
- rollback events (if any)

## Cold Storage Archaeology

From cold storage alone (no runtime state):

1. Read the replay chain from replay_root
2. Reconstruct each evolution object in order
3. For each object, re-derive the answers to the 7 archaeological questions from the object's replay + evidence data
4. Compute archaeology_root from the answers
5. Verify archaeology_root matches stored value
6. Reconstruct the complete generation lineage

This property ensures that Tiannara's evolutionary history can be recovered even after catastrophic data loss, as long as the replay and evidence chains survive.

## Constraints

- **No runtime state required** — archaeology works from cold storage with only evidence + replay data
- **Deterministic** — rebuilding archaeology from the same evidence and replay always produces identical answers and identical archaeology_root hashes
- **Reconstructable** — the full evolution archaeology chain can be rebuilt from genesis if the registry is destroyed
- **Complete** — every rejected candidate, failed experiment, and rolled-back generation is preserved; nothing is deleted from the archaeological record
