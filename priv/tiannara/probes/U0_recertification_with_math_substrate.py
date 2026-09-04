#!/usr/bin/env python3
"""
U0 Full Closed-Loop Re-Certification verifier with Constitutional Mathematics substrate.
Inspects the trace directly; does NOT trust helper assertions. Validates R1-R23
and emits a bounded verdict. Certification-only.

Constitutional basis:
  - "Evidence Before Confidence. Never optimize for appearing correct."
  - "Uncertainty should never be hidden."
  - "Capability must never outpace verification."
"""

import sys, json, hashlib, argparse
from pathlib import Path
from typing import Dict, Any, List

sys.path.insert(0, str(Path(__file__).parent))
from certification_bounds import (
    load_certification_contract, enforce_certification_bounds,
    CertificationContractError, ActionNotCertificationError,
)

ROOT = Path(__file__).parent.parent.parent.parent
CONTRACT = ROOT/"priv/tiannara/probes/contracts/U0_recertification_with_math_substrate.contract.yaml"
RESULTS  = ROOT/"priv/tiannara/probes/results"
TRACE    = RESULTS/"U0_recertification_trace.json"
MATH_IMPL = "Tiannara.Math.Probability.bayes_update/3"
EXPECTED_MATH = 2.25

ORDER = ["c11_ingress","c1_perception","c2_reality","c3_knowledge",
    "c4_epistemics_with_math","c5_mathematics_substrate","c8_context_with_math",
    "c14_governance_with_math","cel_discovery_asc","cel_delegation_asc",
    "cel_discovery_math","cel_delegation_math","c9_asc","c12_homeostasis",
    "c15_continuity","c11_egress","pollution_check"]

def load_trace() -> Dict[str, Any]:
    if not TRACE.exists():
        raise FileNotFoundError(f"{TRACE} not found. Run u0_recertification_helpers.exs first.")
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

def verify(data: Dict[str, Any], contract: Dict[str, Any]) -> Dict[str, Any]:
    trace=data["trace"]; bp=by_phase(trace); R={}
    baseline=EXPECTED_MATH

    # R1-R4: substrate chain
    R["R1"]= bp.get("c11_ingress") is not None
    R["R2"]= bp.get("c1_perception",{}).get("causal_parent",{}).get("phase")=="c11_ingress"
    R["R3"]= bp.get("c2_reality",{}).get("payload",{}).get("canonical_mutation") is True
    R["R4"]= bp.get("c3_knowledge",{}).get("payload",{}).get("lineage") is True

    # R5-R9: math substrate consumed at C4/C5/C8/C14
    c4=bp.get("c4_epistemics_with_math",{}).get("payload",{})
    c5=bp.get("c5_mathematics_substrate",{}).get("payload",{})
    c8=bp.get("c8_context_with_math",{}).get("payload",{})
    c14=bp.get("c14_governance_with_math",{}).get("payload",{})
    R["R5"]= c4.get("math_consumed") is True and c4.get("math_provider") is not None
    R["R6"]= c5 is not None and c5.get("substrate_role")=="foundational_epistemic_layer"
    R["R7"]= c8.get("math_consumed") is True and c8.get("math_provider") is not None
    R["R8"]= c14.get("math_consumed") is True and c14.get("math_provider") is not None
    R["R9"]= c14.get("math_is_authorization") is False and c14.get("governance_ref") is not None

    # R10-R13: CEL-1/CEL-2 via CapabilityGraph
    asc_d=bp.get("cel_discovery_asc",{}).get("payload",{})
    math_d=bp.get("cel_discovery_math",{}).get("payload",{})
    R["R10"]= asc_d.get("registry_query",{}).get("source")=="capability_graph"
    R["R11"]= math_d.get("registry_query",{}).get("source")=="capability_graph"
    R["R12"]= (asc_d.get("selection_source")=="registry_query"
               and math_d.get("selection_source")=="registry_query")
    phases=[e["phase"] for e in trace]
    def before(a,b): return a in phases and b in phases and phases.index(a)<phases.index(b)
    R["R13"]= before("c14_governance_with_math","cel_delegation_asc") and \
              before("c14_governance_with_math","cel_delegation_math")

    # R14-R15: math invoked through discovered provider + deterministic
    math_del=bp.get("cel_delegation_math",{}).get("payload",{})
    R["R14"]= math_del.get("implementation")==MATH_IMPL and math_del.get("status")=="EXECUTED"
    R["R15"]= data.get("math_result")==baseline

    # R16-R23: downstream consumption + continuity + egress + pollution
    R["R16"]= bp.get("c9_asc",{}).get("payload",{}).get("governed_result_consumed") is True
    R["R17"]= bp.get("c12_homeostasis",{}).get("payload",{}).get("monitored") is True
    cont=bp.get("c15_continuity",{}).get("payload",{})
    R["R18"]= cont.get("persisted") is True and cont.get("readback") is True
    egr=bp.get("c11_egress",{}).get("payload",{})
    R["R19"]= egr.get("mode")=="dry_run" and egr.get("governance_gate")=="allow"
    # R20: no hardcoded math path (all math consumed via discovered provider)
    R["R20"]= all(bp.get(p,{}).get("payload",{}).get("math_provider") is not None
                  for p in ["c4_epistemics_with_math","c8_context_with_math","c14_governance_with_math"])
    # R21: complete causal trace
    R["R21"]= not lineage_problems(trace)
    pol=bp.get("pollution_check",{}).get("payload",{})
    R["R22"]= pol.get("production_mutation") is False
    R["R23"]= pol.get("clean") is True

    return {"R":R, "lineage": lineage_problems(trace)}

def verdict(res: Dict[str, Any]) -> str:
    R=res["R"]
    dispositive=["R5","R6","R7","R8","R9","R10","R11","R12","R13","R14","R15","R21"]
    substrate_level=["R5","R6","R7","R8","R9"]
    if R["R22"] is False: return "BLOCKED"
    hard_fabrication = any(R[k] is False for k in ["R9","R12","R13","R14"])
    if hard_fabrication: return "NOT_CERTIFIED"
    if all(R[k] is True for k in dispositive) and all(R[k] is True for k in substrate_level):
        return "CERTIFIED"
    if all(R[k] is True for k in ["R1","R2","R3","R4","R10","R11","R21","R22","R23"]):
        return "QUALIFIED_PARTIAL"
    return "NOT_CERTIFIED"

def main():
    ap=argparse.ArgumentParser(); ap.add_argument("--contract",type=Path,default=CONTRACT)
    args=ap.parse_args()
    try:
        contract=load_certification_contract(args.contract); enforce_certification_bounds(contract)
    except (CertificationContractError, ActionNotCertificationError) as e:
        print(f"[CERT HALT] {e}"); sys.exit(1)
    except Exception as e:
        print(f"Exception: {e}"); sys.exit(1)
    try:
        data=load_trace()
    except FileNotFoundError as e:
        print(f"[BLOCKED] {e}"); sys.exit(2)

    res=verify(data, contract); status=verdict(res)
    out={"verdict": status,
         "checks": res["R"],
         "lineage_problems": res["lineage"],
         "trace_hash": hashlib.sha256(TRACE.read_bytes()).hexdigest(),
         "contract_hash": contract.get("contract_hash"),
         "bounded_claim": contract.get("bounded_proposition", ""),
         "post_certification_claim": contract.get("post_certification_claim", ""),
         "claims": {"math_is_substrate": status=="CERTIFIED",
                     "registry_fully_dynamic": False}}
    RESULTS.mkdir(parents=True,exist_ok=True)
    (RESULTS/"U0_recertification_result.json").write_text(json.dumps(out,indent=2))

    print("="*80); print(f"U0 Re-Certification VERDICT: {status}"); print("="*80)
    for i in range(1,24):
        k=f"R{i}"; v=res["R"].get(k)
        print(f"  [{'PASS' if v is True else 'FAIL'}] {k}")
    print(f"\n  lineage_problems: {res['lineage']}")
    print(f"  claims.math_is_substrate: {status=='CERTIFIED'}")
    print(f"  claims.registry_fully_dynamic: False (bounded)")

if __name__=="__main__":
    main()
