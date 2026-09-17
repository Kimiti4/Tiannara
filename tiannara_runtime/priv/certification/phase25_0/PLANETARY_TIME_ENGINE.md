# Planetary Time Engine

## Purpose

Define the time engine that maintains the planetary clock across all runtime operations.

## Time Model

- **Wall Clock** — System time synchronized to UTC.
- **Logical Clock** — Monotonically increasing counter for event ordering.
- **Simulation Time** — Virtual time for scenario execution (decoupled from wall clock).
- **Planetary Time** — Aggregated time representation combining all three.

## Time Responsibilities

1. **Clock Distribution** — Distribute authoritative time to all subsystems.
2. **Clock Synchronization** — Ensure all subsystems agree on time.
3. **Timestamp Assignment** — Assign timestamps to all events.
4. **Time Zone Management** — Handle planetary time zones.
5. **Simulation Time** — Manage virtual time for scenarios.
6. **Time Arithmetic** — Support time-based calculations across timescales.
7. **Calendar Management** — Handle calendar systems and date arithmetic.

## Timescales

| Timescale | Granularity | Horizon | Uses |
|---|---|---|---|
| Real-Time | Milliseconds | Minutes | System monitoring, alerts |
| Operational | Seconds | Days | State updates, observations |
| Tactical | Hours | Months | Risk assessment, planning |
| Strategic | Days | Years | Scenario evolution, policy |
| Long-Horizon | Months | Centuries | Civilization modeling |
| Archaeological | Years | Millennia | Historical analysis |

## Time Integrity

- All timestamps include uncertainty bounds.
- Clock drift monitored and compensated.
- Time synchronization events recorded in event log.
- Time engine state included in checkpoints.
- Time can be replayed deterministically.
