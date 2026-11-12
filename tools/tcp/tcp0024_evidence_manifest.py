#!/usr/bin/env python3
"""TCP-002.4 — evidence manifest generator.

Produces:
    certification/evidence/tcp002_4/TCP_002_4_EVIDENCE_MANIFEST.json
    certification/tcp/TCP_002_4_EVIDENCE_MANIFEST.json

Usage:
    python tools/tcp/tcp0024_evidence_manifest.py
"""

import hashlib
import json
import os
import subprocess
from datetime import datetime, timezone

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
TCP = os.path.join(ROOT, "certification", "tcp")
EVID = os.path.join(ROOT, "certification", "evidence", "tcp002_4")

ARTIFACTS = [
    "certification/tcp/TCP_002_4_BASELINE_AND_INTEGRATION.md",
    "certification/tcp/TCP_002_4_IMPLEMENTATION_REPORT.md",
    "certification/tcp/TCP_002_4_EVIDENCE_MANIFEST.json",
    "certification/tcp/TCP-002_EXECUTION_SPINE.md",
    "certification/tcp/TCP-002_ACTIVATION_MAP.md",
    "certification/tcp/TCP_001_MASTER_COMPLETION_ASSESSMENT.md",
    "certification/tcp/TCP-001_PROGRAMME_CHARTER.md",
    "certification/tcp/TCP-001_COMPLETION_REGISTER.csv",
    "certification/tcp/TCP_002_3_IMPLEMENTATION_REPORT.md",
    "certification/tcp/TCP_002_3_EFDI_CONTRACT_AUDIT.md",
    "certification/tcp/TCP_002_3_SOURCE_AND_CALLER_INVENTORY.md",
]

CHANGED = [
    "lib/tiannara/research/forecasting.ex",
    "lib/tiannara/research/research_director.ex",
    "lib/tiannara/research/hypothesis_ranker.ex",
    "lib/tiannara/forecasting/adapters/research_impl.ex",
    "lib/tiannara/forecasting/bridge.ex",
    "lib/tiannara/forecasting/forecast_registry.ex",
    "lib/tiannara/executive/event_store.ex",
    "lib/tiannara/executive/event.ex",
    "test/tiannara/research/research_forecasting_integration_test.exs",
    "test/tiannara/forecasting/forecast_registry_durability_test.exs",
    "test/tiannara/forecasting/d2_integration_test.exs",
    "test/tiannara/forecasting/forecast_adversarial_test.exs",
    "test/tiannara/forecasting/forecast_registry_test.exs",
    "test/tiannara/forecasting/forecast_replay_test.exs",
    "test/tiannara/forecasting/d5/d5_integration_test.exs",
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
        "checkpoint": "TCP-002.4",
        "title": "Research-to-Forecast Operational Closure, Independent Outcome Acquisition, and Durable Evidence Lifecycle",
        "workstream": "W0 - Activate Existing Capabilities",
        "repository": "Kimiti4/Tiannara",
        "branch": git("rev-parse", "--abbrev-ref", "HEAD"),
        "starting_commit": "4e24f3277ec3f0f40da8d7846b14a63b9ffb9a6d",
        "commit": git("rev-parse", "HEAD"),
        "parent_commit": git("rev-parse", "HEAD~1"),
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "toolchain": {"elixir": "1.18.4", "otp": "28", "erts": "16.4"},
        "status": "PARTIAL",
        "disposition": "IMPLEMENTED_WITH_PARTIAL_EVIDENCE / VERIFICATION_BLOCKED",
        "canonical_forecasting_authority": "Tiannara.Forecasting (EFDI)",
        "stages": {
            "0_baseline": "PASS",
            "1_lifecycle_contract": "PASS",
            "2_research_director_to_efdi": "PASS",
            "3_durable_registry_adversarial": "PASS",
            "4_outcome_acquisition": "BLOCKED",
            "5_independent_resolution": "OPEN",
            "6_forecast_scoring": "OPEN",
            "7_calibration_readiness": "OPEN",
            "8_governed_model_update": "OPEN",
            "9_spine_integration": "PARTIAL",
            "10_end_to_end_demonstration": "PARTIAL",
            "11_test_programme": "PASS",
            "12_observability": "OPEN",
            "13_register_reconciliation": "PASS",
        },
        "changed_paths": CHANGED,
        "artifacts": [],
        "test_commands": [
            {
                "suite": "application: test/tiannara/forecasting",
                "command": "MIX_ENV=test mix test test/tiannara/forecasting --seed 0 --no-deps-check",
                "cwd": ".",
                "tests": 428,
                "failures": 0,
                "seeds": [0, 123456],
            },
            {
                "suite": "research -> EFDI integration",
                "command": "MIX_ENV=test mix test test/tiannara/research/research_forecasting_integration_test.exs --seed 0 --no-deps-check",
                "cwd": ".",
                "tests": 10,
                "failures": 0,
                "seeds": [0, 123456],
            },
            {
                "suite": "registry durability (adversarial)",
                "command": "MIX_ENV=test mix test test/tiannara/forecasting/forecast_registry_durability_test.exs --seed 0 --no-deps-check",
                "cwd": ".",
                "tests": 14,
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
            "NATS transport: no NATS server is available in this environment; the refusing default covers the absent-authority path.",
            "Outcome acquisition, independent resolution, forecast scoring and calibration: no real observed outcome exists to resolve, score or aggregate.",
            "End-to-end operational demonstration: the research-to-forecast-to-durable-registration half is demonstrated; the observation half is not.",
        ],
        "known_limitations": [
            "Hypothesis confidence (0.5) and eig_score (per-domain constants) are heuristics presented as measurements (TCP-B-056).",
            "The durable log carries no per-record sequence number, so reordering cannot be detected (TCP-B-057).",
            "No integrity digest covers the durable forecast record (TCP-B-058).",
            "A forecast horizon is free text and cannot be enforced at resolution (TCP-B-059).",
            "No observation contract links an acquired outcome to a forecast's declared outcome definition (TCP-B-060).",
            "The correlation between the runtime Spine and the Research Director is not yet established; both reach canonical EFDI, but not as one invocation.",
            "D6 institutional forecasting memory remains deferred.",
        ],
        "open_blockers": [
            "TCP-B-046", "TCP-B-048", "TCP-B-051", "TCP-B-052",
            "TCP-B-056", "TCP-B-057", "TCP-B-058", "TCP-B-059", "TCP-B-060",
        ],
        "unresolved_findings": {
            "RL-565": "HIGH / OPEN",
            "RL-564": "OPEN",
            "F-ARC-018": "OPEN",
        },
        "independent_verification": {
            "performed": False,
            "reason": "no independent verifier was available for this checkpoint",
        },
        "closure_claimed": False,
        "prohibited_actions_performed": [],
    }

    artifacts = []
    for a in ARTIFACTS:
        d = sha256(a)
        if d:
            artifacts.append({"path": a, "sha256": d})
    manifest["artifacts"] = artifacts

    body = json.dumps(manifest, indent=2, ensure_ascii=False) + "\n"

    with open(os.path.join(EVID, "TCP_002_4_EVIDENCE_MANIFEST.json"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write(body)
    with open(os.path.join(TCP, "TCP_002_4_EVIDENCE_MANIFEST.json"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write(body)

    print("wrote certification/evidence/tcp002_4/TCP_002_4_EVIDENCE_MANIFEST.json")
    print("wrote certification/tcp/TCP_002_4_EVIDENCE_MANIFEST.json")
    print("artifacts with digests:", len(artifacts))
    print("commit:", manifest["commit"])


if __name__ == "__main__":
    main()
