#!/usr/bin/env python3
"""
CEL-2 verifier — Constitutional Mathematics as a discoverable capability.

Loads a mode-specific trace (CEL-2_trace_<mode>.json) emitted by cel2_helpers.exs
and verifies the 11 assertions. Certification-only; registration is a separate
C14-gated action and is NOT performed here.

Constitutional basis:
  - "Uncertainty should never be hidden." (MATH_NOT_REGISTERED over fabricated success)
  - "Evidence Before Confidence. Never optimize for appearing correct."
  - "Capability must never outpace verification."
"""

import sys, json, argparse
from pathlib import Path
from typing import Dict, Any, List

sys.path.insert(0, str(Path(__file__).parent))
from certification_bounds import (
    load_certification_contract, enforce_certification_bounds,
    CertificationContractError, ActionNotCertificationError,
)

ROOT = Path(__file__).parent.parent.parent.parent
CONTRACT = ROOT/"priv/tiannara/probes/contracts/CEL-2_constitutional_mathematics.contract.yaml"
RESULTS  = ROOT/"priv/tiannara/probes/results"
NEG_TRACE = RESULTS/"u1x_trace.json"                 # immutable negative control
REG_TRACE = RESULTS/"CEL-2_registration_trace.json"
POS_TRACE = RESULTS/"CEL-2_trace_positive.json"

POS_ORDER = ["objective","registry_query","candidate_set","health_check",
    "ownership_check","dependency_check","interface_validation","selection",
    "governance_gate","delegation","math_operation","result","pollution_check"]

def load(path: Path) -> Dict[str, Any]:
    if not path.exists():
        raise FileNotFoundError(f"{path} not found")
    return json.loads(path.read_text())

def by_phase(trace: List[Dict[str, Any]]) -> Dict[str, Dict[str, Any]]:
    return {e["phase"]: e for e in trace}

def lineage_problems(trace: List[Dict[str, Any]], order: List[str]) -> List[str]:
    problems=[]; bp=by_phase(trace); prev=None
    for ph in order:
        if ph not in bp: problems.append(f"missing {ph}"); continue
        env=bp[ph]; parent=env["causal_parent"]["trace_id"]
        if prev is None:
            if parent is not None: problems.append(f"{ph} should be root")
        elif parent != prev["trace_id"]:
            problems.append(f"{ph} parent != {prev['phase']}")
        prev=env
    return problems

# ---- negative control (must be intact and immutable) ----
def verify_negative() -> Dict[str, Any]:
    try:
        neg = load(NEG_TRACE)
    except FileNotFoundError:
        return {"pass": False, "reason": "negative control missing"}
    ok = neg.get("math_discoverable") is False
    return {"pass": ok, "expected": "MATH_NOT_REGISTERED",
            "note": "negative control immutable" if ok else "negative control violated"}

# ---- registration trace ----
def verify_registration() -> Dict[str, Any]:
    try:
        reg = load(REG_TRACE)
    except FileNotFoundError:
        return {"pass": False, "status": "BLOCKED", "reason": "registration trace missing"}
    trace = reg["trace"]; bp = by_phase(trace)
    order_ok = not lineage_problems(trace,
        ["registration_request","c14_review","authorization_decision",
         "registry_mutation","live_registry_readback"])
    decision = bp.get("authorization_decision",{}).get("payload",{}).get("decision")
    readback = bp.get("live_registry_readback",{}).get("payload",{})
    # hard-fail: provider inserted by probe, not C14
    c14_path = decision == "allow" and bp.get("registry_mutation") is not None
    return {"pass": order_ok and c14_path and readback.get("present") is True,
            "order_ok": order_ok, "c14_path": c14_path,
            "readback_present": readback.get("present"),
            "hard_fail_probe_insertion": not c14_path}

# ---- positive control: P1-P11 ----
def verify_positive(contract) -> Dict[str, Any]:
    try:
        pos = load(POS_TRACE)
    except FileNotFoundError:
        return {"status":"BLOCKED","reason":"positive trace missing","checks":{}}
    trace = pos["trace"]; bp = by_phase(trace); C = {}
    objective = pos.get("objective",{})

    # hard-fail: objective names the provider
    banned = contract["objective_constraint"]["must_not_contain"]
    obj_str = json.dumps(objective)
    C["objective_clean"] = not any(b in obj_str for b in banned)

    C["P1"] = bp.get("objective") is not None
    rq = bp.get("registry_query",{})
    C["P2"] = rq is not None and rq["causal_parent"]["trace_id"] == bp["objective"]["trace_id"]
    C["P3"] = bp.get("candidate_set",{}).get("payload",{}).get("from_live_registry") is True
    sel = bp.get("selection",{}).get("payload",{})
    C["P4"] = sel.get("derived_from") == "registry_query" and C["objective_clean"]
    C["P5"] = all(bp.get(p) is not None for p in
        ["health_check","ownership_check","dependency_check","interface_validation"])
    C["P6"] = sel.get("provider") == "constitutional_mathematics"
    phases=[e["phase"] for e in trace]
    C["P7"] = ("governance_gate" in phases and "delegation" in phases
               and phases.index("governance_gate") < phases.index("delegation"))
    deleg = bp.get("delegation",{}).get("payload",{})
    C["P8"] = ("Tiannara.Math.Probability.bayes_update/3" in deleg.get("implementation","")
               and deleg.get("status")=="EXECUTED")
    mo = bp.get("math_operation",{}).get("payload",{})
    C["P9"] = mo.get("result") is not None and mo.get("deterministic") is True
    res = bp.get("result",{}).get("payload",{})
    C["P10"] = res.get("objective_id") == objective.get("id")
    C["P11"] = bp.get("pollution_check",{}).get("payload",{}).get("clean") is True
    C["TRACE"] = not lineage_problems(trace, POS_ORDER)

    # hard fails
    hard = []
    if not rq: hard.append("registry_query absent")
    if rq and sel.get("derived_from") != "registry_query": hard.append("registry_query does not influence selection")
    if not C["P7"]: hard.append("governance bypassed or misordered")
    if not C["P8"]: hard.append("delegation does not invoke registered implementation")
    if not C["P9"]: hard.append("result not deterministic")
    if not C["TRACE"]: hard.append("trace causally inconsistent")
    if not C["P11"]: hard.append("unrelated production state mutated")

    all_p = all(C[k] is True for k in
        ["P1","P2","P3","P4","P5","P6","P7","P8","P9","P10","P11","TRACE"])
    if hard: status="FAIL"
    elif all_p: status="PASS"
    elif C["P4"]: status="PARTIAL"   # discovered but some assertion unestablished
    else: status="FAIL"
    return {"status": status, "checks": C, "hard_fails": hard}

def main():
    ap=argparse.ArgumentParser(); ap.add_argument("--contract",type=Path,default=CONTRACT)
    ap.add_argument("--mode", choices=["negative","positive","both"], default="both")
    args=ap.parse_args()
    try:
        contract=load_certification_contract(args.contract); enforce_certification_bounds(contract)
    except (CertificationContractError, ActionNotCertificationError) as e:
        print(f"[CERT HALT] {e}"); sys.exit(1)

    results = {}
    if args.mode in ("negative","both"):
        try: results["negative"] = verify_negative()
        except FileNotFoundError as e: results["negative"] = {"mode":"negative","status":"BLOCKED","reason":str(e)}
    if args.mode in ("positive","both"):
        try: results["positive"] = verify_positive(load(REG_TRACE) if False else load_contract_for_positive(contract))
        except FileNotFoundError as e: results["positive"] = {"mode":"positive","status":"BLOCKED","reason":str(e)}
        # Actually call verify_positive directly
        try:
            results["positive"] = verify_positive(contract)
        except FileNotFoundError as e:
            results["positive"] = {"mode":"positive","status":"BLOCKED","reason":str(e)}

    # Overall CEL-2 verdict
    neg = results.get("negative",{}); pos = results.get("positive",{})
    # Use the helper to load traces properly
    try:
        neg_v = verify_negative()
        pos_v = verify_positive(contract)
        results["negative"] = neg_v
        results["positive"] = pos_v
    except Exception as e:
        pass

    if pos.get("status")=="BLOCKED" or neg.get("pass") is False:
        overall="BLOCKED" if (pos.get("status")=="BLOCKED") else "FAIL"
        if not neg.get("pass", True): overall="FAIL"   # negative control violated => integrity failure
    elif pos.get("status")=="FAIL":
        overall="FAIL"
    elif pos.get("status")=="PASS" and neg.get("pass"):
        overall="PASS"
    else:
        overall="PARTIAL"

    # Re-evaluate with actual verifier
    try:
        neg_r = verify_negative()
        pos_r = verify_positive(contract)
        if pos_r.get("status")=="PASS" and neg_r.get("pass"):
            overall="PASS"
        elif pos_r.get("status")=="PARTIAL":
            overall="PARTIAL"
        elif pos_r.get("status")=="BLOCKED":
            overall="BLOCKED"
        else:
            overall="FAIL"
        results["negative"] = neg_r
        results["positive"] = pos_r
    except Exception as e:
        print(f"Verifier error: {e}")

    out={"probe":"CEL-2","overall":overall,
         "negative_control":results.get("negative"),"positive_control":results.get("positive"),
         "bounded_proposition":contract["bounded_proposition"],
         "post_verdict_language":contract["post_verdict_language"]}
    RESULTS.mkdir(parents=True,exist_ok=True)
    (RESULTS/"CEL-2_constitutional_mathematics_result.json").write_text(json.dumps(out,indent=2))

    print("="*80); print(f"CEL-2 OVERALL: {overall}"); print("="*80)
    for m, r in [("negative", neg_r), ("positive", pos_r)]:
        print(f"\n[{m}]")
        if "pass" in r:
            print(f"  pass={r.get('pass')}")
        if "status" in r:
            print(f"  status={r.get('status')}")
        for k, v in (r.get("checks") or {}).items():
            if isinstance(v, bool):
                print(f"    [{'PASS' if v else 'FAIL'}] {k}")
            elif isinstance(v, dict) and "pass" in v:
                print(f"    [{'PASS' if v['pass'] else 'FAIL'}] {k}")
    if pos_r.get("hard_fails"):
        print(f"  hard_fails: {pos_r['hard_fails']}")
    print(f"\nPost-verdict language (binding):\n  {contract['post_verdict_language']}")

def load_contract_for_positive(contract):
    return contract

if __name__=="__main__":
    main()
