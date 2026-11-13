#!/usr/bin/env python3
"""TCP-002.5 — evidence manifest generator.

Writes:
    certification/evidence/tcp002_5/TCP_002_5_EVIDENCE_MANIFEST.json
    certification/tcp/TCP_002_5_EVIDENCE_MANIFEST.json

Usage:
    python tools/tcp/tcp0025_evidence_manifest.py
"""

import hashlib
import json
import os
import subprocess
from datetime import datetime, timezone

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
TCP = os.path.join(ROOT, "certification", "tcp")
EVID = os.path.join(ROOT, "certification", "evidence", "tcp002_5")

ARTIFACTS = [
    "certification/tcp/TCP_002_5_IMPLEMENTATION_REPORT.md",
    "certification/tcp/TCP_002_5_EVIDENCE_MANIFEST.json",
    "certification/tcp/TCP_002_4_IMPLEMENTATION_REPORT.md",
    "certification/tcp/TCP-002_EXECUTION_SPINE.md",
    "certification/tcp/TCP-001_MASTER_COMPLETION_ASSESSMENT.md",
    "certification/tcp/TCP-001_PROGRAMME_CHARTER.md",
    "certification/tcp/TCP-001_COMPLETION_REGISTER.csv",
    "certification/tcp/TCP_002_3_EFDI_CONTRACT_AUDIT.md",
]

CHANGED = [
    "lib/tiannara/executive/event_store.ex",
    "lib/tiannara/executive/event.ex",
    "lib/tiannara/forecasting/integrity.ex",
    "lib/tiannara/forecasting/contracts.ex",
    "lib/tiannara/forecasting/forecast.ex",
    "lib/tiannara/forecasting/forecast_engine.ex",
    "lib/tiannara/forecasting/forecast_registry.ex",
    "lib/tiannara/forecasting/bridge.ex",
    "lib/tiannara/research/forecasting.ex",
    "test/tiannara/forecasting/event_store_integrity_test.exs",
    "test/tiannara/forecasting/horizon_contract_test.exs",
    "test/tiannara/forecasting/bridge_test.exs",
    "test/tiannara/research/research_forecasting_integration_test.exs",
]


def git(*args):
    try:
        return subprocess.check_output(["git", "-C", ROOT] + list(args), text=True).strip()
    except Exception:
        return ""


def sha256(path):
    p = os.path.join(ROOT, path)
    if not os.path.exists(p):
        return None
    h = hashlib.sha256()
    with open(p, "rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def main():
    os.makedirs(EVID, exist_ok=True)

    manifest = {
        "checkpoint": "TCP-002.5",
        "title": "Outcome Integrity, Independent Verification, and Durable Forecast Resolution",
        "workstream": "W0 - Activate Existing Capabilities",
        "repository": "Kimiti4/Tiannara",
        "branch": git("rev-parse", "--abbrev-ref", "HEAD"),
        "baseline_commit": "367036321659f91562c469ba3f36fe0c3b5142b4",
        "commit": git("rev-parse", "HEAD"),
        "parent_commit": git("rev-parse", "HEAD~1"),
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "toolchain": {"elixir": "1.18.4", "otp": "28", "erts": "16.4"},
        "status": "PARTIAL",
        "disposition": "IMPLEMENTED_WITH_PARTIAL_EVIDENCE / VERIFICATION_BLOCKED",
        "canonical_forecasting_authority": "Tiannara.Forecasting (EFDI)",
        "stages": {
            "0_baseline": "PASS",
            "1_event_ordering": "PASS",
            "2_record_integrity": "PARTIAL",
            "3_typed_horizon": "PARTIAL",
            "4_observation_binding": "OPEN",
            "5_real_source_acquisition": "BLOCKED",
            "6_independent_verification": "OPEN",
            "7_temporal_resolution": "OPEN",
            "8_durable_outcome": "OPEN",
            "9_scoring": "PASS (implementation only; no eligible resolved forecast exists)",
            "10_calibration_readiness": "OPEN",
            "11_spine_transport": "PARTIAL",
            "12_end_to_end": "PARTIAL",
            "13_evidence_register": "PASS",
        },
        "lifecycle_state_proven": "FORECAST_REGISTERED",
        "lifecycle_states_not_proven": [
            "OBSERVATION_ACQUIRED", "OUTCOME_VERIFIED", "OUTCOME_RESOLVED",
            "FORECAST_SCORED", "CALIBRATION_ASSESSED",
        ],
        "changed_paths": CHANGED,
        "artifacts": [],
        "test_commands": [
            {
                "suite": "application: test/tiannara/forecasting + test/tiannara/research",
                "command": "MIX_ENV=test mix test test/tiannara/forecasting test/tiannara/research --seed 0 --no-deps-check",
                "cwd": ".",
                "tests": 491,
                "failures": 0,
                "seeds": [0, 123456],
            },
            {
                "suite": "event store integrity and ordering (new)",
                "command": "MIX_ENV=test mix test test/tiannara/forecasting/event_store_integrity_test.exs --seed 0 --no-deps-check",
                "cwd": ".",
                "tests": 11,
                "failures": 0,
                "seeds": [0, 123456],
            },
            {
                "suite": "typed horizon and canonical scoring vectors (new)",
                "command": "MIX_ENV=test mix test test/tiannara/forecasting/horizon_contract_test.exs --seed 0 --no-deps-check",
                "cwd": ".",
                "tests": 23,
                "failures": 0,
                "seeds": [0, 123456],
            },
            {
                "suite": "runtime regression",
                "command": "MIX_ENV=test mix test test/simulation test/runtime_layers test/kernel test/cognitive test/world_model --seed 0 --no-deps-check",
                "cwd": "tiannara_runtime",
                "tests": 792,
                "properties": 32,
                "failures": 0,
                "seeds": [0, 123456],
            },
        ],
        "not_executed": [
            "NATS transport: no NATS server is available in this environment. It is compiled; its absent-authority behaviour is covered by the refusing default. No mocked transport evidence is reported as real transport execution.",
            "Outcome acquisition, independent verification, outcome resolution, scoring of a resolved forecast, and calibration readiness: no eligible resolved forecast exists.",
        ],
        "known_limitations": [
            "Record integrity is established; record authenticity is NOT. The digest chain has no trusted anchor outside the log's storage boundary, so a wholesale log replacement with recomputed digests would not be detected.",
            "The typed horizon is validated, persisted and immutable, but the canonical resolution path does not yet read it, so enforcement at resolution is not proven (TCP-B-059 partial).",
            "The durable log supports a single writer only (TCP-B-062).",
            "The forecast lifecycle's temporal guard (Outcome) and the decision firewall (TemporalFirewall) are separate mechanisms and neither is exercised by a live resolution (TCP-B-063).",
            "Hypothesis confidence (0.5) and per-domain eig_score constants remain heuristics presented as measurements (TCP-B-056).",
            "D6 institutional forecasting memory remains deferred.",
        ],
        "open_blockers": [
            "TCP-B-046", "TCP-B-048", "TCP-B-056", "TCP-B-059", "TCP-B-060",
            "TCP-B-061", "TCP-B-062", "TCP-B-063",
        ],
        "unresolved_findings": {
            "RL-565": "HIGH / OPEN",
            "RL-564": "OPEN",
            "F-ARC-018": "OPEN",
        },
        "governance": {
            "model_update_gate": "unchanged; authority: :none, production_mutation: :forbidden, human_review_required: true",
            "human_review_controls": "intact",
            "production_mutation": False,
            "deployment_or_registry_promotion": False,
            "physical_actuation": False,
        },
        "independent_verification": {
            "performed": False,
            "reason": "no independent verifier was available for this checkpoint",
        },
        "closure_claimed": False,
    }

    artifacts = []
    for a in ARTIFACTS:
        d = sha256(a)
        if d:
            artifacts.append({"path": a, "sha256": d})
    manifest["artifacts"] = artifacts

    body = json.dumps(manifest, indent=2, ensure_ascii=False) + "\n"

    with open(os.path.join(EVID, "TCP_002_5_EVIDENCE_MANIFEST.json"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write(body)
    with open(os.path.join(TCP, "TCP_002_5_EVIDENCE_MANIFEST.json"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write(body)

    print("wrote certification/evidence/tcp002_5/TCP_002_5_EVIDENCE_MANIFEST.json")
    print("wrote certification/tcp/TCP_002_5_EVIDENCE_MANIFEST.json")
    print("artifacts with digests:", len(artifacts))
    print("commit:", manifest["commit"])


if __name__ == "__main__":
    main()
