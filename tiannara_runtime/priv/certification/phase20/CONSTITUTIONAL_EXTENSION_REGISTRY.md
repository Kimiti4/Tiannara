# Phase 20.0 — Constitutional Extension Registry

## Overview

The Constitutional Extension Registry is the authoritative record of all constitutional extensions in Tiannara. It is registry-driven, deterministic, and fully replayable.

## Registry Entry Schema

Each extension registry entry contains:

### Identification
- **extension_id:** UUID (immutable)
- **name:** Extension name
- **type:** Extension type

### Timeline
- **proposal_date:** ISO 8601 timestamp
- **architecture_review_date:** ISO 8601 timestamp (nullable)
- **certification_date:** ISO 8601 timestamp (nullable)
- **sandbox_deployment:** ISO 8601 timestamp (nullable)
- **canary_deployment:** ISO 8601 timestamp (nullable)
- **production_deployment:** ISO 8601 timestamp (nullable)

### Status
- **current_status:** {proposed, review, validated, certified, sandbox, canary, production, retired}
- **status_history:** Array of {status, timestamp, reason, certification_ref}
- **health:** {healthy, degraded, critical, paused}

### Lineage
- **parent_extension_id:** UUID (nullable, for forked extensions)
- **child_extension_ids:** Array of UUID
- **replaces_extension_id:** UUID (nullable, for superseding extensions)
- **replaced_by_extension_id:** UUID (nullable)

### References
- **archaeological_refs:** Array of UUID linking to archaeological records
- **certification_refs:** Array of UUID linking to certification documents
- **experiment_refs:** Array of UUID linking to constitutional experiments

## Registry Properties

- **Deterministic:** The registry state is fully determined by the sequence of constitutional events
- **Replayable:** The registry can be reconstructed from scratch by replaying all events
- **Immutable:** Historical entries are never modified; corrections create new entries
- **Auditable:** Every registry change references its constitutional authorization
- **Complete:** No extension exists outside the registry

## Registry Operations

### Register Extension
Creates a new registry entry in "proposed" status. Requires proposal documentation.

### Advance Status
Transitions an extension to the next lifecycle stage. Requires constitutional certification for each advance.

### Retire Extension
Marks an extension as retired. Requires retirement certification and archaeological preservation verification.

### Query Registry
Registry supports queries by: id, name, type, status, date range, lineage, and any combination thereof.

## Event Log

Every registry operation produces an immutable event log entry:
- event_id, event_type, extension_id, timestamp, previous_status, new_status, certification_ref, rationale
