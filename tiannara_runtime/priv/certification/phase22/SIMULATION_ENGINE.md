# Simulation Engine

## Purpose

Execute deterministic civilization simulations that evolve model state across generations according to civilizational dynamics.

## Simulation Modes

### Time-Driven Simulation
- Fixed time step progression
- State updated at each step
- Suitable for continuous dynamics
- Deterministic even with variable step count

### Event-Driven Simulation
- State updated only on events
- Events trigger state transitions
- Suitable for discrete changes
- Deterministic event ordering

### Hybrid Simulation
- Time-driven with event injection
- Events can trigger at any time step
- Both continuous and discrete dynamics
- Most general simulation mode

## Simulation State

Each simulation maintains:
- Current generation/epoch
- Civilization state (all dimensions)
- Event log (all events that occurred)
- Dynamics parameters
- Random seed (deterministic)
- Simulation fingerprint

## Simulation Execution

1. **Initialize**: Set initial state and parameters
2. **Advance**: Apply dynamics for one time step
3. **Detect Events**: Check for event triggers
4. **Process Events**: Apply event effects to state
5. **Record**: Log state and events
6. **Repeat**: Continue until termination condition
7. **Complete**: Generate simulation artifact

## Determinism Guarantee

All simulations are fully deterministic:
- Same parameters produce identical results
- Randomness is deterministic (seeded)
- Floating-point operations are deterministic
- Execution order is deterministic

## Constraints

- Simulations must be fully deterministic
- Simulation records become constitutional artifacts
