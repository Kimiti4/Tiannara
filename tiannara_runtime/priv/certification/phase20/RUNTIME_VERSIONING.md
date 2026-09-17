# Phase 20.5 — Runtime Versioning

## Overview

Runtime Versioning defines the semantic constitutional versioning scheme for all runtime generations. Versions are deterministic, replayable, and encode the complete evolutionary context of a generation.

## Version Format

```
MAJOR.MINOR.GENERATION.BUILD
```

### Example: `20.5.0.17`

| Component | Value | Meaning |
|-----------|-------|---------|
| MAJOR | 20 | Phase number (constitutional era) |
| MINOR | 5 | Architecture revision within phase |
| GENERATION | 0 | Generation count within this minor version |
| BUILD | 17 | Immutable build identifier |

## Component Semantics

### MAJOR (Phase)
Incremented when a new constitutional phase is initiated. Represents a fundamental expansion of the operating system's constitutional scope.

- 1–14: Pre-constitutional phases (archaeological)
- 15–19: Cognitive OS foundation
- 20+: Constitutional Operating System

### MINOR (Architecture Revision)
Incremented when a sub-phase introduces architectural changes that modify interfaces, data models, or constitutional contracts. Resets GENERATION and BUILD to 0.

### GENERATION
Incremented each time a new runtime generation is frozen in production. Represents an immutable operating system version. Never resets within a MINOR version.

### BUILD
Incremented for each certified candidate integration within a generation. Each BUILD represents a specific set of integrated innovations. Builds are monotonic within a generation.

## Version Rules

- Versions are immutable once assigned to a frozen generation
- Version assignment is deterministic (same constituents always produce same version)
- Versions encode full evolutionary context (phase, revision, generation count, build count)
- Versions support comparison (greater version = later generation)
- Versions are human-readable and machine-parseable

## Version Comparison

Comparison rules follow lexicographic order of [MAJOR, MINOR, GENERATION, BUILD]:

```
20.5.0.17 < 20.5.1.0 < 20.5.1.5 < 21.0.0.0
```

## Version Registry

| Function | Description |
|----------|-------------|
| encode | Encode generation parameters into version string |
| decode | Parse version string into components |
| compare | Compare two versions (less, equal, greater) |
| successor | Compute next version for a given context |
| latest | Return latest version for a given MAJOR.MINOR |
