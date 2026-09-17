# Planetary Context Engine

## Purpose

Define the context engine that provides runtime context to all planetary subsystems.

## Context Contents

- **Planetary State** — Current authoritative planetary state snapshot.
- **Time Context** — Current wall clock, logical clock, and simulation time.
- **Runtime Configuration** — Active runtime configuration parameters.
- **System Status** — Status of all registered subsystems.
- **Active Constraints** — Currently active constitutional constraints.
- **Pending Events** — Events awaiting processing.
- **Checkpoint Information** — Last checkpoint timestamp and hash.
- **Security Context** — Current security credentials and permissions.
- **Observability Context** — Active observability subscriptions.

## Context Distribution

- Context pushed to subsystems on change.
- Context available on-demand via query.
- Context versioned for consistency tracking.
- Context included in checkpoints.
- Context replayable for historical reconstruction.

## Context Scope

- **Global Context** — Available to all subsystems.
- **Domain Context** — Domain-specific context (climate, energy, etc.).
- **Subsystem Context** — Context specific to a single subsystem.
- **Temporal Context** — Context valid for a specific time window.

## Context Integrity

- Context cryptographically signed.
- Context tampering detectable.
- Context lineage preserved.
- Context conflicts detectable and resolvable.
