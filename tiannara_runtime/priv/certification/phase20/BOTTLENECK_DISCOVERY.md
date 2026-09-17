# Phase 20.0 — Bottleneck Discovery Specification

## Overview

The CER operates a continuous, system-wide bottleneck detection system that monitors all subsystems for limitations. Every detected bottleneck produces an Evolution Candidate for the constitutional pipeline.

## Bottleneck Categories

### Reasoning
Limitations in logical inference, deduction, abduction, causal reasoning, counterfactual reasoning, analogical reasoning, or any form of symbolic or neural reasoning.

### Planning
Limitations in goal decomposition, plan generation, plan execution, plan repair, contingency planning, or multi-step coordination.

### Memory
Limitations in storage capacity, retrieval accuracy, retrieval latency, associative recall, episodic memory, semantic memory, or working memory binding.

### Simulation
Limitations in world model fidelity, simulation speed, counterfactual simulation, predictive accuracy, or multi-agent simulation.

### Knowledge
Limitations in knowledge coverage, knowledge consistency, knowledge freshness, cross-domain inference, or ontological completeness.

### Mathematics
Limitations in symbolic mathematics, numerical computation, theorem proving, optimization, or any mathematical reasoning capability.

### World Models
Limitations in the accuracy, resolution, or predictive power of internal world models across any domain.

### Scientific Discovery
Limitations in hypothesis generation, experimental design, observation interpretation, statistical methodology, or scientific workflow efficiency.

### Engineering
Limitations in system design, implementation, testing, debugging, or maintenance capabilities.

### Infrastructure
Limitations in compute capacity, memory capacity, network bandwidth, storage throughput, or any physical or virtual resource.

### Energy
Limitations in power consumption, thermal management, or energy efficiency that constrain runtime capabilities.

### Hardware
Limitations imposed by physical hardware capabilities, architecture constraints, or hardware roadmap projections.

### Coordination
Limitations in multi-agent communication, consensus, task allocation, synchronization, or conflict resolution.

### Civilization Planning
Limitations in long-horizon civilization-scale modeling, resource planning, risk assessment, or intergenerational optimization.

## Bottleneck Record Schema

Each bottleneck produces a record containing:
- **id:** Unique identifier
- **category:** One of the 14 categories
- **severity:** {critical, major, moderate, minor, informational}
- **impact:** Quantitative description of the limitation's effect on constitutional goals
- **frequency:** {continuous, periodic, intermittent, rare}
- **evidence:** References to observation records demonstrating the bottleneck
- **proposed_resolution_class:** {new_algorithm, new_runtime, enhanced_capability, infrastructure_change, retirement}

## Evolution Candidate Trigger

When a bottleneck exceeds constitutional severity thresholds, it automatically generates an Evolution Candidate containing:
- Reference to bottleneck record
- Proposed resolution class
- Initial scope estimate
- Priority ranking
- Resource requirement estimate

The Evolution Candidate enters the Architectural Discovery function.
