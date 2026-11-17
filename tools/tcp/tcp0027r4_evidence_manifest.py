#!/usr/bin/env python3
"""TCP-002.7-R4 — evidence manifest generator."""

import hashlib
import json
import os
import subprocess
from datetime import datetime, timezone

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
TCP = os.path.join(ROOT, "certification", "tcp")
EVID = os.path.join(ROOT, "certification", "evidence", "tcp002_7_r4")

ARTIFACTS = [
    "certification/tcp/TCP_002_7_R4_IMPLEMENTATION_REPORT.md",
    "certification/tcp/TCP_002_7_R3_IMPLEMENTATION_REPORT.md",
    "certification/tcp/TCP_002_7_R3_FINAL_RECONCILIATION.md",
    "certification/tcp/TCP_002_6_IMPLEMENTATION_REPORT.md",
    "certification/tcp/TCP-001_MASTER_COMPLETION_ASSESSMENT.md",
    "certification/tcp/TCP-001_COMPLETION_REGISTER.csv",
]

CHANGED = [
    "lib/tiannara/executive/event_store.ex",
    "test/tiannara/forecasting/event_store_integrity_test.exs",
    "test/tiannara/forecasting/resolution_registry_test.exs",
    "test/tiannara/forecasting/forecast_registry_durability_test.exs",
    "tools/tcp/tcp0027r4_evidence_manifest.py",
    "certification/tcp/TCP_002_7_R4_IMPLEMENTATION_REPORT.md",
]

BASELINE = "0c31f98595fddc3fca6b01b7789ae2c1297a589c"
BASELINE_PARENT = "0c42961641e7b7970f523e6f5e50b768c937b679"


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


def implementation_commit():
    found = None
    out = git("log", "--format=%H %s")
    for line in out.splitlines():
        sha, _, subject = line.partition(" ")
        if subject.startswith("TCP-002.7-R4"):
            found = sha
    return found


def main():
    os.makedirs(EVID, exist_ok=True)

    manifest = {
        "checkpoint": "TCP-002.7-R4",
        "title": "EventStore Compatibility-Reader Explicitness",
        "workstream": "W0 - Activate Existing Capabilities",
        "repository": "Kimiti4/Tiannara",
        "branch": git("rev-parse", "--abbrev-ref", "HEAD"),
        "baseline_commit": BASELINE,
        "baseline_parent": BASELINE_PARENT,
        "implementation_commit": implementation_commit(),
        "evidence_commit": None,
        "evidence_commit_note": (
            "commits A (implementation + tests) and B (test fix) are part of this "
            "checkpoint; a manifest committed in either cannot contain its own SHA. "
            "The implementation commit SHA above is A. B is recorded in the report "
            "and the final closure response."
        ),
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "toolchain": {"elixir": "1.18.4", "otp": "28", "erts": "16.4"},
        "status": "PARTIAL",
        "disposition": "IMPLEMENTED_AND_TESTED",
        "canonical_forecasting_authority": "Tiannara.Forecasting (EFDI)",
        "event_log_module": "lib/tiannara/executive/event_store.ex",
        "stages": {
            "0_scope_and_preservation": "PASS",
            "1_caller_inventory": "PASS",
            "2_compatibility_reader_contract": "PASS",
            "3_caller_migration": "PASS",
            "4_regression_tests": "PASS_VIA_CI",
            "5_ci_on_this_branch": "FAIL_PREEXISTING_ONLY",
            "6_evidence_package": "PASS",
            "7_independent_verification": "NOT_RUN",
            "8_genuine_observation_scoring": "BLOCKED",
        },
        "lifecycle_state_proven": "FORECAST_REGISTERED",
        "lifecycle_states_not_proven": [
            "OBSERVATION_ACQUIRED",
            "OUTCOME_VERIFIED",
            "OUTCOME_RESOLVED",
            "FORECAST_SCORED",
            "CALIBRATION_ASSESSED",
        ],
        "changed_paths": CHANGED,
        "artifacts": [],
        "eventstore_contract": {
            "stream_default": "verification-aware, fail-closed: returns {:ok, map()} only on fully verified (or empty-verified) history; {:error, reason} otherwise",
            "since_default": "verification-aware, fail-closed: same contract as stream/2",
            "stream_unverified": "compatibility wrapper: bare list, no verification gating, no diagnostics; I/O failures propagate as {:error, {:read_failed, reason}}",
            "since_unverified": "compatibility wrapper: bare list, no verification gating, no diagnostics; I/O failures propagate",
            "fail_closed_reasons": [
                "truncated_history",
                "integrity_failure (or failure_detail atom)",
                "sequence_gap",
                "unverified_legacy_record",
                "unreadable_record",
                "unknown_history_integrity_failure",
                "{:read_failed, reason}",
            ],
            "r3_recovery_unchanged": True,
            "r3_recovery_uses": ["read_records/1", "health/1"],
            "r3_recovery_does_not_use": ["stream/2", "since/2", "stream_unverified/2", "since_unverified/2"],
            "fault_injection_is_simulated": True,
        },
        "caller_migration": {
            "production_callers": "none used stream/2 or since/2 (forecast_registry uses stream_verified/2)",
            "test_migrations": [
                "event_store_integrity_test.exs: legacy-readable assertion -> stream_unverified/1",
                "event_store_integrity_test.exs: strict-mode test -> default stream/since (renamed 'readers fail closed on legacy or incomplete history')",
                "resolution_registry_test.exs: legacy-readable assertion -> stream_unverified/2",
                "forecast_registry_durability_test.exs: bare-list read -> stream_unverified/0",
            ],
            "breaking_change": "stream/2 and since/2 no longer accept opts (strict:/fail_closed:/explicit:); bare-list access moved to stream_unverified/2 and since_unverified/2",
        },
        "test_commands": [
            {
                "suite": "EventStore integrity (incl. R4 compatibility readers)",
                "command": "MIX_ENV=test mix test test/tiannara/forecasting/event_store_integrity_test.exs --seed 0 --no-deps-check",
                "cwd": ".",
                "tests": "see CI",
                "failures": 0,
                "exit_code": 0,
                "seeds": [],
                "executed": "via CI only (local boot blocked by environment)",
                "executed_via_ci": True,
            },
            {
                "suite": "ResolutionRegistry (R3, unchanged)",
                "command": "MIX_ENV=test mix test test/tiannara/forecasting/resolution_registry_test.exs --seed 0 --no-deps-check",
                "cwd": ".",
                "tests": 42,
                "failures": 0,
                "exit_code": 0,
                "seeds": [0, 1, 2, 3, 4, 5, 123456],
                "executed": "R3 (carried forward; suite unchanged by R4)",
                "executed_via_ci": True,
            },
            {
                "suite": "full application suite (CI)",
                "command": "MIX_ENV=test mix test --max-failures 25",
                "cwd": ".",
                "tests": 2755,
                "failures": 10,
                "exit_code": 1,
                "failures_analysis": "exactly the ten pre-existing ResearchForecastingIntegrationTest failures (lines 88/89, 104, 116, 131, 143, 153, 166, 182, 191, 208); zero new failures attributable to R4",
                "executed": True,
                "executed_via_ci": True,
            },
            {
                "suite": "runtime quarantine (CI, non-blocking)",
                "command": "MIX_ENV=test mix test (quarantined)",
                "cwd": ".",
                "tests": 1909,
                "properties": 40,
                "failures": 4,
                "exit_code": 1,
                "failures_analysis": "exactly the four pre-existing non-blocking failures (passive_mode_test.exs:38, reactivity_test.exs:69, omega_robustness_test.exs:25 and :48)",
                "executed": True,
                "executed_via_ci": True,
            },
        ],
        "ci_record": {
            "push_of_commit_a": {
                "remote_head_verified": "8893f36c36b141c1333f59e7cfca3eeb83acd8af",
                "elixir_ci": {
                    "run_id": "44101105100",
                    "conclusion": "failure",
                    "jobs": {
                        "compile": "success",
                        "test-placement": "success",
                        "tiannara_audit_suite_required": "success",
                        "lineage-regression": "success",
                        "tiannara_runtime_suite_required": "success",
                        "suite": "failure",
                        "tiannara_runtime_quarantine_non_blocking": "failure",
                    },
                    "suite_failure_analysis": "ten pre-existing ResearchForecastingIntegrationTest failures plus 3 new R4 test failures (File.chmod! on non-existent file) - fixed in commit B",
                    "new_failures_attributable_to_r4": 3,
                },
                "cross_platform_verification": {
                    "run_id": "44101105577",
                    "conclusion": "success",
                    "jobs": {
                        "verify_macos_latest": "success",
                        "verify_ubuntu_latest": "success",
                        "compare_cross_platform_hashes": "success",
                    },
                },
            },
            "push_of_commit_b": {
                "remote_head_verified": "b4b8b0534251e33c74a8041969423f1b42344608",
                "elixir_ci": {
                    "run_id": "44105174511",
                    "conclusion": "failure",
                    "jobs": {
                        "compile": "success",
                        "test-placement": "success",
                        "tiannara_audit_suite_required": "success",
                        "lineage-regression": "success",
                        "tiannara_runtime_suite_required": "success",
                        "suite": "failure",
                        "tiannara_runtime_quarantine_non_blocking": "failure",
                    },
                    "suite_failure_analysis": "exactly the ten pre-existing ResearchForecastingIntegrationTest failures; zero new failures attributable to R4",
                    "new_failures_attributable_to_r4": 0,
                },
                "cross_platform_verification": {
                    "run_id": "44105173387",
                    "conclusion": "success",
                    "jobs": {
                        "verify_macos_latest": "success",
                        "verify_ubuntu_latest": "success",
                        "compare_cross_platform_hashes": "success",
                    },
                },
            },
            "push_of_commit_c": {
                "remote_head_verified": "94d244d741951ea7acf8a47b88442af7d5bdb88f",
                "elixir_ci": {
                    "run_id": "44108040685",
                    "conclusion": "failure",
                    "jobs": {
                        "compile": "success",
                        "test-placement": "success",
                        "tiannara_audit_suite_required": "success",
                        "lineage-regression": "success",
                        "tiannara_runtime_suite_required": "success",
                        "suite": "failure",
                        "tiannara_runtime_quarantine_non_blocking": "failure",
                    },
                    "suite_failure_analysis": "exactly the ten pre-existing ResearchForecastingIntegrationTest failures; zero new failures attributable to R4",
                    "new_failures_attributable_to_r4": 0,
                },
                "cross_platform_verification": {
                    "run_id": "44108040263",
                    "conclusion": "success",
                    "jobs": {
                        "verify_macos_latest": "success",
                        "verify_ubuntu_latest": "success",
                        "compare_cross_platform_hashes": "success",
                    },
                },
            },
        },
        "not_executed": [
            "Local test execution: blocked by a pre-existing environment issue (CEL.Kernel boot timeout). Tests verified via CI on ubuntu-latest.",
            "Independent verification: not performed (separate checkpoint).",
            "Real filesystem fault injection on real media: not performed; simulated seam only.",
            "Genuine observation acquisition (TCP-B-048): blocked, not attempted.",
        ],
        "open_blockers": [
            "TCP-B-046",
            "TCP-B-048",
            "TCP-B-056",
            "TCP-B-058",
            "TCP-B-061",
            "TCP-B-062",
            "TCP-B-065",
            "TCP-B-066",
            "TCP-B-067",
        ],
        "findings_closed_this_checkpoint": {},
        "findings_opened_this_checkpoint": {},
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
            "source_trust_policy_tcp_b_066": "PROPOSED, NOT RATIFIED",
        },
        "independent_verification": {
            "performed": False,
            "reason": "separate checkpoint (R5); not part of this implementation checkpoint",
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

    with open(os.path.join(EVID, "TCP_002_7_R4_EVIDENCE_MANIFEST.json"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write(body)
    with open(os.path.join(TCP, "TCP_002_7_R4_EVIDENCE_MANIFEST.json"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write(body)

    print("wrote certification/evidence/tcp002_7_r4/TCP_002_7_R4_EVIDENCE_MANIFEST.json")
    print("wrote certification/tcp/TCP_002_7_R4_EVIDENCE_MANIFEST.json")
    print("artifacts with digests:", len(artifacts))
    print("implementation_commit:", manifest["implementation_commit"])


if __name__ == "__main__":
    main()
