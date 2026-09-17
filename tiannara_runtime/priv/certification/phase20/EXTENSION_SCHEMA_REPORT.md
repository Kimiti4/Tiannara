# Phase 20.0 — Extension Schema Report

## Purpose

This document specifies the required schema for all Constitutional Extensions. Every extension registered in the COS must conform to this schema exactly.

## Schema Definition

```json
{
  "id": "string (UUID, globally unique, immutable)",
  "name": "string (human-readable, ASCII, 1-128 characters)",
  "type": "string (one of: runtime, service, framework, interface, protocol, agent, tool)",
  "version": "string (semver, MAJOR.MINOR.PATCH)",
  "status": "string (one of: proposed, review, validated, certified, sandbox, canary, production, retired)",
  "dependencies": [
    {
      "extension_id": "string (UUID of dependency)",
      "constraint": "string (semver constraint)",
      "optional": "boolean"
    }
  ],
  "certification_ref": "string (UUID referencing the constitutional certification artifact)",
  "sandbox_period": {
    "start": "string (ISO 8601 timestamp)",
    "end": "string (ISO 8601 timestamp)",
    "duration_hours": "number"
  },
  "canary_period": {
    "start": "string (ISO 8601 timestamp)",
    "end": "string (ISO 8601 timestamp)",
    "duration_hours": "number",
    "traffic_percentage": "number (0-100)"
  },
  "rollback_triggers": [
    {
      "condition": "string (machine-readable condition expression)",
      "description": "string (human-readable trigger explanation)",
      "action": "string (one of: rollback, pause, alert, halt)"
    }
  ],
  "archaeological_ref": "string (UUID referencing the archaeological record)"
}
```

## Field Requirements

| Field | Required | Immutable | Description |
|-------|----------|-----------|-------------|
| id | Yes | Yes | Globally unique extension identifier |
| name | Yes | No | Human-readable name |
| type | Yes | No | Extension type classification |
| version | Yes | No | Current version (semver) |
| status | Yes | No | Current lifecycle status |
| dependencies | No | No | Extension dependency list |
| certification_ref | Yes | Yes | Reference to certification artifact |
| sandbox_period | Yes* | Yes | Sandbox deployment period (*required if status >= sandbox) |
| canary_period | Yes* | Yes | Canary deployment period (*required if status >= canary) |
| rollback_triggers | Yes | No | Automatic rollback conditions |
| archaeological_ref | Yes | Yes | Reference to archaeological record |

## Validation Rules

- All UUIDs must be RFC 4122 compliant
- Semver must follow https://semver.org/
- Dependencies must not form cycles
- certification_ref must point to a certified constitutional experiment
- archaeological_ref must point to a completed archaeological record
- No two active extensions may have the same name
- Status transitions must follow the constitutional lifecycle (no skipping stages)
