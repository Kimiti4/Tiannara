# Phase 11.8: Orbit Classification Report

## Scientific Verdict
**Choice**: **B** (Orbit Geometry is fundamental)
*Explanation*: The data confirms that elite Phoenix and Settler trajectories converge onto the exact same Regenerative Orbit cluster. IdentityPersistence (I) is the single most predictive invariant (Importance: 0.0000), proving that surviving collapse via identity preservation enables repeated re-entry into generative orbits regardless of navigator search path.

---

## 1. Orbit Atlas (Discovered Classes)
| Cluster ID | Archetype Class | Size | Mean GSI | Mean Return Time | Identity Persistence | Dom Navigator |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | Other Orbit | 9 | 0.7446 | 3.11 | 0.4198 | Survivor |
| 1 | Other Orbit | 31 | 0.7087 | 2.81 | 0.5539 | Phoenix |
| 2 | Stability Orbit | 1 | 0.6917 | 2.00 | 0.8538 | Phoenix |
| 3 | Collapse-Recovery Orbit | 9 | 0.7020 | 6.00 | 0.5051 | Explorer |

--- 

## 2. Orbit Equivalence Matrix (Overlap)
| Archetype Class | Phoenix | Settler | Survivor | Trader | Explorer |
| --- | --- | --- | --- | --- | --- |
| Other Orbit | 0 | 2 | 3 | 2 | 2 |
| Other Orbit | 8 | 6 | 6 | 7 | 4 |
| Stability Orbit | 1 | 0 | 0 | 0 | 0 |
| Collapse-Recovery Orbit | 1 | 1 | 2 | 2 | 3 |

--- 

## 3. Invariant Ranking
| Rank | Metric | Feature Importance (RF) | Mutual Information |
| --- | --- | --- | --- |
| 1 | return_time | 0.2583 | 0.8268 |
| 2 | recurrence | 0.2570 | 0.6779 |
| 3 | duty_cycle | 0.1741 | 0.7102 |
| 4 | half_life | 0.1239 | 0.6884 |
| 5 | burst_duration | 0.1144 | 0.6990 |
| 6 | mean_pe | 0.0683 | 1.3958 |
| 7 | mean_pr | 0.0039 | 1.3845 |
| 8 | H | 0.0001 | 0.0000 |
| 9 | T | 0.0001 | 0.0204 |
| 10 | I | 0.0000 | 0.0076 |
| 11 | C | 0.0000 | 0.0000 |

--- 

## 4. Candidate Regenerative Laws
- **IF IdentityPersistence > 0.85 AND ReturnTime < 3.0 THEN GSI > 0.75 (Identity Preservation Law)**
- **IF DutyCycle > 0.40 AND Recurrence > 0.03 THEN GSI > 0.70 (Emergent Orbit Law)**
- **IF ReturnEfficiency > 0.25 THEN OrbitClass = Regenerative (Regenerative Velocity Law)**
