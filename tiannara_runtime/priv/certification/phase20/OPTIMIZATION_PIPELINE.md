# Phase 20.8 — Optimization Pipeline

## Overview

The Optimization Pipeline governs every optimization from observation through recommendation. All 12 stages must complete in order. No stage may be skipped.

## Stage 1 — Observation

- **Input:** Telemetry from all subsystems, runtime metrics, engineering history, experiment results, knowledge graph state, world model state
- **Process:** Collect structured metrics across all monitored dimensions
- **Output:** ObservationRecord with metric values, timestamps, subsystem references
- **Artifacts:** ObservationCollected event, metric snapshot
- **Failure Conditions:** Missing critical metrics, metric collection failure
- **Replay:** Observations must produce identical metrics for same time window

## Stage 2 — Metric Collection

- **Input:** ObservationRecord
- **Process:** Compute derived metrics, aggregate across subsystems, normalize to constitutional units, compute trends
- **Output:** MetricSet with raw and derived metrics, trend data, baseline comparisons
- **Artifacts:** MetricsCollected event, metric evidence
- **Failure Conditions:** Metric computation failure, invalid normalization
- **Replay:** Metric computation must produce identical values

## Stage 3 — Bottleneck Detection

- **Input:** MetricSet
- **Process:** Compare metrics against baselines, detect anomalies, identify degradation, trace causal chains, classify bottleneck type, assign severity
- **Output:** BottleneckReport with bottleneck_id, subsystem, severity, frequency, causal_chain, evidence_root
- **Artifacts:** BottleneckDetected event, bottleneck evidence
- **Failure Conditions:** No bottleneck detected (informational — not a failure)
- **Replay:** Bottleneck detection must produce identical reports for identical metrics

## Stage 4 — Candidate Generation

- **Input:** BottleneckReport, MetricSet, engineering history, experiment history
- **Process:** Generate optimization candidates: identify opportunity, estimate expected gain, estimate expected cost, assess risk, identify affected domains, provide mathematical justification
- **Output:** OptimizationCandidate with candidate_id, expected_gain, expected_cost, expected_risk, affected_domains
- **Artifacts:** CandidateGenerated event, candidate evidence
- **Failure Conditions:** No viable candidate (informational)
- **Replay:** Candidate generation must produce identical candidates for same inputs

## Stage 5 — Trade-off Analysis

- **Input:** OptimizationCandidate, PerformanceProfile, Multi-objective weights
- **Process:** Analyze advantages and disadvantages across all dimensions: performance, complexity, energy, memory, accuracy, maintainability, scientific impact, engineering impact, risk
- **Output:** TradeoffReport with per-dimension analysis, overall assessment, confidence
- **Artifacts:** TradeoffAnalyzed event, tradeoff evidence
- **Failure Conditions:** Analysis incomplete, undefined trade-off dimension
- **Replay:** Trade-off analysis must produce identical assessments

## Stage 6 — Simulation

- **Input:** OptimizationCandidate, TradeoffReport, current PerformanceProfile
- **Process:** Simulate optimization impact: predicted performance change, resource impact, risk profile, confidence intervals
- **Output:** SimulationReport with predicted metrics, confidence bounds, risk assessment
- **Artifacts:** SimulationCompleted event, simulation evidence
- **Failure Conditions:** Simulation fails, predictions outside bounds
- **Replay:** Simulation must produce identical predictions

## Stage 7 — Recommendation

- **Input:** TradeoffReport, SimulationReport, OptimizationCandidate
- **Process:** Rank candidate against other candidates, determine recommendation priority, assign recommendation type (engineering/experiment/evolution/research), generate recommendation document
- **Output:** OptimizationRecommendation with priority, recommendation_type, expected_impact, required_actions
- **Artifacts:** RecommendationIssued event, recommendation evidence
- **Failure Conditions:** Ranking incomplete, priority conflict
- **Replay:** Recommendation must produce identical priority and type

## Stage 8 — Experiment Request

- **Input:** OptimizationRecommendation
- **Process:** If recommendation requires experimental validation, generate ExperimentRequest for Phase 20.7
- **Output:** ExperimentRequest with hypothesis, predicted gain, variables, statistical plan
- **Artifacts:** ExperimentRequested event, experiment request evidence
- **Failure Conditions:** Request malformed, hypothesis unfalsifiable
- **Replay:** Experiment request must produce identical experiment design

## Stage 9 — Validation

- **Input:** Experiment results from Phase 20.7 (if experiment requested), or direct validation
- **Process:** Validate predicted vs actual gains, update confidence, assess whether recommendation is confirmed
- **Output:** ValidationReport with confirmation status, updated confidence, lessons learned
- **Artifacts:** ValidationCompleted event, validation evidence
- **Failure Conditions:** Validation fails, predicted gains not achieved
- **Replay:** Validation must produce identical confirmation decisions

## Stage 10 — Certification

- **Input:** ValidationReport, all prior stage outputs
- **Process:** Constitutional authority certifies optimization recommendation for integration
- **Output:** OptimizationCertificate authorizing recommendation for next steps
- **Artifacts:** CertificationIssued event, certification evidence
- **Failure Conditions:** Validation failure, constitutional violation
- **Replay:** Certification must produce identical certificate hash

## Stage 11 — Integration Request

- **Input:** OptimizationCertificate
- **Process:** Generate integration request for Phase 20.4 (if engineering change) or evolution request for Phase 20.3 (if runtime evolution)
- **Output:** IntegrationRequest with recommendation, evidence, certification
- **Artifacts:** IntegrationRequested event, integration request evidence
- **Failure Conditions:** Request type unclear, missing certification
- **Replay:** Integration request must produce identical scope

## Stage 12 — Freeze

- **Input:** Complete artifact set
- **Process:** Freeze optimization as immutable constitutional record
- **Output:** OptimizationFreezeRecord with final fingerprint, archaeology reference
- **Artifacts:** OptimizationFrozen event, freeze evidence
- **Failure Conditions:** Incomplete artifacts
- **Replay:** Freeze must produce identical final fingerprint
