#!/usr/bin/env python3
"""
MC-003-A0 verifier — independently inspects repository source.
Does NOT trust the certification record. Read-only.

Checks:
  1. all 14 required artifacts exist
  2. result JSON valid, verdict in the allowed set, mutation_executed false,
     authorization_required_for_mutation true, status_report present
  3. claimed REAL execution sites contain real mechanics (subprocess cmds,
     earned measurement, provenance gating)
  4. claimed THEATRICAL/FABRICATED sites show fabrication patterns (:rand,
     hardcoded PASS, pre-opened gates, status flips)
  5. execution gate unwired: Approval.decide has no callers in lib/
  6. P16 gateway dead: Phase4.ExperimentOrchestrator.submit_experiment has no
     callers in lib/
  7. P16-AT(d) evidence: discovery_scheduler.ex:178 keeps the fixed delta
  8. authorization signature not fabricated (read-only, signature null)
"""
import json, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]  # verifiers -> remediation -> tiannara -> priv -> repo root
RESULTS = ROOT / "priv" / "tiannara" / "remediation" / "results"

ARTIFACTS = [
    "docs/remediation/MC003_A0_REAL_EXECUTION_RECONCILIATION_PROTOCOL.md",
    "priv/tiannara/remediation/contracts/MC003_A0_real_execution_reconciliation.contract.yaml",
    "priv/tiannara/authorization/ASC-MC-003-A0-REAL-EXECUTION-RECONCILIATION.human.yaml",
    "certification/remediation/MC003-A0-EXECUTION-INVENTORY.md",
    "certification/remediation/MC003-A0-TRUTH-CLASSIFICATION.md",
    "certification/remediation/MC003-A0-CONSUMER-MAP.md",
    "certification/remediation/MC003-A0-ARCHITECTURE.md",
    "certification/remediation/MC003-A0-VERIFICATION.md",
    "certification/remediation/MC003-A0-SAFETY-RELIABILITY.md",
    "certification/remediation/MC003-A0-BOTTLENECKS.md",
    "certification/remediation/MC003-A0-MUTATION-PLAN.md",
    "certification/remediation/MC003-A0-RECONCILIATION-CERTIFICATION.md",
    "priv/tiannara/remediation/results/MC003_A0_result.json",
    "priv/tiannara/remediation/verifiers/MC003_A0_real_execution_reconciliation.py",
]


def read(p):
    return (ROOT / p).read_text(errors="replace")


def check_artifacts():
    return {a: (ROOT / a).exists() for a in ARTIFACTS}


def check_json():
    p = RESULTS / "MC003_A0_result.json"
    try:
        d = json.loads(p.read_text())
        allowed = {"CERTIFIED_RECONCILIATION", "PARTIAL_RECONCILIATION", "NOT_CERTIFIED"}
        req = ["gate", "phase", "verdict", "mutation_executed",
               "authorization_required_for_mutation", "capability_counts",
               "critical_findings", "bottlenecks", "evidence_limitations",
               "status_report"]
        status_keys = ["compile_status", "test_status", "runtime_status",
                       "static_scan_status", "verifier_status"]
        sr = d.get("status_report", {})
        return {
            "valid": all(k in d for k in req),
            "verdict_in_allowed_set": d.get("verdict") in allowed,
            "mutation_executed": d.get("mutation_executed"),
            "authorization_required_for_mutation": d.get("authorization_required_for_mutation"),
            "status_report_present": all(k in sr for k in status_keys),
            "status_report_keys": sorted(sr.keys()),
        }
    except Exception as e:
        return {"valid": False, "error": str(e)}


def check_real_sites():
    checks = {
        "experiment_step_real_measurement": ("lib/tiannara/discovery/steps/experiment_step.ex",
                                             ["def execute(input, _ctx)", "produced_by: __MODULE__",
                                              "evidence_routed()", "measurement:"]),
        "local_backend_system_cmd": ("lib/tiannara/self_improvement/sandbox/backend/local.ex",
                                     ["System.cmd", ":brutal_kill", "Task.async"]),
        "container_backend_isolated": ("lib/tiannara/self_improvement/sandbox/backend/container.ex",
                                      ["--network", "none"]),
        "real_harness_benchmark": ("lib/tiannara/self_improvement/sandbox/real_harness.ex",
                                   ["def run(backend, baseline, patch", "compare_benchmarks"]),
        "world_state_sync_real_integration": ("lib/tiannara/world/world_state_synchronizer.ex",
                                              ["create_entity", "retry"]),
        "knowledge_integrator_gate": ("lib/tiannara/research/knowledge_integrator.ex",
                                      [":real_execution"]),
        "provenance_gate": ("lib/tiannara/evidence/provenance.ex",
                            ["def ", "execution_id"]),
    }
    res = {}
    for k, (p, pats) in checks.items():
        f = ROOT / p
        if not f.exists():
            res[k] = {"exists": False}
            continue
        t = f.read_text(errors="replace")
        res[k] = {"exists": True, "pats": {pat: (pat in t) for pat in pats}}
    return res


def check_theatrical_sites():
    checks = {
        "sandbox_simulates": ("lib/tiannara/sandbox.ex",
                              "For now, we simulate", ":rand.uniform() < success_prob"),
        "simulation_manager_fabricates": ("lib/tiannara/autonomy/simulation_manager.ex",
                                          "500 + :rand.uniform(200)", "throughput_ops_sec: 5000 + :rand.uniform(2000)"),
        "deployment_pipeline_flips_status": ("lib/tiannara/autonomy/deployment_pipeline.ex",
                                             "checkpoint_id = Types.new_id()", "stage: :monitoring"),
        "rollback_is_fake": ("lib/tiannara/autonomy/rollback_engine.ex",
                             ":timer.sleep(10)", "checkpoint_id = Types.new_id()"),
        "repair_stub_success": ("lib/tiannara/asc/repair/pipeline.ex",
                                "{:ok, :pass}", "def validate(_project, _patch), do: {:ok, :pass}"),
        "repair_canary_stub": ("lib/tiannara/asc/repair/pipeline.ex",
                               "{:ok, :canary_deployed}", "def release(_project, _patch), do: {:ok, :canary_deployed}"),
        "repair_rollout_stub": ("lib/tiannara/asc/repair/pipeline.ex",
                                "{:ok, :rolled_out}", "def rollout(_project), do: {:ok, :rolled_out}"),
        "verifier_hardcoded": ("lib/tiannara/verification_authority.ex",
                               "reproduced: true", "confidence: 0.95", "all_passing: true"),
        "certifier_gates_preopen": ("lib/tiannara/omega/certification_server.ex",
                                    ":gate_open", "sandbox_validated: :gate_open"),
        "httpoison_stub": ("lib/tiannara/stubs/httpoison.ex",
                           "status_code: 200", "body: \"\""),
    }
    res = {}
    for k, (p, *pats) in checks.items():
        f = ROOT / p
        if not f.exists():
            res[k] = {"exists": False}
            continue
        t = f.read_text(errors="replace")
        res[k] = {"exists": True, "pats": {pat: (pat in t) for pat in pats}}
    return res


def count_lib(pattern, exclude_paths=()):
    n = 0
    for f in (ROOT / "lib").rglob("*.ex"):
        rel = f.relative_to(ROOT).as_posix()
        if any(e in rel for e in exclude_paths):
            continue
        n += f.read_text(errors="replace").count(pattern)
    return n


def check_gate_wiring():
    approval = read("lib/tiannara/sentinel/activation/approval.ex")
    orch = read("lib/tiannara/phase4/experiment_orchestrator.ex")
    decide_defined = "def decide(proposal_id, :approve)" in approval or "def decide" in approval
    submit_defined = "def submit_experiment(experiment_spec)" in orch
    return {
        "approval_decide_defined": decide_defined,
        "approval_decide_callers_in_lib": count_lib("Approval.decide(",
                                                    exclude_paths=("sentinel/activation/approval.ex",)),
        "submit_experiment_defined": submit_defined,
        "submit_experiment_callers_in_lib": count_lib("submit_experiment(",
                                                      exclude_paths=("phase4/experiment_orchestrator.ex",)),
    }


def check_p16_unmet_evidence():
    sched = read("lib/tiannara/discovery/discovery_scheduler.ex")
    fixed_delta = "if(outcome == :supported, do: 0.1, else: 0.0)" in sched
    sandbox = read("lib/tiannara/executive/cognitive/executive_cycle.ex")
    snap = read("lib/tiannara/sandbox.ex")
    loop_a_live = ("status: :executed" in sandbox or ":executed" in sandbox) and \
                  ("def execute" in snap or ":valid" in snap or "validate" in snap)
    return {
        "p16_d_fixed_delta_still_present": fixed_delta,
        "execution_cycle_status_executed_present": ":executed" in sandbox or "status: :executed" in snap,
    }


def check_auth():
    p = ROOT / "priv/tiannara/authorization/ASC-MC-003-A0-REAL-EXECUTION-RECONCILIATION.human.yaml"
    if not p.exists():
        return {"exists": False}
    t = p.read_text(errors="replace")
    return {"exists": True,
            "sig_null": "signature: null" in t,
            "read_only": "OBSERVATIONAL_READ_ONLY" in t}


def main():
    r_real = check_real_sites()
    t_real = check_theatrical_sites()
    wiring = check_gate_wiring()
    p16 = check_p16_unmet_evidence()
    out = {
        "artifacts": check_artifacts(),
        "result_json": check_json(),
        "real_sites": r_real,
        "theatrical_sites": t_real,
        "gate_wiring": wiring,
        "p16_unmet_evidence": p16,
        "authorization": check_auth(),
    }
    RESULTS.mkdir(parents=True, exist_ok=True)
    (RESULTS / "MC003_A0_verifier_output.json").write_text(json.dumps(out, indent=2))

    def real_ok(r):
        return all(v["exists"] and all(v["pats"].values()) for v in r.values())

    def the_ok(t):
        return all(v["exists"] and all(v["pats"].values()) for v in t.values())

    ok = (
        all(out["artifacts"].values())
        and out["result_json"].get("valid") is True
        and out["result_json"].get("verdict_in_allowed_set") is True
        and out["result_json"].get("mutation_executed") is False
        and out["result_json"].get("authorization_required_for_mutation") is True
        and out["result_json"].get("status_report_present") is True
        and real_ok(r_real)
        and the_ok(t_real)
        and wiring["approval_decide_defined"] is True
        and wiring["approval_decide_callers_in_lib"] == 0
        and wiring["submit_experiment_defined"] is True
        and wiring["submit_experiment_callers_in_lib"] == 0
        and p16["p16_d_fixed_delta_still_present"] is True
        and out["authorization"].get("exists") is True
        and out["authorization"].get("sig_null") is True
        and out["authorization"].get("read_only") is True
    )
    print("MC-003-A0 VERIFIER:", "PASS" if ok else "INCOMPLETE")
    print("artifacts ok:", all(out["artifacts"].values()))
    print("missing artifacts:", [a for a, v in out["artifacts"].items() if not v])
    print("real sites failing:", [k for k, v in r_real.items()
                                  if not (v.get("exists") and all(v.get("pats", {}).values()))])
    print("theatrical sites failing:", [k for k, v in t_real.items()
                                        if not (v.get("exists") and all(v.get("pats", {}).values()))])
    print("gate wiring:", wiring)
    print("authorization:", out["authorization"])
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()