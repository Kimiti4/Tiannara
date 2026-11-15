#!/usr/bin/env python3
"""TCP-002.7-R3 — evidence manifest generator.

Writes:
    certification/evidence/tcp002_7_r3/TCP_002_7_R3_EVIDENCE_MANIFEST.json
    certification/tcp/TCP_002_7_R3_EVIDENCE_MANIFEST.json

Usage:
    python tools/tcp/tcp0027r3_evidence_manifest.py
"""

import hashlib
import json
import os
import subprocess
from datetime import datetime, timezone

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
TCP = os.path.join(ROOT, "certification", "tcp")
EVID = os.path.join(ROOT, "certification", "evidence", "tcp002_7_r3")

ARTIFACTS = [
    "certification/tcp/TCP_002_7_R3_IMPLEMENTATION_REPORT.md",
    "certification/tcp/TCP_002_6_IMPLEMENTATION_REPORT.md",
    "certification/tcp/TCP_002_7_SOURCE_TRUST_POLICY_PROPOSAL.md",
    "certification/tcp/TCP-001_MASTER_COMPLETION_ASSESSMENT.md",
    "certification/tcp/TCP-001_COMPLETION_REGISTER.csv",
]

CHANGED = [
    "lib/tiannara/executive/event_store.ex",
    "lib/tiannara/forecasting/resolution_registry.ex",
    "test/tiannara/forecasting/resolution_registry_test.exs",
    "tools/tcp/tcp0027r3_evidence_manifest.py",
    "certification/tcp/TCP_002_7_R3_IMPLEMENTATION_REPORT.md",
    "certification/tcp/TCP_002_7_R3_FINAL_RECONCILIATION.md",
]

BASELINE = "fd7babafc42cccf7d290b6f6af59fb6a6fc63bf4"
BASELINE_PARENT = "05ee148e88d4ba066a9c3c085363eced9d0b5872"


def git(*args):
    try:
        return subprocess.check_output(["git", "-C", ROOT] + list(args), text=True).strip()
    except Exception:
        return ""


def implementation_commit():
    """Return the SHA of commit A: the OLDEST commit whose message starts with 'TCP-002.7-R3' on this branch."""
    found = None
    out = git("log", "--format=%H %s")
    for line in out.splitlines():
        sha, _, subject = line.partition(" ")
        if subject.startswith("TCP-002.7-R3"):
            found = sha
    return found


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
        "checkpoint": "TCP-002.7-R3",
        "title": (
            "EventStore Fail-Closed Recovery, Write Poisoning, and "
            "Transactional ResolutionRegistry Recovery"
        ),
        "workstream": "W0 - Activate Existing Capabilities",
        "repository": "Kimiti4/Tiannara",
        "branch": git("rev-parse", "--abbrev-ref", "HEAD"),
        "baseline_commit": BASELINE,
        "baseline_parent": BASELINE_PARENT,
        "implementation_commit": implementation_commit(),
        "evidence_commit": None,
        "evidence_commit_note": (
            "commits A (implementation), B (evidence: this manifest, register and "
            "master) and C (CI record + this manifest) are all part of the "
            "checkpoint; a manifest committed in any of them cannot contain its "
            "own SHA. The implementation commit SHA above is A. B and C are "
            "recorded in the append-only register row, master assessment section 13 "
            "and the final reconciliation after push."
        ),
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "toolchain": {"elixir": "1.18.4", "otp": "28", "erts": "16.4"},
        "status": "PARTIAL",
        "disposition": "IMPLEMENTED_WITH_PARTIAL_EVIDENCE / VERIFICATION_BLOCKED",
        "canonical_forecasting_authority": "Tiannara.Forecasting (EFDI)",
        "canonical_resolution_authority": (
            "Tiannara.Forecasting.OutcomeResolution (single production caller: "
            "lib/tiannara/forecasting/efdi.ex:116)"
        ),
        "storage_authority": (
            "lib/tiannara/forecasting/resolution_registry.ex (durable index over the "
            "EventStore log)"
        ),
        "event_log_module": "lib/tiannara/executive/event_store.ex",
        "stages": {
            "0_scope_and_preservation": "PASS",
            "1_eventstore_fail_closed_recovery": "PASS",
            "2_write_sync_poisoning": "PASS",
            "3_transactional_registry_recovery": "PASS",
            "4_duplicate_conflict_identity": "PASS",
            "5_adversarial_regression_suite": "PASS",
            "6_cross_suite_regression": "PASS",
            "7_independent_verification": "NOT_RUN",
            "8_ci_on_this_branch": "FAIL_PREEXISTING_ONLY",
            "9_genuine_observation_scoring": "BLOCKED",
            "10_evidence_register": "PASS",
        },
        "ci_record": {
            "push_of_commit_b": {
                "remote_head_verified": "96155353fa22de6cbca5650ae423977a383ce93a",
                "elixir_ci": {
                    "run_id": "43700070002",
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
                    "suite_failure_analysis": (
                        "exactly the ten pre-existing ResearchForecastingIntegrationTest "
                        "failures (research_forecasting_integration_test.exs lines 89, 104, "
                        "116, 131, 143, 153, 166, 182, 191, 208)"
                    ),
                    "quarantine_failure_analysis": (
                        "exactly the four pre-existing non-blocking failures "
                        "(passive_mode_test.exs:38, reactivity_test.exs:69, "
                        "omega_robustness_test.exs:25 and :48)"
                    ),
                    "new_failures_attributable_to_r3": 0,
                },
                "cross_platform_verification": {
                    "run_id": "43700069993",
                    "conclusion": "success",
                    "jobs": {
                        "verify_macos_latest": "success",
                        "verify_ubuntu_latest": "success",
                        "compare_cross_platform_hashes": "success",
                    },
                },
                "r3_files_in_failed_logs": (
                    "only two compile warnings in resolution_registry_test.exs (unused ctx), "
                    "renamed to _ctx in the third commit; plus pre-existing warnings for "
                    "the unrelated Tiannara.CEL.Services.EventStore module"
                ),
            },
            "push_of_commit_c": {
                "remote_head_verified": "500730e40b84cf947ff2abce66e6404e89fcd033",
                "elixir_ci": {
                    "run_id": "43702102210",
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
                    "suite_failure_analysis": (
                        "again exactly the ten pre-existing ResearchForecastingIntegrationTest "
                        "failures (same lines as commit B)"
                    ),
                    "quarantine_failure_analysis": (
                        "again exactly the four pre-existing non-blocking failures"
                    ),
                    "new_failures_attributable_to_r3": 0,
                },
                "cross_platform_verification": {
                    "run_id": "43702102197",
                    "conclusion": "success",
                    "jobs": {
                        "verify_macos_latest": "success",
                        "verify_ubuntu_latest": "success",
                        "compare_cross_platform_hashes": "success",
                    },
                },
                "r3_files_in_failed_logs": (
                    "the two resolution_registry_test.exs unused-ctx warnings are gone "
                    "(the _ctx rename is confirmed by this run); only the five pre-existing "
                    "warnings for the unrelated Tiannara.CEL.Services.EventStore module remain"
                ),
            },
            "push_of_commit_d": {
                "remote_head_verified": "df9231a73497d8303a446b31e20a2f2e22431ddd",
                "elixir_ci": {
                    "run_id": "43703627182",
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
                    "suite_failure_analysis": (
                        "again exactly the ten pre-existing ResearchForecastingIntegrationTest "
                        "failures; the first failure is logged at line 88 in this run versus 89 "
                        "in pushes B and C - a line-ending offset, the same tests, the same set"
                    ),
                    "quarantine_failure_analysis": (
                        "again exactly the four pre-existing non-blocking failures"
                    ),
                    "new_failures_attributable_to_r3": 0,
                },
                "cross_platform_verification": {
                    "run_id": "43703627228",
                    "conclusion": "success",
                    "jobs": {
                        "verify_macos_latest": "success",
                        "verify_ubuntu_latest": "success",
                        "compare_cross_platform_hashes": "success",
                    },
                },
                "r3_files_in_failed_logs": (
                    "zero R3-related lines: no resolution_registry_test.exs, no ResolutionRegistry, "
                    "no TCP_002_7_R3; only the five pre-existing warnings for the unrelated "
                    "Tiannara.CEL.Services.EventStore module"
                ),
            },
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
            "read_failure_is_never_clean_history": True,
            "integrity_states": [
                "verified",
                "empty_verified",
                "unavailable",
                "truncated",
                "integrity_failure",
                "sequence_gap",
                "legacy_unverified",
                "recovery_required",
                "poisoned",
            ],
            "append_permitted_integrities": ["verified", "empty_verified"],
            "append_gate": (
                "append requires integrity in [:verified, :empty_verified] AND a freshly "
                "re-read, fully verified history; loss of intactness returns "
                "{:error, {:store_integrity_failure, reason}} and writes nothing"
            ),
            "write_failure_semantics": (
                "any write failure poisons the store, does not advance count/sequence/"
                "digest, and never acknowledges success; subsequent appends return "
                ":store_poisoned; the store remains :poisoned until restarted and the "
                "complete history verifies"
            ),
            "sync_failure_semantics": (
                "an fsync failure poisons the store the same way; the committed frame "
                "may or may not have reached storage — durable acknowledgement was "
                "withheld and no success is reported; restart against the actual file "
                "classifies it from the bytes on disk"
            ),
            "partial_write_semantics": (
                "the fault seam writes a genuine prefix of the frame; restart against "
                "the real truncated file yields :truncated and refuses append"
            ),
            "read_failure_propagation": [
                "stream/3",
                "stream_with_diagnostics/3",
                "stream_verified/3",
                "read_records/1",
                "since/2",
                "health/1 (via state, as :unavailable with read_error)",
            ],
            "legacy_records": "readable, :unverified_legacy, never integrity-verified, block append",
            "health_has_no_durable_field": True,
            "fault_injection_is_simulated": True,
            "kill_after_write_is_a_real_process_kill": True,
        },
        "registry_contract": {
            "recovery_transaction": ["read", "build_candidate", "publish"],
            "candidate_validation": (
                "every efdi.forecast.resolved event must pass semantic validation "
                "(required fields, forecast identity, scores payload); any failure "
                "halts recovery before publication; non-resolution events are skipped"
            ),
            "publication": (
                "single ETS object {:__resolution_index__, %{forecast_id => resolution}} "
                "inserted atomically; failure yields :publication_failure and leaves no "
                "authoritative index"
            ),
            "failed_recovery_invalidates_previous_index": True,
            "prior_index_never_survives_failed_recovery": True,
            "trust_gate": (
                "get/all_ids/count/commit require a live verified EventStore "
                "(integrity in [:verified, :empty_verified], not poisoned, appendable, "
                "not degraded) plus a published registry; otherwise :registry_not_verified, "
                ":registry_degraded or :eventstore_unavailable"
            ),
            "duplicate_identical_resolution_event": "recovery fails closed, count unchanged",
            "conflicting_forecast_resolutions": "recovery fails closed, count unchanged",
            "identity_comparison_fields": [
                "forecast_id",
                "forecast_version",
                "forecast_digest",
                "outcome_definition_digest",
                "horizon_digest",
                "model_ref",
                "observation_id",
                "observation_digest",
                "evidence_digest",
                "evidence_status",
                "observed_outcome",
                "observed_at",
                "event_at",
                "published_at",
                "acquired_at",
                "verified_at",
                "verification_status",
                "verification_policy_version",
                "verification_record_digest",
                "resolution_source",
                "scores",
                "status",
            ],
            "commit_refuses_when_unverified": True,
            "durable_field_derived_from_live_health_check": True,
        },
        "test_commands": [
            {
                "suite": "TCP-002.7-R3 dedicated adversarial recovery suite (new)",
                "command": (
                    "MIX_ENV=test mix test "
                    "test/tiannara/forecasting/resolution_registry_test.exs --seed 0 --no-deps-check"
                ),
                "cwd": ".",
                "tests": 42,
                "failures": 0,
                "exit_code": 0,
                "seeds": [0, 1, 2, 3, 4, 5, 123456],
                "executed": True,
            },
            {
                "suite": "application forecasting + research regression",
                "command": (
                    "MIX_ENV=test mix test test/tiannara/forecasting test/tiannara/research "
                    "--seed 0 --no-deps-check"
                ),
                "cwd": ".",
                "tests": 617,
                "failures": 0,
                "exit_code": 0,
                "seeds": [0, 123456],
                "executed": True,
            },
            {
                "suite": "executive set (incl. 2 skipped)",
                "command": (
                    "MIX_ENV=test mix test test/executive "
                    "test/tiannara/runtime/executive_memory_test.exs "
                    "test/tiannara/cel/services/executive_memory_test.exs "
                    "--seed 0 --no-deps-check"
                ),
                "cwd": ".",
                "tests": 88,
                "skipped": 2,
                "failures": 0,
                "exit_code": 0,
                "seeds": [0],
                "executed": True,
            },
            {
                "suite": "runtime regression",
                "command": (
                    "MIX_ENV=test mix test test/simulation test/runtime_layers test/kernel "
                    "test/cognitive test/world_model --seed 0 --no-deps-check"
                ),
                "cwd": "tiannara_runtime",
                "tests": 792,
                "properties": 32,
                "failures": 0,
                "exit_code": 0,
                "seeds": [0],
                "executed": True,
            },
        ],
        "not_executed": [
            "Independent verification: no independent verifier was available.",
            "CI on this branch: executed and completed on all three pushes (B, C and D). Elixir CI failed only the two documented pre-existing jobs (suite: the ten ResearchForecastingIntegrationTest failures; the non-blocking runtime quarantine: four failures) on all three pushes; Cross-Platform Verification passed on all three. No new failure is attributable to R3; the outcome is not claimed as passing (see ci_record).",
            "Real disk-corruption, power-loss, fsync-semantics or multi-writer fault injection on real media.",
            "Real external source acquisition (TCP-B-048) — no live external source is reachable from this environment.",
            "Resolution of a genuine, registered forecast against a real observation.",
            "Scoring of a genuine resolved forecast; calibration assessment.",
            "TCP-B-066 (source-trust policy) ratification — PROPOSED, NOT RATIFIED.",
            "TCP-B-067 (persistent, protected VerificationAuthority key).",
            "macOS or Linux local execution of this checkpoint; local execution was Windows-only.",
        ],
        "storage_and_retention": {
            "checkpoint_files": 13596,
            "tracked_files_deleted": 0,
            "tracked_files_modified": 0,
            "untracked_three_preserved": [
                "certification/atlas/r0_refresh_2026-10-24.json",
                "certification/audit/GENSERVER_OWNERSHIP_INVENTORY.csv",
                "certification/audit/GENSERVER_OWNERSHIP_INVENTORY.md",
            ],
            "cel_memory_v2_dets": "restored before commit; not staged",
            "cleanup_performed": "none",
        },
        "known_limitations": [
            "Fault injection is simulated; the partial-write and kill_after_write cases operate on real temp files but no hardware, firmware, filesystem or fsync-semantics fault was injected.",
            "No independent verification was performed; the tests are self-authored against the contract.",
            "No genuine observation was acquired (TCP-B-048); nothing was verified against reality, resolved or scored.",
            "TCP-B-067 remains open: the verification authority's signing key is ephemeral and process-exposed.",
            "Full-history re-read before every append and on replay is deliberate, O(n) and unmeasured here.",
            "TCP-B-061 (no trusted integrity anchor) and TCP-B-062 (single-writer log) remain open.",
            "Evidence digest and chain establish integrity, not publisher authenticity (TCP-B-058 remains PARTIAL).",
            "Legacy compatibility readers EventStore.stream/2 and EventStore.since/2 return bare event lists, discard parser diagnostics, and stream/2 includes :unverified_legacy events unlabelled; they are not fail-closed for completeness. R3 recovery uses read_records/1 plus live health/1 and is unaffected; making the compatibility readers explicit is bounded next work.",
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
        "findings_closed_this_checkpoint": {
            "TCP-B-064": (
                "RESOLVED — the outcome resolution is durably persisted through the "
                "canonical commit path (resolution_registry.ex) over the fail-closed "
                "EventStore; recovery is transactional with atomic publication, exact "
                "idempotency and conflict refusal; restart recovery is executed-tested. "
                "This closes the persistence capability; it does NOT claim that any "
                "genuine resolution has been produced (TCP-B-048)."
            ),
        },
        "findings_opened_this_checkpoint": {},
        "unresolved_findings": {
            "RL-565": "HIGH / OPEN",
            "RL-564": "OPEN",
            "F-ARC-018": "OPEN",
        },
        "governance": {
            "model_update_gate": (
                "unchanged; authority: :none, production_mutation: :forbidden, "
                "human_review_required: true"
            ),
            "human_review_controls": "intact",
            "production_mutation": False,
            "deployment_or_registry_promotion": False,
            "physical_actuation": False,
            "source_trust_policy_tcp_b_066": "PROPOSED, NOT RATIFIED",
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

    with open(os.path.join(EVID, "TCP_002_7_R3_EVIDENCE_MANIFEST.json"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write(body)
    with open(os.path.join(TCP, "TCP_002_7_R3_EVIDENCE_MANIFEST.json"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write(body)

    print("wrote certification/evidence/tcp002_7_r3/TCP_002_7_R3_EVIDENCE_MANIFEST.json")
    print("wrote certification/tcp/TCP_002_7_R3_EVIDENCE_MANIFEST.json")
    print("artifacts with digests:", len(artifacts))
    print("implementation_commit:", manifest["implementation_commit"])


if __name__ == "__main__":
    main()
