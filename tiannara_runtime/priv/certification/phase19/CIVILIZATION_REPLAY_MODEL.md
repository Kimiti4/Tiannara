# Phase 19 — Civilizational Replay Model

## Replay Architecture

The civilizational replay model provides deterministic reconstruction of the entire civilization state from logged artifacts. The root of replay is the `civilization_id`, from which all subsystem replay roots are derived.

## Replay Hierarchy

```
civilization_root (CivilizationId)
├── institution_root
│   ├── InstitutionManager state
│   ├── InstitutionRegistration artifacts
│   └── Charter artifacts
├── portfolio_root
│   ├── PortfolioGovernor state
│   ├── GovernanceAction artifacts
│   └── Allocation artifacts
├── economy_root
│   ├── ScientificEconomy state
│   ├── CapitalLedger artifacts
│   └── RewardEvent artifacts
├── collaboration_root
│   ├── CollaborationEngine state
│   ├── CollaborationGraph artifacts
│   └── DiscoveryEdge artifacts
└── knowledge_root
    ├── CivilizationKnowledgeGraph state
    ├── MergeEvent artifacts
    └── KnowledgeNode artifacts
```

## Reconstruction Procedure

1. **Seed**: Load `civilization_id` → locate `civilization_root` artifact.
2. **Institution**: Descend to `institution_root` → replay InstitutionManager event log → reconstruct institution registry.
3. **Portfolio**: Descend to `portfolio_root` → replay PortfolioGovernor event log → reconstruct portfolio state.
4. **Economy**: Descend to `economy_root` → replay ScientificEconomy event log → reconstruct capital ledger.
5. **Collaboration**: Descend to `collaboration_root` → replay CollaborationEngine event log → reconstruct collaboration graph.
6. **Knowledge**: Descend to `knowledge_root` → replay CivilizationKnowledgeGraph event log → reconstruct knowledge graph.

## Determinism Guarantee

For any two replays seeded with the same `civilization_root`:

- The same event sequence must be produced.
- The same `final_state_hash` must be computed.
- The same set of subsystem roots must be traversed.

## Replay Artifact Structure

```
CivilizationReplay {
  replay_id: ReplayId,
  root: CivilizationRoot {
    civilization_id: CivilizationId,
    root_hash: Hash,
    subsystem_roots: {
      institution: ArtifactRoot,
      portfolio: ArtifactRoot,
      economy: ArtifactRoot,
      collaboration: ArtifactRoot,
      knowledge: ArtifactRoot,
    },
  },
  replay_log: [ReplayEvent],
  final_state_hash: Hash,
}
```

## Idempotency

Replaying the same artifact set multiple times must produce identical `final_state_hash`. No side effects are permitted during replay. Replay is read-only with respect to the artifact store.

## Archaeology Integration

The Archaeology subsystem uses replay roots as excavation starting points. By traversing the replay hierarchy in reverse, Archaeology can recover earlier civilization states from artifact traces.
