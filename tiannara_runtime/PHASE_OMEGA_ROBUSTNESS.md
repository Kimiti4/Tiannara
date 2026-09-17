# Phase Omega Robustness Substrate

This implementation adds an OTP-supervised Omega layer that can run beside a
long soak test without stopping the existing BEAM node. Code changes affect the
next boot; they do not signal or terminate any active soak process.

## Delivered Runtime Pieces

- Executive Memory Hardening: bounded GenServer state with atomic local ETF snapshots and CPL checkpoints.
- Event Store Audit: periodic CPL hash-chain checks plus MultiWorld EventStore visibility when present.
- Checkpoint Reliability: periodic forced executive-memory checkpoints and CPL recovery-stat validation.
- Failure Observatory: centralized failure capture with CPL mirroring and event-bus publication.
- Dependency Isolation: circuit-breaker registry for optional services such as NATS or external bridges.
- Runtime Health Engine: continuous process and VM health aggregation.
- Heartbeat: one-second default heartbeat events mirrored to CPL and SentinelEventBus.
- Constitutional Scheduler: priority jobs, intervals, retries, and backoff for readiness ticks.
- Sentinel Event Bus: local in-VM pub/sub that remains useful when NATS is unavailable.
- Research Director Readiness: observation-to-candidate queueing with experiments disabled.

## Startup Order

`TiannaraRuntime.StartupSupervisor` now starts:

1. Constitutional Persistence Layer
2. Omega Robustness Substrate
3. Constitutional Observatory
4. Phoenix endpoint
5. Root runtime supervisor
6. Discovery runner

The Omega supervisor itself uses `:one_for_one` so a heartbeat, audit, or
scheduler failure does not collapse sibling robustness services.

## Validation

Focused regression coverage lives in:

`test/tiannara_runtime/omega_robustness_test.exs`

It verifies persisted CPL reload without the old `state.ets` marker assumption,
executive-memory checkpointing, event-bus publication, heartbeat continuity,
dependency circuit opening and half-open recovery, scheduler ticks, and research
candidate queue readiness.
