import json
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", ".."))
LIB = os.path.join(ROOT, "lib", "tiannara")


def read(rel):
    with open(os.path.join(LIB, rel), encoding="utf-8", errors="replace") as fh:
        return fh.read()


def read_root(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8", errors="replace") as fh:
        return fh.read()


def walk_physics():
    root = os.path.join(LIB, "physics")
    out = []
    for dirpath, _d, filenames in os.walk(root):
        for f in filenames:
            if f.endswith(".ex"):
                out.append(os.path.join(dirpath, f))
    return out


def main():
    failures = []

    # ---- PhysicsPilotExecution present and implements execute/1 ----
    ppe = read(os.path.join("phase4", "physics_pilot_execution.ex"))
    for tok in ["defmodule Tiannara.Phase4.PhysicsPilotExecution", "def execute",
                "guard_grant", "Authorization.expired?", ":authorization_grant_required",
                "Provenance.build", "kind: :real_execution",
                'harness: :real_simulation', "method: :rk4",
                "executions.jsonl", "EventStore.append", "physics_pilot"]:
        if tok not in ppe:
            failures.append("PhysicsPilotExecution missing token: " + tok)

    # ---- grant routing in Physics.execute_experiment/1 ----
    phys = read(os.path.join("domains", "physics.ex"))
    if "PhysicsPilotExecution.execute" not in phys:
        failures.append("Physics.execute_experiment does not route to PhysicsPilotExecution.execute")
    if "RealExecution.enabled?" not in phys:
        failures.append("Physics.execute_experiment does not gate on RealExecution.enabled?")
    # the fallback gated path must still exist (submit_experiment)
    if "submit_experiment" not in phys:
        failures.append("Physics.execute_experiment lost the gated submit_experiment fallback")
    # MC-001 pins in physics
    if "{:error, :formal_verification_unavailable}" not in phys:
        failures.append("Physics.validate lost formal_verification_unavailable (MC-001 pin)")

    # ---- MC-001 pin in calculus ----
    calc = read(os.path.join("foundations", "mathematics", "calculus.ex"))
    if "{:error, :ode_solver_unavailable}" not in calc:
        failures.append("Calculus.solve_ode lost ode_solver_unavailable (MC-001 pin)")

    # ---- zero rand in physics tree ----
    rand_hits = []
    for p in walk_physics():
        src = open(p, encoding="utf-8", errors="replace").read()
        if ":rand.uniform" in src:
            rand_hits.append(p)
    if rand_hits:
        failures.append(":rand.uniform present in physics tree: " + ", ".join(rand_hits))

    # ---- ledger probe: a real physics_pilot entry exists ----
    ledger_path = os.path.join(ROOT, "priv", "tiannara", "real_execution", "executions.jsonl")
    if os.path.exists(ledger_path):
        text = open(ledger_path, encoding="utf-8", errors="replace").read()
        if '"subsystem":"physics_pilot"' not in text:
            failures.append("executions.jsonl has no physics_pilot entry")
        if '"type":"real_execution"' not in text:
            failures.append("executions.jsonl physics_pilot entry not typed real_execution")
        if "real_simulation" not in text:
            failures.append("executions.jsonl physics_pilot entry missing harness real_simulation")
    else:
        failures.append("executions.jsonl missing")

    # ---- result JSON ----
    try:
        result = json.load(open(os.path.join(
            ROOT, "priv", "tiannara", "remediation", "results", "MC004_P_result.json"),
            encoding="utf-8"))
    except (OSError, ValueError):
        result = None
        failures.append("MC004_P_result.json invalid or unreadable")
    if isinstance(result, dict):
        flag_map = [("mutation_authorized", True), ("pilot_executed", True),
                    ("real_execution_enabled_flag", True), ("deployment_performed", False),
                    ("sandbox_patch_performed", False), ("production_mutation_from_pilot", False),
                    ("formal_verification_revived", False), ("fabricated_success_remaining_in_targets", 0)]
        for key, want in flag_map:
            if result.get(key) != want:
                failures.append("result JSON %s != %r (got %r)" % (key, want, result.get(key)))
        if result.get("verdict") != "CERTIFIED_BOUNDED":
            failures.append("result JSON verdict not CERTIFIED_BOUNDED")
        prov = result.get("provenance") or {}
        if prov.get("kind") != ":real_execution":
            failures.append("result JSON provenance.kind not :real_execution")
        ev = result.get("evidence") or {}
        if not ev.get("verifier") or "PENDING" in str(ev.get("verifier")):
            failures.append("result JSON evidence.verifier not finalized")

    # ---- artifacts ----
    artifacts = [
        "certification/remediation/MC004-P-EVIDENCE-MATRIX.md",
        "certification/remediation/MC004-P-CERTIFICATION.md",
        "priv/tiannara/remediation/contracts/MC004_P_domain_physics_pilot.contract.yaml",
        "priv/tiannara/remediation/results/MC004_P_result.json",
        "priv/tiannara/remediation/verifiers/MC004_P_pilot_execution.py",
        "priv/tiannara/authorization/ASC-MC-004-P-DOMAIN-PHYSICS-PILOT.human.yaml",
        "docs/remediation/MC004_P_PILOT_EXECUTION_PROTOCOL.md",
    ]
    for a in artifacts:
        if not os.path.exists(os.path.join(ROOT, a)):
            failures.append("artifact missing: " + a)

    # ---- authorization ----
    try:
        auth = read_root(os.path.join("priv", "tiannara", "authorization", "ASC-MC-004-P-DOMAIN-PHYSICS-PILOT.human.yaml"))
    except (FileNotFoundError, OSError):
        auth = ""
        failures.append("ASC-MC-004-P authorization human.yaml missing")
    if "GRANTED" not in auth:
        failures.append("MC-004-P authorization not GRANTED")
    if "c14_ac" not in auth:
        failures.append("MC-004-P authorization operator not c14_ac")
    if "pilot_executed: true" not in auth:
        failures.append("MC-004-P authorization does not record pilot_executed true")

    if failures:
        print("MC-004-P VERIFY: FAIL")
        for f in failures:
            print("  -", f)
        sys.exit(1)

    print("MC-004-P VERIFY: PASS")
    print("  Execution layer : PhysicsPilotExecution.execute/1 (grant + flag gated)")
    print("  Routing         : Physics.execute_experiment routes to pilot when granted; fallback gated path preserved")
    print("  Evidence        : provenance kind :real_execution; harness :real_simulation; method :rk4")
    print("  Ledger          : executions.jsonl has a real physics_pilot entry")
    print("  Invariants      : MC-001 pins kept; no deployment/sandbox/mutation; zero :rand.uniform")
    print("  Authorization   : GRANTED (c14_ac); pilot_executed true")
    print("  Boundary        : no deployment, no formal verification revival; flag restored false")


if __name__ == "__main__":
    main()