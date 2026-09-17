# Research Program Architecture

## Purpose

The Research Program Architecture defines how scientific research is hierarchically organized within Tiannara. Research is managed as a continuously evolving portfolio of programs, each containing objectives, questions, hypotheses, experiments, evidence, discoveries, and theories.

## Research Hierarchy

```
Research Domain
       ↓
Research Program
       ↓
Research Objective
       ↓
Scientific Question
       ↓
Hypothesis
       ↓
Experiment
       ↓
Evidence
       ↓
Discovery
       ↓
Theory
```

## Research Domain

A Research Domain represents a broad field of scientific inquiry (e.g., physics, biology, mathematics, engineering). Domains are long-lived and evolve as knowledge expands.

### Domain Properties
- Domain ID (content-addressed)
- Name
- Description
- Active programs
- Archived programs
- Cross-domain links

## Research Program

A Research Program is a funded, staffed, and governed initiative within a domain. Programs have budgets, timelines, objectives, and associated experiments.

### Program Properties
- Program ID (content-addressed)
- Domain reference
- Goals and objectives
- Active hypotheses
- Experiment queue
- Budget allocation
- Resource allocation
- Metrics and health
- Replay fingerprint
- Archaeology trail

## Research Objective

Objectives define specific, measurable goals within a program. Each objective maps to one or more scientific questions.

### Objective Properties
- Objective ID
- Program reference
- Description
- Success criteria
- Associated questions
- Status
- Completion evidence

## Scientific Question

Questions are the atomic unit of scientific curiosity. Each question represents something Tiannara does not know but wants to discover.

### Question Properties
- Question ID
- Objective reference
- Question text
- Domain tags
- Knowledge gap references
- Hypothesis candidates
- Priority score
- Status

## Hypothesis

A Hypothesis is a testable proposition that answers a scientific question. Hypotheses drive experiment design.

### Hypothesis Properties
- Hypothesis ID
- Question reference
- Proposition
- Predictions
- Confidence
- Supporting evidence
- Contradicting evidence
- Status

## Experiment

An Experiment is a controlled procedure designed to test a hypothesis. Experiments produce evidence.

### Experiment Properties
- Experiment ID
- Hypothesis reference
- Design configuration
- Simulation bindings
- Execution plan
- Status
- Results
- Evidence produced

## Evidence

Evidence is the output of experiments. Evidence may support or contradict hypotheses.

### Evidence Properties
- Evidence ID
- Experiment reference
- Type (observation, measurement, simulation)
- Data
- Uncertainty
- Timestamp
- Validation status

## Discovery

A Discovery occurs when evidence consistently supports a hypothesis across multiple experiments.

### Discovery Properties
- Discovery ID
- Hypothesis reference
- Supporting experiments
- Confidence level
- Impact assessment
- New questions spawned

## Theory

A Theory is a well-substantiated explanation that integrates multiple discoveries. Theories evolve as new evidence emerges.

### Theory Properties
- Theory ID
- Component discoveries
- Scope
- Predictive power
- Uncertainty bounds
- Status
- Revision history

## Program Evolution

Research programs evolve continuously:
- New questions spawn from discoveries
- Failed experiments redirect inquiry
- Cross-domain insights merge programs
- Resource constraints reshape priorities
- Constitutional mandates introduce new objectives
