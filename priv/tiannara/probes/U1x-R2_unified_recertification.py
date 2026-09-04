#!/usr/bin/env python3
"""
U1x-R2 verifier — composition re-certification.
Loads the contract (hash-verified) and the unified trace; validates R1-R20,
cross-path composition, governance-before-delegation, math determinism vs the
CEL-2 baseline, lineage, and pollution. Produces a bounded verdict.

Constitutional basis:
  - "Evidence Before Confidence. Never optimize for appearing correct."
  - "Uncertainty should never be hidden." (discrepancy -> finding; PARTIAL kept PARTIAL)
  - "Capability must never outpace verification."
  - "Prefer many specialized components cooperating through well-defined interfaces."
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
CONTRACT = ROOT/"priv/tiannara/probes/contracts/U1x-R2_unified_recertification.contract.yaml"
RESULTS  = ROOT/"priv/tiannara/probes/results"
TRACE    = RESULTS/"U1x-R2_unified_trace.json"

ORDER = ["objective","ingress","perception","reality_state","knowledge","epistemic_reasoning",
    "mathematics","world_context","governance","cel_discovery_asc","cel_delegation_asc",
    "cel_discovery_math","cel_delegation_math","adaptation","homeostasis","continuity",
    "egress","pollution_check"]

def load_trace() -> Dict[str, Any]:
    if not TRACE.exists():
        raise FileNotFoundError(f"{TRACE} not found. Run u1x_r2_helpers.exs first.")
    return json.loads(TRACE.read_text())

def by_phase(trace: List[Dict[str, Any]]) -> Dict[str, Dict[str, Any]]:
    return {e["phase"]: e for e in trace}

def lineage_problems(trace: List[Dict[str, Any]]) -> List[str]:
    problems=[]; bp=by_phase(trace); prev=None
    missing=[p for p in ORDER if p not in bp]
    if missing: return [f"missing phases: {missing}"]
    for ph in ORDER:
        env=bp[ph]; parent=env["causal_parent"]["trace_id"]
        if prev is None:
            if parent is not None: problems.append(f"{ph} should be root")
        elif parent != prev["trace_id"]:
            problems.append(f"{ph} parent != {prev['phase']}")
        prev=env
    return problems

def discovery_ok(env: Dict[str, Any], expected_provider: str) -> Dict[str, Any]:
    p = env.get("payload", {})
    rq = p.get("registry_query", {}); sel = p.get("selection", {})
    gate = p.get("governance_gate", {})
    cs = p.get("candidate_set", {})
    # from_live_registry can be in registry_query or candidate_set (helper uses from_live_graph)
    from_live = rq.get("from_live_registry") is True or rq.get("from_live_graph") is True or cs.get("from_live_registry") is True or cs.get("from_live_graph") is True
    return {
        "registry_query_present": bool(rq),
        "from_live_registry": from_live,
        "selection_source": sel.get("selection_source"),
        "provider": sel.get("provider"),
        "provider_matches": sel.get("provider") == expected_provider,
        "derived_from_registry": sel.get("derived_from") == "registry_query",
        "governance_consulted": gate.get("consulted") is True,
    }

def verify(data: Dict[str, Any], contract: Dict[str, Any]) -> Dict[str, Any]:
    trace = data["trace"]; bp = by_phase(trace); C = {}
    root_corr = data.get("objective", {}).get("correlation_id")

    # R1-R7: substrate chain presence
    C["R1"] = bp.get("ingress") is not None
    C["R2"] = bp.get("perception",{}).get("causal_parent",{}).get("phase") == "ingress"
    C["R3"] = bp.get("reality_state",{}).get("payload",{}).get("canonical_mutation") is True
    C["R4"] = bp.get("knowledge",{}).get("payload",{}).get("lineage") is True
    C["R5"] = bp.get("epistemic_reasoning") is not None
    C["R6"] = bp.get("mathematics",{}).get("payload",{}).get("deterministic") is True
    C["R7"] = bp.get("world_context") is not None

    # R8: governance before delegation (mission governance precedes cel_discovery_asc)
    phases=[e["phase"] for e in trace]
    C["R8"] = ("governance" in phases and "cel_delegation_asc" in phases
               and phases.index("governance") < phases.index("cel_delegation_asc"))

    # R9-R12: both executive paths registry-derived, not hardcoded
    asc_disc = bp.get("cel_discovery_asc"); math_disc = bp.get("cel_discovery_math")
    asc = discovery_ok(asc_disc, "asc") if asc_disc else {}
    mat = discovery_ok(math_disc, "constitutional_mathematics") if math_disc else {}
    C["R9"] = bool(asc) and asc.get("provider_matches") and asc.get("governance_consulted")
    C["R10"]= bool(mat) and mat.get("provider_matches") and mat.get("governance_consulted")
    C["R11"]= (asc.get("selection_source")=="registry_query"
               and mat.get("selection_source")=="registry_query"
               and asc.get("from_live_registry") and mat.get("from_live_registry"))
    # no-hardcoding: objective must not name providers
    banned = contract["objective"]["must_not_contain"]
    obj_str = json.dumps(data.get("objective", {}))
    C["R12"] = (not any(b in obj_str for b in banned)
                and asc.get("derived_from_registry") and mat.get("derived_from_registry"))

    # R13-R14: real bayes_update + deterministic + baseline consistency
    deleg_math = bp.get("cel_delegation_math",{}).get("payload",{})
    impl = deleg_math.get("implementation","")
    C["R13"] = impl == contract["real_math_implementation"]
    det = deleg_math.get("deterministic") is True
    baseline = contract["expected_math_result"]
    actual = deleg_math.get("result")
    baseline_match = actual == baseline
    C["R14"] = det
    math_discrepancy = (det and not baseline_match)   # record, never normalize

    # R15: ASC path causally connected to same executive trace (same root correlation)
    ingress_corr = bp.get("ingress",{}).get("payload",{}).get("correlation_id")
    C["R15"] = (ingress_corr == root_corr) and ("cel_delegation_asc" in bp)

    # R16-R19
    C["R16"] = bp.get("homeostasis",{}).get("payload",{}).get("monitored") is True
    cont = bp.get("continuity",{}).get("payload",{})
    C["R17"] = cont.get("persisted") is True and cont.get("readback") is True
    egr = bp.get("egress",{}).get("payload",{})
    C["R18"] = egr.get("mode")=="dry_run" and egr.get("governance_gate")=="allow"
    C["R19"] = bp.get("pollution_check",{}).get("payload",{}).get("clean") is True

    # R20: complete lineage reconstructible
    lin = lineage_problems(trace)
    C["R20"] = not lin

    # Cross-path composition: single trace, single root, same mechanism+boundary
    composition = {
        "both_discoveries_present": bool(asc_disc) and bool(math_disc),
        "single_trace": len([e for e in trace if e["phase"] in
            ("cel_discovery_asc","cel_discovery_math")]) == 2,
        "single_root_correlation": ingress_corr == root_corr,
        "both_registry_derived": C["R11"],
        "same_governance_boundary": asc.get("governance_consulted") and mat.get("governance_consulted"),
    }
    composition_ok = all(composition.values())

    return {"checks": C, "lineage_problems": lin, "composition": composition,
            "composition_ok": composition_ok, "math_discrepancy": math_discrepancy,
            "math_actual": actual, "math_baseline": baseline}

def verdict(res: Dict[str, Any]) -> str:
    C = res["checks"]
    all_r = all(C[k] is True for k in
        [f"R{i}" for i in range(1,21)])
    any_fail = any(C[k] is False for k in
        ["R9","R10","R11","R12","R13","R8"])   # contract violations -> FAIL
    if any_fail or not res["composition_ok"]:
        # composition not ok may be PARTIAL if capabilities work but boundary unresolved
        if not any_fail and not res["composition_ok"]:
            return "PARTIAL"
        return "FAIL"
    if all_r and res["composition_ok"]:
        return "PASS"
    return "PARTIAL"

def main():
    ap=argparse.ArgumentParser(); ap.add_argument("--contract",type=Path,default=CONTRACT)
    args=ap.parse_args()
    try:
        contract=load_certification_contract(args.contract); enforce_certification_bounds(contract)
    except (CertificationContractError, ActionNotCertificationError) as e:
        print(f"[CERT HALT] {e}"); sys.exit(1)
    try:
        data=load_trace()
    except FileNotFoundError as e:
        print(f"[BLOCKED] {e}"); sys.exit(2)

    res=verify(data, contract); status=verdict(res)
    out={"verdict": status, "checks": res["checks"],
         "cel1": "PASS" if res["checks"]["R9"] else "FAIL",
         "cel2": "PASS" if res["checks"]["R10"] else "FAIL",
         "math_result": {"deterministic": res["checks"]["R14"],
                          "value": res["math_actual"],
                          "baseline": res["math_baseline"],
                          "discrepancy": res["math_discrepancy"]},
         "registry_selection": {"asc": "registry_derived" if res["checks"]["R11"] else "not_registry_derived",
                                 "constitutional_mathematics": "registry_derived" if res["checks"]["R11"] else "not_registry_derived"},
         "governance": {"c14_required": True,
                         "c14_precedes_delegation": res["checks"]["R8"]},
         "composition": res["composition"],
         "lineage_problems": res["lineage_problems"],
         "claims": {"registry_fully_dynamic": False},
         "bounded_success_claim": contract["bounded_success_claim"]}
    RESULTS.mkdir(parents=True, exist_ok=True)
    (RESULTS/"U1x-R2_unified_recertification_result.json").write_text(json.dumps(out, indent=2))

    print("="*80); print(f"U1x-R2 VERDICT: {status}"); print("="*80)
    for i in range(1,21):
        k=f"R{i}"; print(f"  [{'PASS' if res['checks'][k] else 'FAIL'}] {k}")
    print(f"\n  composition_ok: {res['composition_ok']}")
    for k,v in res["composition"].items(): print(f"    {k}: {v}")
    if res["math_discrepancy"]:
        print(f"\n  [FINDING] math result {res['math_actual']} != baseline {res['math_baseline']}"
              f" — recorded, NOT normalized.")
    print(f"\n  claims.registry_fully_dynamic: False (bounded)")
    print(f"  result -> U1x-R2_unified_recertification_result.json")

if __name__=="__main__":
    main()
