# Resource Allocation Engine

## Purpose

The Resource Allocation Engine governs deterministic allocation of computational and knowledge resources across the experiment portfolio. Every allocation is justified constitutionally, recorded immutably, and replayable.

## Resource Types

| Resource | Unit | Description |
|----------|------|-------------|
| CPU | Core-hours | Central processing time |
| GPU | GPU-hours | Graphics processing for simulations |
| Memory | GB-hours | Working memory allocation |
| Simulation Capacity | Simulation-slots | Concurrent simulation instances |
| Knowledge Resources | Query-credits | Access to knowledge base queries |
| Engineering Resources | Build-credits | Engineering verification capacity |
| External Data Sources | Data-credits | External data acquisition |
| Storage | GB | Persistent storage for experiment data |

## Allocation Model

```
ResourceAllocation {
  allocation_id: content-addressed,
  experiment_id: reference,
  resources: {
    cpu: { allocated, used, remaining },
    gpu: { allocated, used, remaining },
    memory: { allocated, used, remaining },
    simulation_capacity: { allocated, used, remaining },
    knowledge_resources: { allocated, used, remaining },
    engineering_resources: { allocated, used, remaining },
    external_data: { allocated, used, remaining },
    storage: { allocated, used, remaining }
  },
  priority_at_allocation: float,
  constitutional_justification: string,
  timestamp: integer,
  allocation_hash: string
}
```

## Allocation Policy

### Base Allocation
Each experiment receives a base allocation determined by:
- Experiment type (simulation, validation, exploration)
- Estimated resource requirements
- Historical resource usage for similar experiments

### Priority Bonus
Higher-priority experiments receive additional allocation:
- Critical: +50% over base
- High: +25% over base
- Medium: Base allocation
- Low: -25% from base
- Deferred: -50% from base

### Constraint
Total allocated resources never exceed available capacity. When resources are exhausted, lower-priority experiments are deferred.

## Allocation Lifecycle

```
Request → Evaluate → Approve → Allocate → Monitor → Release → Account
```

1. **Request**: Experiment requests resources
2. **Evaluate**: Priority and requirements assessed
3. **Approve**: Constitutional justification recorded
4. **Allocate**: Resources assigned
5. **Monitor**: Usage tracked against allocation
6. **Release**: Resources freed on completion
7. **Account**: Final usage recorded for replay

## Constitutional Guarantees

- All allocations are content-addressed and immutable
- Allocation decisions are replayable
- Resource usage is verifiable post-hoc
- No experiment receives resources without justification
- Allocation history is archaeologically traceable
