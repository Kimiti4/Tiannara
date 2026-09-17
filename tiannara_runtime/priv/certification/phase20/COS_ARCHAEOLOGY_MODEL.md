# Phase 20.1 — COS Archaeology Model

## Overview
Every constitutional object must be archaeologically recoverable. Archaeology answers existential questions about every object in the system — why it was created, what problem it solved, what evidence supported it, and what eventually replaced it.

## The Seven Archaeological Questions

Every object must answer:

1. **Why was I created?** — The originating motivation or bottleneck.
2. **Which problem produced me?** — The specific BottleneckReport or evidence that triggered creation.
3. **Which evidence justified me?** — The EvolutionEvidence that supported the decision to create this object.
4. **Which proposal created me?** — The EvolutionProposal that formally proposed this object.
5. **Which generation integrated me?** — The RuntimeGeneration that first included this object.
6. **What replaced me?** — The object(s) that superseded this one (if any).
7. **Why was replacement accepted?** — The rationale and evidence for the replacement decision.

## Archaeology Registry

| Function | Description |
|----------|-------------|
| register | Register an object's archaeological record |
| explain | Given an object id, return answers to all 7 archaeology questions |
| lineage | Return the full historical lineage of an object (ancestors and descendants) |

## Reconstruction Property

Archaeology must be reconstructable from evidence and replay alone. No runtime state is required. This means:

- Given only the `evidence_root` and `replay_root`, any object's full history can be reconstructed.
- The `ArchaeologyRegistry` indexes this information for efficient querying.
- If the registry is lost, it can be rebuilt entirely from the replay and evidence chains.

## Archaeology Root

- Each object's `archaeology_root` is `SHA-256(answers_to_7_questions)`.
- The root links the object to its full historical context.
- Archaeology roots form a chain that can be traversed backward through time.

## Constraints

- **No runtime state required** — archaeology must work from cold storage with only evidence + replay data.
- **Deterministic** — rebuilding archaeology from the same evidence and replay always produces identical answers.
- **Reconstructable** — the full archaeology chain can be rebuilt from genesis if the registry is destroyed.
