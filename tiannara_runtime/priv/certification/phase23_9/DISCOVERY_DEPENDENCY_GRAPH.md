# Discovery Dependency Graph

## Purpose

Architect a directed graph representing how discoveries enable downstream discoveries, technologies, industries, and civilizational capabilities.

## Graph Structure

```
Discovery A
      ↓
Discovery B
      ↓
Technology C
      ↓
Industry D
      ↓
Civilizational Capability E
```

## Graph Properties

- Nodes represent discoveries, technologies, industries, and capabilities
- Edges represent enabling relationships
- Edge weights represent leverage magnitude
- Paths represent complete downstream chains
- The graph is derived from the knowledge graph and causal impact models

## Analytical Queries

| Query | Description |
|-------|-------------|
| DownstreamLeverage(discovery) | What does this discovery enable? |
| UpstreamDependencies(discovery) | What discoveries enabled this? |
| BottleneckAnalysis | Which discoveries unlock the most downstream value? |
| PathToCapability(discovery, capability) | What chain leads from discovery to capability? |
| CriticalPathways | Which chains are most important for civilizational goals? |
