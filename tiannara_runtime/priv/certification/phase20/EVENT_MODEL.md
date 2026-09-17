# Phase 20.2 — Constitutional Event Model

Every interaction within the Constitutional Execution Fabric becomes an immutable event. Events form the backbone of the constitutional record, providing replayability, auditability, and archaeological lineage.

## Core Principle

Events are content-addressed, replayable, and immutable. Once committed, an event can never be modified or deleted.

## Event Types

| Event Type | Description |
|---|---|
| MissionCreated | A new mission has been created and validated |
| MissionQueued | A mission has been scheduled and added to the execution queue |
| MissionStarted | A mission has been dispatched to a subsystem |
| MissionCompleted | A mission has completed successfully |
| MissionFailed | A mission has failed during execution |
| MissionCancelled | A mission has been cancelled |
| EvidenceProduced | Evidence has been collected from a mission |
| ReplayGenerated | A replay chain has been generated for a mission |
| KnowledgeUpdated | Knowledge has been updated from mission evidence |
| TheoryGenerated | A new theory has been generated |
| ModelUpdated | A model has been updated |
| ExtensionIntegrated | An extension has been integrated into the system |
| ExtensionRetired | An extension has been retired |
| RollbackTriggered | A rollback has been triggered |
| CivilizationUpdated | The civilization state has been updated |

## Event Structure

Every event contains the following fields:

| Field | Type | Required | Description |
|---|---|---|---|
| event_id | string | yes | Unique content-addressed identifier |
| event_type | string | yes | One of the defined event types |
| timestamp | integer | yes | Unix timestamp of event creation |
| source | string | yes | Subsystem or component that produced the event |
| target | string | yes | Subsystem or component the event targets |
| payload | object | no | Event-specific payload data |
| fingerprint | string | yes | SHA-256 content fingerprint |
| replay_root | string | no | Root of the replay chain this event belongs to |
| archaeology_root | string | no | Root of the archaeology lineage this event belongs to |
| metadata | object | no | Additional metadata |

## Event Constraints

- **Content-addressed**: event_id is derived from the event content using SHA-256
- **Replayable**: The full event sequence can be replayed with identical ordering and hashes
- **Immutable**: Once committed, events cannot be altered
- **Ordered**: Events within a mission form a total order via their replay chain
- **Linkable**: Events reference related events via replay_root and archaeology_root
