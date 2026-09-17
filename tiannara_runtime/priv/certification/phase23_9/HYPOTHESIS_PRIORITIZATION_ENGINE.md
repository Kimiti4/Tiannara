# Hypothesis Prioritization Engine

## Purpose

Rank competing hypotheses by strategic importance before allocating experimental resources. Ensure the most strategically valuable hypotheses are tested first.

## Prioritization Factors

| Factor | Description |
|--------|-------------|
| Strategic Alignment | Does testing this hypothesis serve current research missions? |
| Expected Information Gain | How much will we learn regardless of outcome? |
| Downstream Impact | How many other hypotheses depend on this result? |
| Feasibility | Can the hypothesis be tested with available resources? |
| Risk | What is the risk of not testing this hypothesis? |
| Opportunity Cost | What other hypotheses would be delayed? |

## Properties

- Hypothesis priority is dynamic — it changes with new knowledge
- Priority decomposes into component factors
- Tied hypotheses are resolved by exploratory diversity goals
- Low-priority hypotheses remain eligible for exploratory research
