#!/usr/bin/env python3
"""TCP-002.3 — evidence manifest generator.

Produces `certification/tcp/TCP_002_3_EVIDENCE_MANIFEST.json` with the
checkpoint identity, changed paths, test commands and outcomes, evidence
artefact paths, SHA-256 digests, known limitations and open blockers.

Usage:
    python tools/tcp/tcp0023_evidence_manifest.py
"""

import hashlib
import json
import os
import subprocess
import sys
from datetime import datetime, timezone

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "certification", "tcp", "TCP_002_3_EVIDENCE_MANIFEST.json")

ARTIFACTS = [
    "certification/tcp/TCP_002_3_IMPLEMENTATION_REPORT.md",
    "certification/tcp/TCP_002_3_SOURCE_AND_CALLER_INVENTORY.md",
    "certification/tcp/TCP_002_3_EFDI_CONTRACT_AUDIT.md",
    "certification/tcp/TCP_002_3_EFDI_INVENTORY.md",
    "certification/tcp/TCP_002_3_EFDI_INVENTORY.csv",
    "certification/tcp/TCP-002_EXECUTION_SPINE.md",
    "certification/tcp/TCP-002_ACTIVATION_MAP.md",
    "certification/tcp/TCP-002_ACTIVATION_MAP.csv",
    "certification/tcp/TCP-001_MASTER_COMPLETION_ASSESSMENT.md",
    "certification/tcp/TCP-001_PROGRAMME_CHARTER.md",
    "certification/tcp/TCP-001_COMPLETION_REGISTER.csv",
]

CHANGED = [
    "lib/tiannara/forecasting/bridge.ex",
    "lib/tiannara/forecasting/forecast_registry.ex",
    "lib/tiannara/forecasting/efdi.ex",
    "lib/tiannara/forecasting/adapters/research_impl.ex",
    "lib/tiannara/application.ex",
    "config/config.exs",
    "config/test.exs",
    "test/tiannara/forecasting/bridge_test.exs",
    "test/tiannara/forecasting/research_adapter_honesty_test.exs",
    "tiannara_runtime/lib/tiannara_runtime/cognitive/spine/forecasting.ex",
    "tiannara_runtime/lib/tiannara_runtime/cognitive/spine/forecasting/nats.ex",
    "tiannara_runtime/lib/tiannara_runtime/cognitive/spine/cognitive_execution_spine.ex",
    "tiannara_runtime/test/cognitive/spine/forecasting_port_test.exs",
    "tools/tcp/tcp0023_efdi_inventory.py",
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
    manifest = {
        "checkpoint": "TCP-002.3",
        "title": "EFDI Canonical Forecasting Integration, Research Connectivity and Institutional Calibration",
        "workstream": "W0 — Activate Existing Capabilities",
        "repository": "Kimiti4/Tiannara",
        "branch": git("rev-parse", "--abbrev-ref", "HEAD"),
        "commit": git("rev-parse", "HEAD"),
        "parent_commit": git("rev-parse", "HEAD~1"),
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "toolchain": {"elixir": "1.18.4", "otp": "28", "erts": "16.4"},
        "status": "PARTIAL",
        "disposition": "IMPLEMENTED_WITH_PARTIAL_EVIDENCE / VERIFICATION_BLOCKED",
        "canonical_forecasting_authority": "Tiannara.Forecasting (EFDI)",
        "stages_delivered": ["0", "1", "2", "3.1", "5 (partial)", "10 (partial)", "11 (partial)"],
        "stages_open": ["3.2-3.4", "4", "6", "7", "8", "9", "12"],
        "changed_paths": CHANGED,
        "artifacts": [],
        "test_commands": [
            {
                "suite": "application: test/tiannara/forecasting",
                "command": "MIX_ENV=test mix test test/tiannara/forecasting --seed 0 --no-deps-check",
                "cwd": ".",
                "tests": 414,
                "failures": 0,
                "seeds": [0, 123456],
            },
            {
                "suite": "runtime: test/{simulation,runtime_layers,kernel,cognitive,world_model}",
                "command": "MIX_ENV=test mix test test/simulation test/runtime_layers test/kernel test/cognitive test/world_model --seed 0 --no-deps-check",
                "cwd": "tiannara_runtime",
                "tests": 792,
                "properties": 32,
                "failures": 0,
                "seeds": [0, 123456],
            },
        ],
        "known_limitations": [
            "The NATS transport is compiled but not executed: no NATS server is available in this environment. The refusing default covers the absent-authority behaviour instead.",
            "The application stack did not compile at the start of this checkpoint because _build held no compiled dependencies. The dependencies were restored from the CP19.20 worktree; no application-stack evidence could have been produced before that repair.",
            "No end-to-end investigation has been demonstrated: a forecast has not yet been resolved against a real observed outcome and scored.",
            "The durable registry has no adversarial persistence suite (corruption, truncation, replay, duplicate delivery, concurrent registration, partial-write recovery).",
            "D6 institutional forecasting memory is deferred; 65 of 70 EFDI modules hold no state across a restart.",
            "The application and runtime stacks cannot yet share a compile-time dependency: 28 module names are defined in both.",
        ],
        "open_blockers": [
            "TCP-B-046", "TCP-B-047", "TCP-B-048", "TCP-B-049",
            "TCP-B-050", "TCP-B-051", "TCP-B-052",
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
        digest = sha256(a)
        if digest:
            artifacts.append({"path": a, "sha256": digest})
    manifest["artifacts"] = artifacts

    with open(OUT, "w", encoding="utf-8", newline="\n") as fh:
        json.dump(manifest, fh, indent=2, ensure_ascii=False)
        fh.write("\n")

    print("wrote", OUT)
    print("artifacts with digests:", len(artifacts))
    print("commit:", manifest["commit"])


if __name__ == "__main__":
    main()
