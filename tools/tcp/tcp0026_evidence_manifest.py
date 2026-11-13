#!/usr/bin/env python3
"""TCP-002.6 — evidence manifest generator.

Writes:
    certification/evidence/tcp002_6/TCP_002_6_EVIDENCE_MANIFEST.json
    certification/tcp/TCP_002_6_EVIDENCE_MANIFEST.json

Usage:
    python tools/tcp/tcp0026_evidence_manifest.py
"""

import hashlib
import json
import os
import subprocess
from datetime import datetime, timezone

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
TCP = os.path.join(ROOT, "certification", "tcp")
EVID = os.path.join(ROOT, "certification", "evidence", "tcp002_6")

ARTIFACTS = [
    "certification/tcp/TCP_002_6_IMPLEMENTATION_REPORT.md",
    "certification/tcp/TCP_002_6_EVIDENCE_MANIFEST.json",
    "certification/tcp/TCP_002_5_IMPLEMENTATION_REPORT.md",
    "certification/tcp/TCP-002_EXECUTION_SPINE.md",
    "certification/tcp/TCP-001_MASTER_COMPLETION_ASSESSMENT.md",
    "certification/tcp/TCP-001_PROGRAMME_CHARTER.md",
    "certification/tcp/TCP-001_COMPLETION_REGISTER.csv",
    "certification/tcp/TCP_002_3_EFDI_CONTRACT_AUDIT.md",
]

CHANGED = [
    "lib/tiannara/forecasting/outcome.ex",
    "lib/tiannara/forecasting/observation.ex",
    "lib/tiannara/forecasting/outcome_verifier.ex",
    "lib/tiannara/forecasting/outcome_resolution.ex",
    "lib/tiannara/forecasting/lifecycle.ex",
    "lib/tiannara/forecasting/verification_authority.ex",
    "lib/tiannara/forecasting/contracts.ex",
    "lib/tiannara/forecasting/forecast.ex",
    "lib/tiannara/forecasting/efdi.ex",
    "lib/tiannara/application.ex",
    "test/tiannara/forecasting/outcome_integrity_test.exs",
    "test/tiannara/forecasting/outcome_resolution_test.exs",
    "test/tiannara/forecasting/lifecycle_observability_test.exs",
    "tools/tcp/tcp0026_evidence_manifest.py",
]

BASELINE = "153f09799d301b1e8f803a02a26d10a31cd0d050"


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
        "checkpoint": "TCP-002.6",
        "title": (
            "Immutable Observation Binding, Independent Evidence Verification, "
            "and First Governed Outcome Resolution"
        ),
        "workstream": "W0 - Activate Existing Capabilities",
        "repository": "Kimiti4/Tiannara",
        "branch": git("rev-parse", "--abbrev-ref", "HEAD"),
        "baseline_commit": BASELINE,
        "commit": git("rev-parse", "HEAD"),
        "parent_commit": git("rev-parse", "HEAD~1"),
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "toolchain": {"elixir": "1.18.4", "otp": "28", "erts": "16.4"},
        "status": "PARTIAL",
        "disposition": "IMPLEMENTED_WITH_PARTIAL_EVIDENCE / VERIFICATION_BLOCKED",
        "canonical_forecasting_authority": "Tiannara.Forecasting (EFDI)",
        "canonical_resolution_authority": (
            "Tiannara.Forecasting.OutcomeResolution (single production caller: "
            "lib/tiannara/forecasting/efdi.ex:116)"
        ),
        "stages": {
            "0_baseline_disk_safety": "PASS",
            "1_source_contract_mapping": "PASS",
            "2_outcome_extension": "PASS",
            "3_immutable_binding": "PASS",
            "4_independent_verifier": "PASS",
            "5_horizon_enforcement": "PASS",
            "6_real_acquisition": "BLOCKED",
            "7_verified_observation": "OPEN",
            "8_durable_resolution": "PARTIAL",
            "9_scoring": "OPEN",
            "10_adversarial_regression": "PASS",
            "11_disk_aware_execution": "PASS",
            "12_observability": "PASS",
            "13_evidence_register": "PASS",
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
        "binding_contract": {
            "authoritative_source": "the registered forecast in the canonical ForecastRegistry",
            "caller_may_supply_authoritative_digests": False,
            "derived_fields": [
                "forecast_digest",
                "outcome_definition_digest",
                "horizon_digest",
            ],
            "observation_binding_module": "lib/tiannara/forecasting/observation.ex",
            "binding_refuses_self_asserted_verification": ":verification_status_not_acceptable_at_binding",
            "observation_content_digest": (
                "Outcome.content_digest/1 — binds the forecast, the observed value, "
                "the event, publication and acquisition timestamps, and the evidence "
                "reference and digest"
            ),
            "resolution_binding_checks": [
                "observation is bound (binding + evidence present)",
                "forecast digest matches the authoritative forecast",
                "outcome-definition digest matches the authoritative forecast",
                "horizon digest matches the authoritative forecast",
            ],
        },
        "verification_contract": {
            "verifier_module": "lib/tiannara/forecasting/outcome_verifier.ex",
            "policy_version": "efdi-verification-v1",
            "completed_verification_always_returns": "{:ok, result}",
            "negative_verdicts_are_not_errors": True,
            "statuses": [
                "verified",
                "verified_with_limited_source_assurance",
                "requires_review",
                "unverified",
                "rejected",
                "unavailable",
            ],
            "verified_status_reachable": False,
            "verified_status_limitation": (
                ":verified is unreachable because publisher authenticity is not "
                "established; the strongest status the implementation can produce "
                "is :verified_with_limited_source_assurance"
            ),
            "transition_module": "OutcomeVerifier.apply/2",
            "transition_requires_binding": [
                "observation id",
                "evidence digest",
                "forecast id",
                "forecast digest",
                "observation content digest",
                "verification policy version",
                "record digest",
            ],
            "resolver_requires_a_verification_record": True,
            "resolver_verification_failures": [
                ":verification_record_missing",
                ":verification_policy_unsupported",
                ":verification_record_tampered",
                ":verification_forecast_mismatch",
                ":verification_forecast_digest_mismatch",
                ":verification_observation_mismatch",
                ":verification_evidence_mismatch",
                ":observation_content_tampered",
                ":verification_not_sufficient",
                ":verification_status_mismatch",
            ],
            "record_limitation": (
                "A verification record is integrity-bound, not authenticated: its "
                "record_digest detects modification but does not prove the verifier "
                "process produced it. The reproduction path is to re-run verify/3 "
                "against the evidence store."
            ),
        },
        "horizon_enforcement": {
            "read_by_canonical_resolver": True,
            "enforced_at": "Tiannara.Forecasting.OutcomeResolution.validate_horizon/2",
            "caller_may_substitute_horizon": False,
            "checks": [
                "typed horizon present on the registered forecast",
                "event timestamp present",
                "event inside the registered horizon",
                "publication inside the registered publication policy",
            ],
            "temporal_authority": (
                "the existing Outcome/OutcomeResolution path; TemporalFirewall.verify/3 "
                "is decision-scoped and was NOT repurposed; no parallel forecast "
                "time validator was created"
            ),
        },
        "evidence_assurance": {
            "evidence_integrity": "ESTABLISHED — the verifier re-reads and re-digests the stored evidence",
            "source_identity": "ESTABLISHED to the declared policy's level; its authenticity is not established",
            "transport_protection": "NOT_ESTABLISHED by the verifier",
            "publisher_authenticity": "NOT_ESTABLISHED — no publisher signature is verified",
            "semantic_verification": "ESTABLISHED — the evidence is independently parsed and compared with the registered outcome definition",
            "temporal_eligibility": "ESTABLISHED — the registered typed horizon and publication policy are applied",
            "corroboration": "NOT_REQUIRED_AND_NOT_AVAILABLE",
            "overall": "VERIFIED_WITH_LIMITED_SOURCE_ASSURANCE",
            "note": (
                "VERIFIED_WITH_LIMITED_SOURCE_ASSURANCE is NOT interchangeable with "
                "VERIFIED. A content digest proves integrity only, never authenticity "
                "(TCP-B-058 remains PARTIAL)."
            ),
        },
        "legacy_compatibility": {
            "legacy_outcome_readable": True,
            "legacy_outcome_classification": "legacy_unverified",
            "legacy_outcome_eligible_for_resolution": False,
            "refusal_reason": ":legacy_outcome_not_eligible",
            "legacy_fields_fabricated_on_deserialization": False,
            "legacy_observed_at_reinterpreted": False,
        },
        "resolution_callers": [
            {
                "module": "Tiannara.Forecasting.OutcomeResolution.resolve/4",
                "production_callers": 1,
                "call_sites": ["lib/tiannara/forecasting/efdi.ex:116"],
                "bypass_path_exists": False,
                "note": (
                    "resolve/3 remains and fails closed with "
                    ":verification_record_missing; a resolution cannot be produced "
                    "without a bound verification record"
                ),
            }
        ],
        "observability": {
            "module": "lib/tiannara/forecasting/lifecycle.ex",
            "supervised": True,
            "scope": "process_scoped",
            "durable": False,
            "wired_into": [
                "Outcome.new/3",
                "Observation.bind/2",
                "OutcomeVerifier.verify/3",
                "OutcomeResolution.resolve/4",
            ],
            "conditions_kept_distinct": [
                "no observation",
                "observation acquired but unverified",
                "observation verified with limited source assurance",
                "observation requires review",
                "observation rejected",
                "outcome unresolved",
                "outcome resolved",
                "score unavailable",
            ],
            "reports_no_counts_when_the_ledger_is_unavailable": True,
            "never_claims_durability": True,
        },
        "real_source_result": {
            "selected_forecast": None,
            "source": None,
            "acquisition": "NOT_PERFORMED",
            "raw_evidence_preserved": None,
            "evidence_digest": None,
            "verification": None,
            "resolution": None,
            "blocker": (
                "No live external source is reachable from this environment. Stage 6 is "
                "BLOCKED and the lifecycle is left at FORECAST_REGISTERED rather than "
                "advanced with synthetic evidence."
            ),
        },
        "real_forecast_score": "NOT_ESTABLISHED",
        "test_commands": [
            {
                "suite": "application: test/tiannara/forecasting + test/tiannara/research",
                "command": (
                    "MIX_ENV=test mix test test/tiannara/forecasting test/tiannara/research "
                    "--seed 0 --no-deps-check"
                ),
                "cwd": ".",
                "tests": 565,
                "failures": 0,
                "seeds": [0, 123456],
                "executed": True,
            },
            {
                "suite": "observation binding and independent evidence verification (new)",
                "command": (
                    "MIX_ENV=test mix test "
                    "test/tiannara/forecasting/outcome_integrity_test.exs --seed 0 --no-deps-check"
                ),
                "cwd": ".",
                "tests": 39,
                "failures": 0,
                "seeds": [0],
                "executed": True,
            },
            {
                "suite": "outcome resolution contract (rewritten to the strengthened contract)",
                "command": (
                    "MIX_ENV=test mix test "
                    "test/tiannara/forecasting/outcome_resolution_test.exs --seed 0 --no-deps-check"
                ),
                "cwd": ".",
                "tests": 28,
                "failures": 0,
                "seeds": [0],
                "executed": True,
            },
            {
                "suite": "lifecycle and assurance observability (new)",
                "command": (
                    "MIX_ENV=test mix test "
                    "test/tiannara/forecasting/lifecycle_observability_test.exs --seed 0 --no-deps-check"
                ),
                "cwd": ".",
                "tests": 12,
                "failures": 0,
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
                "seeds": [0],
                "executed": True,
            },
        ],
        "not_executed": [
            "Real source acquisition: no live external source is reachable from this environment. No synthetic fixture is reported as a real observation.",
            "NATS transport round trip: no NATS server is available. It is compiled; no mocked transport evidence is reported as real transport execution.",
            "Independent verification of a real observation: depends on real acquisition.",
            "Scoring of a genuine resolved forecast: no eligible resolved forecast exists.",
        ],
        "storage_and_retention": {
            "starting_free_mb": 15696,
            "reported_265_mb_reading": (
                "transient — it was not a steady state and was not caused by checkpoint "
                "accumulation; it coincided with the delayed release of space from the "
                "removal of the self-nesting copy"
            ),
            "checkpoint_directory": "tiannara_runtime/data/cpl/checkpoints/<layer>/<checkpoint_id>.json",
            "checkpoint_writer": (
                "TiannaraRuntime.OS.Persistence.ConstitutionalPersistenceLayer.persist_checkpoint/2"
            ),
            "checkpoint_files": 13596,
            "checkpoint_layers": 6,
            "checkpoint_total_mb": 3,
            "checkpoint_tracked": 13596,
            "checkpoint_untracked": 0,
            "checkpoint_chain_field": "previous_checkpoint_id",
            "checkpoint_readers": [
                "ConstitutionalPersistenceLayer.load_checkpoints/2",
                "ConstitutionalPersistenceLayer.load_events/2",
            ],
            "pruning_implemented": False,
            "retention_decision": (
                "No cleanup of tracked checkpoints and no retention mechanism implemented. "
                "The checkpoints are git-tracked repository content (~3 MB aggregate), they "
                "are chained through previous_checkpoint_id, and a bounded retention policy "
                "must preserve the chain ancestors of the newest checkpoint and the recovery "
                "index. The unbounded growth that does matter is the runtime's per-event "
                "files, which is registered as TCP-B-065."
            ),
            "cleanup_performed": (
                "untracked runtime artefacts only; no git-tracked file was deleted, moved "
                "or rewritten"
            ),
            "tracked_files_deleted": 0,
        },
        "known_limitations": [
            "No real observation was acquired, so nothing was independently verified against reality, nothing was durably resolved, and no real score exists.",
            "A verification record is integrity-bound, not authenticated: its digest detects modification but does not prove the verifier process produced it.",
            "The :verified status is unreachable because publisher authenticity is not established; the strongest status produced is :verified_with_limited_source_assurance.",
            "The resolution record is returned but NOT durably persisted; a resolution survives only as a returned map and cannot be recovered after a restart (TCP-B-064).",
            "Evidence integrity is established; publisher authenticity is NOT. No publisher signature is verified, so TCP-B-058 remains PARTIAL and is not closed by the existence of an evidence digest.",
            "The durable log supports a single writer only (TCP-B-062).",
            "No external trusted integrity anchor exists outside the log's storage boundary (TCP-B-061).",
            "No ratified source-trust policy exists for forecast outcome evidence; the implementation uses the most conservative available behaviour (TCP-B-066).",
            "Hypothesis confidence (0.5) and per-domain eig_score constants remain heuristics presented as measurements (TCP-B-056).",
            "D6 institutional forecasting memory remains deferred.",
        ],
        "open_blockers": [
            "TCP-B-046",
            "TCP-B-048",
            "TCP-B-056",
            "TCP-B-061",
            "TCP-B-062",
            "TCP-B-064",
            "TCP-B-065",
            "TCP-B-066",
        ],
        "findings_closed_this_checkpoint": {
            "TCP-B-059": (
                "RESOLVED — the canonical resolver now reads and enforces the registered "
                "typed horizon; a substituted horizon cannot authorize resolution"
            ),
            "TCP-B-060": (
                "RESOLVED — binding, immutable evidence references, legacy handling and "
                "the verifier transition are implemented and adversarially tested"
            ),
            "TCP-B-063": (
                "RESOLVED — the forecast lifecycle's temporal authority is the existing "
                "Outcome/OutcomeResolution path; TemporalFirewall was not repurposed and "
                "no bypass path remains"
            ),
        },
        "findings_opened_this_checkpoint": {
            "TCP-B-064": "OPEN / HIGH — the outcome resolution is not durably persisted",
            "TCP-B-065": "OPEN / MEDIUM — unbounded runtime file growth into a git-tracked directory",
            "TCP-B-066": "OPEN / MEDIUM — no ratified source-trust policy",
        },
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

    with open(os.path.join(EVID, "TCP_002_6_EVIDENCE_MANIFEST.json"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write(body)
    with open(os.path.join(TCP, "TCP_002_6_EVIDENCE_MANIFEST.json"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write(body)

    print("wrote certification/evidence/tcp002_6/TCP_002_6_EVIDENCE_MANIFEST.json")
    print("wrote certification/tcp/TCP_002_6_EVIDENCE_MANIFEST.json")
    print("artifacts with digests:", len(artifacts))
    print("commit:", manifest["commit"])


if __name__ == "__main__":
    main()
