# Experiment Archaeology

## Overview
Experiment Archaeology is the systematic study of past experiments to understand their context, evolution, and impact on Tiannara's constitutional development. It provides a historical lens for understanding why experiments existed, who introduced them, what they disproved, and what discoveries they produced.

## Archaeological Dimensions

### 1. Provenance Tracking
- **Origin**: What RFC or governance issue prompted this experiment?
- **Introducer**: Who proposed and owned this experiment?
- **Approval Path**: Which institutions approved the experiment and why?
- **Dependencies**: What prior experiments or constitutional changes were required?

### 2. Impact Analysis
- **Disproven Claims**: What hypotheses were invalidated by this experiment?
- **Validated Discoveries**: What new knowledge was confirmed?
- **Replacement Experiments**: What subsequent experiments replaced or evolved this one?
- **Governance Changes**: Which constitutional amendments or RFCs were directly influenced?

### 3. Evolutionary Tracing
- **Experiment Lineage**: Parent-child relationships between related experiments
- **Hypothesis Evolution**: How the hypothesis changed over time
- **Methodology Evolution**: Changes in experimental design or statistical approaches
- **Outcome Refinement**: Evolution of measured outcomes and confidence levels

## Archaeological Record Structure

### Experiment Artifact
```json
{
  "experiment_id": "EXP-2026-001",
  "genealogy": {
    "parent_experiments": ["EXP-2025-042", "EXP-2025-087"],
    "child_experiments": ["EXP-2026-015", "EXP-2026-023"],
    "sibling_experiments": ["EXP-2026-002", "EXP-2026-003"]
  },
  "context": {
    "prompting_rfc": "RFC-152",
    "governance_issue": "institutional deadlock resolution",
    "urgency": "critical"
  },
  "discovery": {
    "primary_finding": "Decentralized voting reduces deadlock by 34%",
    "secondary_findings": [
      "Increased voter participation by 12%",
      "Reduced implementation latency by 8%"
    ],
    "disproven_assumptions": [
      "Assumed centralized authority was more efficient"
    ]
  },
  "replacement": {
    "superseded_by": "EXP-2026-015",
    "supersedes": null,
    "evolved_into": "RFC-158"
  }
}
```

### Discovery Trace
- **Observation**: Initial observation that triggered the experiment
- **Hypothesis**: The testable claim made by the experiment
- **Prediction**: Specific, measurable predictions
- **Evidence**: Collected evidence artifacts
- **Analysis**: Statistical and qualitative analysis
- **Conclusion**: Final determination and implications
- **Knowledge Integration**: How findings were incorporated into governance

## Archaeological Queries

### Historical Reconstruction
```
Given: RFC-152
Find: All experiments that tested or were inspired by RFC-152
Trace: The evolution of ideas from proposal to implementation
```

### Counterfactual Analysis
```
Given: Experiment EXP-2026-001
Question: What if this experiment had never been run?
Trace: Alternative governance paths and their consequences
```

### Discovery Mapping
```
Given: Institutional deadlock problem
Find: All experiments addressing this issue
Rank: By evidence quality and impact
Synthesize: Combined learnings into governance principles
```

## Archaeological Tools

### Experiment Timeline
Visualizes the chronological sequence of experiments, showing:
- Temporal relationships
- Parallel experiments
- Sequential dependencies
- Gaps in experimentation

### Discovery Graph
Maps the flow of knowledge from:
- Observations → Experiments → Discoveries → Governance Changes

### Evolution Tree
Shows how experimental designs and hypotheses evolved over time, including:
- Branching experiments
- Merged experiments
- Abandoned approaches
- Refined methodologies

## Integration with Knowledge Graph

The Experiment Archaeology feeds into the broader knowledge graph by:
1. **Linking Experiments**: Creating edges between related experiments
2. **Tracking Discoveries**: Mapping findings to scientific outputs
3. **Governance Lineage**: Tracing constitutional changes to experimental evidence
4. **Institutional Memory**: Preserving lessons learned for future governance

## Validation Requirements
- All archaeological records must be content-addressable
- Provenance must be cryptographically verifiable
- Discovery claims must reference evidence artifacts
- Evolution traces must be reconstructable from ledger data
- Archaeological conclusions must be independently reproducible