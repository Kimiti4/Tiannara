# Phase 20.2 — Constitutional Message Specification

Subsystems communicate exclusively through constitutional messages. No shared mutable state exists. No direct inter-subsystem calls are permitted. All messages pass through the Constitutional Execution Fabric.

## Core Principle

Messages are immutable, content-addressed, and routed through the fabric. No subsystem ever calls another subsystem directly.

## Message Categories

| Category | Description |
|---|---|
| Mission | Messages related to mission creation, scheduling, dispatch, completion |
| Evidence | Messages carrying evidence artifacts between stages |
| Replay | Messages related to replay chain generation and verification |
| Knowledge | Messages updating knowledge, theories, models |
| Coordination | Messages coordinating subsystems and extensions |
| Resource | Messages allocating and releasing resources |
| Audit | Messages recording audit information |
| Evolution | Messages governing system evolution and extension lifecycle |

## Message Structure

Every message contains the following fields:

| Field | Type | Required | Description |
|---|---|---|---|
| message_id | string | yes | Unique content-addressed identifier |
| category | string | yes | One of the defined message categories |
| type | string | yes | Message type within the category |
| source | string | yes | Originating subsystem |
| target | string | yes | Target subsystem |
| payload | object | no | Message payload |
| fingerprint | string | yes | SHA-256 content fingerprint |
| timestamp | integer | yes | Unix timestamp of message creation |

## Message Constraints

- **Immutable**: Messages cannot be modified after creation
- **Content-addressed**: message_id is derived from content via SHA-256
- **No direct subsystem calls**: All messages are routed through the fabric
- **No shared mutable state**: The fabric holds the authoritative state
- **Replayable**: Message sequences can be replayed with identical ordering
