# Phase 20.7 — Experiment Pipeline

## Overview

The Experiment Pipeline governs every experiment from proposal through freeze. All 12 stages must complete in order. No stage may be skipped.

## Stage 1 — Proposal

- **Input:** Experiment proposal from Engineering (20.6), Discovery (15), Research (16), or Runtime Evolution (20.3)
- **Process:** Validate proposal structure, record purpose, hypothesis, prediction, variables, constraints
- **Output:** ExperimentProposal with experiment_id, hypothesis, variables, statistical plan
- **Artifacts:** ExperimentProposed event, draft ExperimentPlan
- **Failure Conditions:** Proposal malformed, hypothesis unfalsifiable, variables undefined
- **Replay:** Proposal must reproduce identical experiment_id and parameters

## Stage 2 — Constitutional Review

- **Input:** ExperimentProposal, constitutional rules, safety constraints
- **Process:** Verify constitutional compliance, safety assumptions, resource bounds, ethical constraints
- **Output:** ConstitutionalReviewReport with pass/fail, conditions, constraints
- **Artifacts:** ConstitutionalReview event, review evidence
- **Failure Conditions:** Constitutional violation, unsafe design, insufficient controls
- **Replay:** Review must produce identical pass/fail decision

## Stage 3 — Resource Reservation

- **Input:** Approved proposal, resource availability
- **Process:** Reserve compute, memory, time, and domain-specific resources for experiment execution
- **Output:** ResourceReservation with budget allocations, time window
- **Artifacts:** ResourceReserved event, reservation evidence
- **Failure Conditions:** Insufficient resources, budget exceeds limits
- **Replay:** Reservation must produce identical budget allocation

## Stage 4 — Environment Preparation

- **Input:** ResourceReservation, ExperimentProposal
- **Process:** Prepare execution environment: initialize state, load dependencies, configure parameters, set up controls
- **Output:** EnvironmentSnapshot with initialized state hash, configuration fingerprint
- **Artifacts:** EnvironmentPrepared event, environment evidence
- **Failure Conditions:** Environment initialization failure, dependency conflict
- **Replay:** Environment must produce identical initialization state

## Stage 5 — Execution

- **Input:** EnvironmentSnapshot, ExperimentProposal
- **Process:** Execute experiment: apply treatments, collect observations, record all outputs
- **Output:** ExperimentRun with raw observations, execution trace, timing data
- **Artifacts:** ExperimentExecuted event, execution evidence
- **Failure Conditions:** Execution failure, resource exhaustion, safety limit reached
- **Replay:** Execution must produce identical observations and traces

## Stage 6 — Observation Capture

- **Input:** ExperimentRun
- **Process:** Capture and structure all observations: independent variable measurements, dependent variable measurements, control measurements, environmental conditions
- **Output:** ObservationSet with structured observations, metadata, quality metrics
- **Artifacts:** ObservationsCaptured event, observation evidence
- **Failure Conditions:** Missing observations, corrupted data, quality below threshold
- **Replay:** Observations must produce identical structured data

## Stage 7 — Statistical Analysis

- **Input:** ObservationSet, statistical plan (from proposal)
- **Process:** Apply statistical methods: hypothesis testing, confidence intervals, effect size, power analysis, sensitivity analysis
- **Output:** StatisticalReport with test statistics, p-values, confidence intervals, effect sizes, conclusions
- **Artifacts:** StatisticalAnalysis event, analysis evidence
- **Failure Conditions:** Invalid statistics, assumptions violated, insufficient power
- **Replay:** Analysis must produce identical statistics and conclusions

## Stage 8 — Result Classification

- **Input:** StatisticalReport, success criteria (from proposal), failure criteria
- **Process:** Classify result: confirmed, refuted, inconclusive, ambiguous, error
- **Output:** ResultClassification with classification, confidence, recommendations
- **Artifacts:** ResultClassified event, classification evidence
- **Failure Conditions:** Classification criteria undefined, contradictory evidence
- **Replay:** Classification must produce identical result

## Stage 9 — Reproducibility Verification

- **Input:** Full experiment artifact set
- **Process:** Reproduce experiment from proposal: replay entire pipeline, verify identical observations, statistics, and classification
- **Output:** ReproducibilityReport with verification result, hash comparisons
- **Artifacts:** ReproducibilityVerified event, reproducibility evidence
- **Failure Conditions:** Any hash mismatch, any statistical deviation
- **Replay:** Reproducibility verification must itself be reproducible

## Stage 10 — Knowledge Integration

- **Input:** All prior stage outputs
- **Process:** Integrate results into knowledge: update theories, refine models, update confidence, record evidence
- **Output:** KnowledgeIntegrationRecord with knowledge updates, theory changes, confidence adjustments
- **Artifacts:** KnowledgeIntegrated event, integration evidence
- **Failure Conditions:** Integration produces inconsistent knowledge state
- **Replay:** Integration must produce identical knowledge updates

## Stage 11 — Archaeology Recording

- **Input:** Complete artifact set
- **Process:** Record complete experiment archaeology: answers to all archaeological questions, evidence chain, lineage
- **Output:** ExperimentArchaeologyRecord with complete lineage, archaeology_root
- **Artifacts:** ArchaeologyRecorded event, archaeology evidence
- **Failure Conditions:** Incomplete artifact set, archaeology_root mismatch
- **Replay:** Archaeology must reproduce identical roots

## Stage 12 — Freeze

- **Input:** Complete artifact set, archaeology record
- **Process:** Freeze experiment as immutable constitutional artifact
- **Output:** ExperimentFreezeRecord with final fingerprint, archive reference
- **Artifacts:** ExperimentFrozen event, freeze evidence
- **Failure Conditions:** Incomplete artifacts, verification failure
- **Replay:** Freeze must produce identical final fingerprint
