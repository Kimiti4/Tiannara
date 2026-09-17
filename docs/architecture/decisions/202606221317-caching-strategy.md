# ADR 202606221317: Caching Strategy

## Context
We need fast key-value storage.

## Decision
We will use Redis for all internal caching because it provides high throughput.

## Rejected Alternatives
- Memcached
- ETS

## Status
Accepted (2026-06-22)


> [!WARNING]
> **IMMUNE SYSTEM QUARANTINE**: This ADR has been flagged for Reality Drift. Its contents contradict the physical codebase.
