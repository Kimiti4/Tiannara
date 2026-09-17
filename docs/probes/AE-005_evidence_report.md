# AE-005 Evidence Report — Epistemic Grounding Remediation (F10)

Date: 2026-08-21T02:42:16.574428+00:00

## 1. Authorization
- Mission: `ASC-AE-005` — Ground the CollapsePredictor in actual observed telemetry. If sufficient  evidence cannot be established to derive a risk score, quarantine the  capability to return explicit UNKNOWN/UNASSESSED rather than authoritative-looking  random probabilities.

- Status: `AUTHORIZED`; operator `schtickman`; signature `f9/f12/f10`; valid until `2026-09-04T02:00Z`
- Rule: `This authorization permits ISOLATED EXPERIMENTATION only.  If a candidate passes Phase C, it must generate an EVIDENCE REPORT. Merging to production requires a SEPARATE C14 authorization artifact  (ASC-AE-005-ADOPTION.human.yaml).
`

## 2. Phase A — Telemetry Mapping (baseline)
- `CollapsePredictor.assess_risk(:reality_graph)` 100x -> `100 unique risks`, variance `0.29928224926921504`, is_random=`True`
- Samples: [0.1893507395010103, 0.0035270974098312257, 0.24167919439750893, 0.14306830117417718, 0.06701665024665787]
- Missing telemetry behavior: `{'ok': {'collapse_risk': 0.07106863650322431, 'subsystem': 'nil', 'timestamp': {'calendar': 'Elixir.Calendar.ISO', 'day': 21, 'hour': 2, 'microsecond': [614000, 6], 'minute': 42, 'month': 8, 'second': 8, 'std_offset': 0, 'time_zone': 'Etc/UTC', 'utc_offset': 0, 'year': 2026, 'zone_abbr': 'UTC'}}}` — still returns random float (invents probability, violates Bounded Uncertainty)
- Conclusion: predictor is ungrounded stochastic generator, not telemetry-derived

## 3. Phase B — Candidate (grounded + quarantine)
- Patch: `lib/tiannara/cis/supervisor.ex` CollapsePredictor replaced via Code.compile_string (isolated)
- New API: `assess_risk(map)` -> grounded deterministic; `assess_risk(nil)` -> unknown quarantine

## 4. Phase C — Epistemic Verification
### T1 Determinism (100x same input -> identical): **PASS**
```json
{
  "pass": true,
  "scores": [
    0.05,
    0.05,
    0.05
  ]
}
```

### T2 Sensitivity (degraded telemetry -> higher risk + provenance): **PASS**
```json
{
  "degraded_factors": [
    [
      "executive_memory_health",
      "unhealthy",
      [
        [
          "weight",
          0.35
        ]
      ]
    ],
    [
      "event_store_healthy",
      false,
      [
        [
          "weight",
          0.35
        ]
      ]
    ],
    [
      "event_bus_health",
      "unhealthy",
      [
        [
          "weight",
          0.15
        ]
      ]
    ],
    [
      "memory_pressure",
      0.95,
      [
        [
          "weight",
          0.22499999999999987
        ]
      ]
    ],
    [
      "dets_health",
      false,
      [
        [
          "weight",
          0.25
        ]
      ]
    ]
  ],
  "degraded_score": 1.0,
  "healthy_score": 0.05,
  "pass": true
}
```

### T3 Grounding (structured map with provenance): **PASS**
```json
{
  "pass": true,
  "result": {
    "collapse_risk": 0.05,
    "contributing_factors": [],
    "evidence_count": 5,
    "risk_score": 0.05,
    "subsystem": "telemetry_map",
    "timestamp": {
      "calendar": "Elixir.Calendar.ISO",
      "day": 21,
      "hour": 2,
      "microsecond": [
        516000,
        6
      ],
      "minute": 42,
      "month": 8,
      "second": 16,
      "std_offset": 0,
      "time_zone": "Etc/UTC",
      "utc_offset": 0,
      "year": 2026,
      "zone_abbr": "UTC"
    }
  }
}
```

### T4 Bounded Uncertainty (missing -> UNKNOWN): **PASS**
```json
{
  "pass": true,
  "r_missing": [
    "unknown",
    "insufficient_evidence",
    [
      [
        "missing_fields",
        [
          "executive_memory_health",
          "event_bus_health"
        ]
      ]
    ]
  ],
  "r_nil": [
    "unknown",
    "insufficient_evidence",
    [
      [
        "missing_fields",
        [
          "telemetry"
        ]
      ]
    ]
  ],
  "r_stale": [
    "unknown",
    "insufficient_evidence",
    [
      [
        "missing_fields",
        [
          "executive_memory_health"
        ]
      ]
    ]
  ]
}
```

**Verdict:** candidate_grounding_fix PASSES all 4 epistemic tests

## 5. Causal Conclusion
- Determinism: same telemetry -> identical risk_score (no :rand)
- Sensitivity: healthy 0.05 -> degraded 1.0 with 5 contributing_factors traceable to memory_pressure/dets_health
- Grounding: returns %{risk_score, evidence_count, contributing_factors, subsystem, timestamp}
- Bounded Uncertainty: missing/nil/stale -> {:unknown, :insufficient_evidence, missing_fields: [...]} (never invents 0.249)

## 6. Adoption Status
- **NOT EXECUTED (requires ASC-AE-005-ADOPTION.human.yaml)**
- No production file mutated (in-memory only).