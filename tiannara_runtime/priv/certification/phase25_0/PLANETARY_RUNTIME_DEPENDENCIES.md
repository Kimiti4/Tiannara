# Planetary Runtime Dependencies

## Purpose

Define the dependency relationships between the planetary runtime and other systems.

## Internal Dependencies

```
Planetary Runtime
    ├── Depends on: Event Engine, Time Engine, Memory Engine
    ├── Checkpoint Engine → Memory Engine, Event Engine
    ├── Recovery Engine → Checkpoint Engine, Memory Engine
    ├── Coordinator → Subsystem Registry, Event Engine
    ├── Synchronization Engine → Coordinator, State Engine
    └── Context Engine → Memory Engine, Time Engine
```

## External Dependencies

| Dependency | Description | Criticality |
|---|---|---|
| Phase 23 Scientific Runtime | Scientific discovery capabilities | High |
| Phase 24 Engineering Runtime | Engineering program execution | High |
| Observatory (Phase 23.0) | Metrics and display infrastructure | Medium |
| Constitution | Governance and constraint rules | Critical |
| NATS/JetStream | Inter-system messaging | High |
| Storage System | Durable state persistence | Critical |
| Cryptographic Services | Signing and verification | High |

## Dependency Management

- Dependencies declared in subsystem registry.
- Dependency health monitored continuously.
- Dependency failures trigger escalation.
- Dependency upgrades coordinated through runtime.
- Circular dependencies prevented by architecture.

## Dependency Resilience

- Critical dependencies have hot failover.
- Non-critical dependencies have graceful degradation.
- Dependency timeouts prevent cascading failures.
- Dependency failures recorded in event log.
- Post-mortem analysis for dependency failures.
