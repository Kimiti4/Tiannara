# Readiness Dashboard Specification (Phase 20.98)

## Purpose

Specify a constitutional readiness dashboard that presents the CRI in a clear, actionable format. No runtime UI implementation — only dashboard specification.

## Dashboard Layout

```
+----------------------------------------------------------+
|  Constitutional Readiness Dashboard                        |
|  Overall CRI: 0.00    Level: CRI-0    Status: Assessing   |
+----------------------------------------------------------+
|  Dimension Radar          |  Domain Readiness Matrix      |
|                           |                               |
|     Constitutional        |  Engineering    0.00  ░░░░░   |
|    /              \       |  Physics         0.00  ░░░░░   |
|   /    Math        \      |  Chemistry       0.00  ░░░░░   |
|  |                    |   |  Medicine        0.00  ░░░░░   |
|  |                    |   |  ...                       |
|   \                  /    |                               |
|    \   Governance   /     |                               |
|     \______________/      |                               |
+---------------------------+-------------------------------+
|  Historical Readiness Trend |  Certification Eligibility  |
|  CRI 1.0 █                   |  CRI ≥ 0.95  Readiness dimension status          |
|        █ █                   |  Dim ≥ 0.90  Readiness dimension status          |
|       █  █  █               |  No critical  Readiness dimension status          |
|      █   █   █              |  Validation   Readiness dimension status          |
|     █    █    █             |  Audit        Readiness dimension status          |
|    █     █     █            |  Replay       Readiness dimension status          |
|   █      █      █           |  Archaeology  Readiness dimension status          |
|  20.95  20.96  20.97  20.98 |  ELIGIBLE: NO               |
+---------------------------+-------------------------------+
|  Deficiency Summary                  |  Improvement         |
|  Critical: 0    Major: 0    Minor: 0  |  Priorities         |
|  Qualitative details of the readiness assessment                          |  1. ...            |
|                                        |  2. ...            |
|                                        |  3. ...            |
+----------------------------------------+--------------------+
|  Replay Verification                   |  Archaeology        |
|  Full replay: Dashboard verification status                   |  Artifacts: Total count    |
|  All dimensions: Passing count over total count                |  Chain: Dashboard verification status   |
|  All domains: Passing count over total count                   |  Cold storage: Operational status|
+----------------------------------------+--------------------+
```

## Dashboard Elements

1. **Overall CRI** — Score, level, and status
2. **Dimension Radar** — 10-dimension radar/spider chart
3. **Domain Readiness Matrix** — 20-domain table with scores
4. **Historical Trend** — CRI progression across phases
5. **Certification Eligibility** — Binary checklist
6. **Deficiency Summary** — Counts and details
7. **Improvement Priorities** — Ranked recommendations
8. **Replay Verification** — Replay status indicators
9. **Archaeology Status** — Artifact preservation status

## Data Sources

All dashboard data comes from deterministic CRI calculations stored in cold storage. No live runtime data required. Dashboard is a static view over computed results.
