#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""MC-004-A0 Domain/Physics Reconciliation verifier (static evidence only, READ-ONLY)."""
import json
import os
import re
import sys
import datetime

REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", ".."))

ERRORS = []
CHECKS = []


def check(name, ok, detail=""):
    CHECKS.append({"name": name, "ok": bool(ok), "detail": detail})
    if not ok:
        ERRORS.append(f"{name}: {detail}")


def read(p):
    with open(p, "r", encoding="utf-8", errors="replace") as f:
        return f.read()


def exists(p):
    return os.path.isfile(p)


def scan_dir_for_refs(dirpath, patterns):
    """Count lines matching patterns (regex) under dirpath (recursive)."""
    count = 0
    hits = []
    for base, _, files in os.walk(dirpath):
        for fn in files:
            if not fn.endswith(".ex"):
                continue
            fp = os.path.join(base, fn)
            for i, line in enumerate(read(fp).splitlines(), 1):
                for pat in patterns:
                    if re.search(pat, line):
                        count += 1
                        hits.append(f"{os.path.relpath(fp, REPO)}:{i}")
                        break
    return count, hits


def grep_lib(pattern):
    count = 0
    hits = []
    for base, _, files in os.walk(os.path.join(REPO, "lib")):
        for fn in files:
            if not fn.endswith(".ex"):
                continue
            fp = os.path.join(base, fn)
            for i, line in enumerate(read(fp).splitlines(), 1):
                if re.search(pattern, line):
                    count += 1
                    hits.append(f"{os.path.relpath(fp, REPO)}:{i}")
    return count, hits


def load_yml(p):
    import yaml
    with open(p, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def main():
    t0 = datetime.datetime.now(datetime.timezone.utc).isoformat()

    # 0. Paths
    protocol = os.path.join(REPO, "docs", "remediation", "MC004_A0_DOMAIN_PHYSICS_RECONCILIATION_PROTOCOL.md")
    contract_p = os.path.join(REPO, "priv", "tiannara", "remediation", "contracts", "MC004_A0_domain_physics_reconciliation.contract.yaml")
    authz_p = os.path.join(REPO, "priv", "tiannara", "authorization", "ASC-MC-004-A0-DOMAIN-PHYSICS-RECONCILIATION.human.yaml")
    result_p = os.path.join(REPO, "priv", "tiannara", "remediation", "results", "MC004_A0_result.json")
    cert_dir = os.path.join(REPO, "certification", "remediation")
    physics_dir = os.path.join(REPO, "lib", "tiannara", "physics")
    domains_dir = os.path.join(REPO, "lib", "tiannara", "domains")
    registry_p = os.path.join(domains_dir, "canonical_registry.ex")
    domain_p = os.path.join(domains_dir, "physics.ex")
    calculus_p = os.path.join(REPO, "lib", "tiannara", "foundations", "mathematics", "calculus.ex")
    fv_p = os.path.join(REPO, "lib", "tiannara", "foundations", "formal_verification.ex")
    ade_p = os.path.join(REPO, "lib", "tiannara", "asc", "autonomous_discovery.ex")

    cert_docs = [
        "MC004-A0-PHYSICS-INVENTORY.md",
        "MC004-A0-TRUTH-CLASSIFICATION.md",
        "MC004-A0-CONSUMER-MAP.md",
        "MC004-A0-WORKFLOW-TRACE.md",
        "MC004-A0-ARCHITECTURE.md",
        "MC004-A0-VERIFICATION-PROVENANCE.md",
        "MC004-A0-SAFETY-EXECUTION.md",
        "MC004-A0-METRICS-DISCOVERY.md",
        "MC004-A0-PILOT-DEFINITION.md",
        "MC004-A0-BOTTLENECKS.md",
        "MC004-A0-MUTATION-PLAN.md",
        "MC004-A0-CERTIFICATION.md",
    ]

    # 1. Result JSON
    check("result_json_exists", exists(result_p), result_p)
    result = None
    if exists(result_p):
        try:
            result = json.loads(read(result_p))
            check("result_json_valid", True)
        except Exception as e:
            check("result_json_valid", False, str(e))
    if result:
        check("result_gate", result.get("gate") == "MC-004-A0", str(result.get("gate")))
        check("result_verdict", result.get("verdict") in {"CERTIFIED_RECONCILIATION", "PARTIAL_RECONCILIATION", "NOT_CERTIFIED"},
              str(result.get("verdict")))
        check("result_verdict_certified", result.get("verdict") == "CERTIFIED_RECONCILIATION", str(result.get("verdict")))
        check("result_physics_capability", result.get("physics_capability") in {"REAL", "PARTIAL", "THEATRICAL", "UNKNOWN", "NO"},
              str(result.get("physics_capability")))
        flags = result.get("flags", {})
        check("flag_mutation_false", flags.get("mutation_executed") is False, str(flags.get("mutation_executed")))
        check("flag_pilot_false", flags.get("pilot_executed") is False, str(flags.get("pilot_executed")))
        check("flag_real_exec_false", flags.get("real_execution_enabled") is False, str(flags.get("real_execution_enabled")))
        check("flag_authz_mutation_required", flags.get("authorization_required_for_mutation") is True, str(flags.get("authorization_required_for_mutation")))
        check("flag_authz_pilot_required", flags.get("authorization_required_for_live_pilot") is True, str(flags.get("authorization_required_for_live_pilot")))
        check("result_constitutional_answer", result.get("constitutional_answer") in {"YES", "PARTIAL", "NO"}, str(result.get("constitutional_answer")))
        check("result_authorization_status", result.get("authorization_status") == "GRANTED_READ_ONLY", str(result.get("authorization_status")))
        check("result_authorization_operator", result.get("authorization_operator") == "c14_ac", str(result.get("authorization_operator")))

    # 2. Protocol
    check("protocol_exists", exists(protocol))
    if exists(protocol):
        ptxt = read(protocol)
        check("protocol_read_only", "READ-ONLY" in ptxt and "NO production mutation" in ptxt)
        check("protocol_no_capability_cert", "NOT physics capability" in ptxt or "NO capability was certified" in ptxt)

    # 3. Contract
    check("contract_exists", exists(contract_p))
    contract = load_yml(contract_p) if exists(contract_p) else {}
    check("contract_gate", contract.get("gate") == "MC-004-A0", str(contract.get("gate")))
    check("contract_mode", contract.get("mode") == "READ_ONLY", str(contract.get("mode")))
    check("contract_no_mutation", contract.get("boundaries", {}).get("mutation_allowed") is False,
          str(contract.get("boundaries", {}).get("mutation_allowed")))
    check("contract_no_live_execution", contract.get("boundaries", {}).get("live_experiment_execution_allowed") is False,
          str(contract.get("boundaries", {}).get("live_experiment_execution_allowed")))

    # 4. Authorization
    check("authz_exists", exists(authz_p))
    authz = load_yml(authz_p) if exists(authz_p) else {}
    check("authz_granted", authz.get("status") == "GRANTED", str(authz.get("status")))
    check("authz_operator", authz.get("operator") == "c14_ac", str(authz.get("operator")))
    check("authz_kind", authz.get("authorization_kind") == "READ_ONLY_RECONCILIATION", str(authz.get("authorization_kind")))
    forbidden = " ".join(str(x) for x in authz.get("expressly_forbidden", []))
    check("authz_forbids_mutation", "mutation" in forbidden.lower(), forbidden[:80])
    check("authz_no_fabrication", authz.get("authorization_fabricated") in (None, False),
          str(authz.get("authorization_fabricated")))

    # 5. Canonical registry
    if exists(registry_p):
        rtxt = read(registry_p)
        domains = False
        count = 0
        for line in rtxt.splitlines():
            s = line.strip()
            if s.startswith("@canonical_domains ["):
                domains = True
                continue
            if domains:
                if s == "]":
                    break
                if re.match(r"^:[a-z]", s):
                    count += 1
        check("registry_physics_present", ":physics" in rtxt and ":physics," in rtxt)
        check("registry_20_domains", count == 20, f"count={count}")
        check("registry_binding", "defp domain_module(:physics), do: Tiannara.Domains.Physics" in rtxt)

    # 6. Domain module
    if exists(domain_p):
        dtxt = read(domain_p)
        check("domain_behaviour", "@behaviour Tiannara.Domains.Domain" in dtxt)
        check("domain_8_callbacks_impl", dtxt.count("@impl true") >= 8, f"@impl count={dtxt.count('@impl true')}")
        check("domain_no_theatrics", ":rand.uniform" not in dtxt and "rand.uniform" not in dtxt)
        check("domain_simulate_to_calculus", "Calculus.solve_ode" in dtxt)
        check("domain_validate_to_fv", "FormalVerification.verify_invariants" in dtxt)
        check("domain_honest_empty_discover", "discoveries: []" in dtxt)
        check("domain_metrics_truthful", "metrics_source" in dtxt and "state_derived" in dtxt)

    # 7. Substrate unavailability (unchanged, honest)
    check("calculus_unavailable", exists(calculus_p) and ":ode_solver_unavailable" in read(calculus_p))
    check("fv_unavailable", exists(fv_p) and ":formal_verification_unavailable" in read(fv_p))

    # 8. NO mutation guard: no real ODE/integrator added, no provenance/real-exec wiring added
    n_rk4, h_rk4 = grep_lib(r"\b(rk4|ode45)\b|def integrate_ode")
    check("no_ode_integrator_added", n_rk4 == 0, "; ".join(h_rk4[:5]) or "no rk4/ode45/integrate_ode")
    n_prov, h_prov = scan_dir_for_refs(physics_dir, [r"Provenance", r"RealExecution", r"Phase4"])
    check("physics_no_provenance_exec", n_prov == 0, "; ".join(h_prov[:5]) or "no refs")
    n_dprov, h_dprov = scan_dir_for_refs(domains_dir, [r"Provenance", r"RealExecution", r"Phase4"])
    check("domains_no_provenance_exec", n_dprov == 0, "; ".join(h_dprov[:5]) or "no refs")

    # 9. Subsystem theatrics documented (>= 2 files genuinely contain :rand.uniform)
    theaters = []
    for base, _, files in os.walk(physics_dir):
        for fn in files:
            if fn.endswith(".ex"):
                fp = os.path.join(base, fn)
                if ":rand.uniform" in read(fp):
                    theaters.append(os.path.relpath(fp, REPO))
    check("subsystem_theatrics_present", len(theaters) >= 2, f"files={len(theaters)}")
    subsystem_theatrics_json = json.dumps(theaters)

    # 10. ADE dead-path
    n_ade, h_ade = grep_lib(r"run_discovery_cycle")
    check("ade_dead", n_ade == 1, f"occurrences={n_ade} ({'; '.join(h_ade)})")

    # 11. Pilot NOT executed, no trajectory artifacts
    pilot_count = 0
    for base, _, files in os.walk(os.path.join(REPO, "priv", "tiannara", "remediation", "results")):
        for fn in files:
            if re.search(r"trajectory|MC004_P.*result|pilot.*result", fn, re.I):
                pilot_count += 1
    check("no_pilot_artifacts", pilot_count == 0, f"found={pilot_count}")
    pilot_doc = os.path.join(cert_dir, "MC004-A0-PILOT-DEFINITION.md")
    check("pilot_doc_not_executed", exists(pilot_doc) and "NOT_EXECUTED" in read(pilot_doc))
    if result:
        check("pilot_status_not_executed", result.get("pilot_definition", {}).get("status") == "NOT_EXECUTED",
              str(result.get("pilot_definition", {}).get("status")))

    # 12. Certification docs all present
    for d in cert_docs:
        check(f"cert_doc_{d}", exists(os.path.join(cert_dir, d)), d)
    cert_txt = read(os.path.join(cert_dir, "MC004-A0-CERTIFICATION.md")) if exists(os.path.join(cert_dir, "MC004-A0-CERTIFICATION.md")) else ""
    check("certification_not_capability", "NOT physics capability" in cert_txt, "")
    check("certification_verdict", "CERTIFIED_RECONCILIATION" in cert_txt, "")

    ok = not ERRORS
    out = {
        "gate": "MC-004-A0",
        "phase": "RECONCILIATION_ONLY",
        "timestamp": t0,
        "exit": 0 if ok else 1,
        "verdict": "PASS" if ok else "FAIL",
        "checks": CHECKS,
        "subsystem_theatrical_files": theaters,
        "notes": [
            "Static reconciliation verification only. No source modified (A0 read-only).",
            "Full-runtime side-effect observation NOT_EXECUTED in this environment.",
            "git-diff baseline unavailable (pre-existing working-tree state)."
        ]
    }
    out_path = os.path.join(REPO, "priv", "tiannara", "remediation", "results", "MC004_A0_verifier_output.json")
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(out, f, indent=2)

    print(f"MC-004-A0 reconciliation verifier: {'PASS' if ok else 'FAIL'}")
    print(f"checks: {len(CHECKS)} total, {len(ERRORS)} failed")
    for e in ERRORS:
        print(f"  FAIL: {e}")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()