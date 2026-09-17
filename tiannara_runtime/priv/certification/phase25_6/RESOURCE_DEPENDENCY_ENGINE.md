# Resource Dependency Engine

## Purpose
Maps dependencies between resource categories — understanding that consuming one resource affects availability of others, and that resource systems form interdependent networks.

## Dependency Types

### Direct Dependencies
- Energy to extract/produce resources (e.g., energy for water desalination)
- Water for resource production (e.g., water for agriculture, mining)
- Materials for energy production (e.g., rare earths for wind turbines)
- Compute for resource management (e.g., AI for logistics optimization)

### Supply Chain Dependencies
- Resource A must be processed by Resource B to be useful
- Multiple resources must combine to produce a product
- Sequential dependencies (step 1 → step 2 → step 3)

### Infrastructure Dependencies
- Roads needed to transport resources
- Ports needed for bulk material handling
- Pipelines for fluid transport
- Grid for electricity distribution

### Competitive Dependencies
- Same resource used by multiple industries (e.g., water for agriculture and industry)
- Same infrastructure used by multiple resource flows

### Systemic Dependencies
- Resource system A depends on Resource system B which depends on Resource system A (circular dependencies, feedback loops)
- Failure propagation paths

## Dependency Model
For each pair of resource categories: dependency type, strength, direction, criticality, substitutability, cascade risk.

## Analysis
- Dependency graph of all resource categories
- Critical nodes (resources many others depend on)
- Failure cascade pathways
- Substitution opportunities
- Bottleneck identification

## Output
Resource dependency graph, critical node identification, cascade risk assessment, substitution analysis.
