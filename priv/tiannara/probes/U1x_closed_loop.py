#!/usr/bin/env python3
"""
U1x: Full Closed-Loop Certification — verifier/orchestrator.

Consumes the trace emitted by u1x_helpers.exs (u1x_trace.json) and verifies the
seven U1x invariants. Produces a bounded verdict + evidence. Certification-only.

Constitutional basis:
  - "Evidence Before Confidence. Never optimize for appearing correct."
  - "Prefer many specialized components cooperating through well-defined interfaces."
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

PROJECT_ROOT = Path(__file__).parent.parent.parent.parent
CONTRACT_PATH = PROJECT_ROOT/"priv/tiannara/probes/contracts/U1x_closed_loop.contract.yaml"
TRACE_PATH    = PROJECT_ROOT/"priv/tiannara/probes/results/u1x_trace.json"
RESULTS_DIR   = PROJECT_ROOT/"priv/tiannara/probes/results"
EVIDENCE_DIR  = PROJECT_ROOT/"priv/tiannara/probes/evidence"

REQUIRED_PHASES = [
    "c11_ingress","c1_perception","c2_reality","c3_knowledge","c4_epistemics",
    "c5c6_reasoning","c8_context","c14_governance","cel_discovery","c9_asc",
    "c12_homeostasis","c15_continuity","c11_egress",
]

# ---------------------------------------------------------------------------
def load_trace(path: Path) -> Dict[str, Any]:
    if not path.exists():
        raise FileNotFoundError(
            f"{path} not found. Run `mix run priv/tiannara/probes/u1x_helpers.exs` first."
        )
    with open(path) as f:
        return json.load(f)

def by_phase(trace: List[Dict[str, Any]]) -> Dict[str, Dict[str, Any]]:
    return {env["phase"]: env for env in trace}

# ---------------------------------------------------------------------------
# Invariant checks
# ---------------------------------------------------------------------------
def check_lineage_continuity(trace: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Each phase's causal_parent must equal the previous phase's trace_id."""
    problems = []
    phases = [env["phase"] for env in trace]
    missing = [p for p in REQUIRED_PHASES if p not in phases]
    if missing:
        return {"pass": False, "reason": f"missing phases: {missing}"}
    # walk in required order
    ordered = [by_phase(trace)[p] for p in REQUIRED_PHASES]
    prev = None
    for env in ordered:
        parent = env["causal_parent"]["trace_id"]
        if prev is None:
            if parent is not None:
                problems.append(f"{env['phase']} should be root (parent null)")
        else:
            if parent != prev["trace_id"]:
                problems.append(f"{env['phase']} parent {parent} != prev {prev['trace_id']}")
        prev = env
    return {"pass": not problems, "problems": problems}

def check_cel_bridge(trace: List[Dict[str, Any]]) -> Dict[str, Any]:
    """cel_discovery must contain registry_query + selection derived from it."""
    env = by_phase(trace).get("cel_discovery")
    if not env:
        return {"pass": False, "reason": "cel_discovery phase absent"}
    payload = env.get("payload") or env
    # payload_hash refers to cel_payload; reconstruct expected keys from trace file
    # (the .exs writes cel_payload into the envelope payload; adapt to actual shape)
    rq = payload.get("registry_query")
    sel = payload.get("selection")
    if not rq:
        return {"pass": False, "reason": "registry_query absent -> hardcoded routing"}
    if not sel or sel.get("derived_from") != "registry_query":
        return {"pass": False, "reason": "selection not derived from registry_query"}
    return {"pass": True, "provider": sel.get("provider")}

def check_governance(trace: List[Dict[str, Any]]) -> Dict[str, Any]:
    """c14_governance must precede c9_asc; cel governance_gate present."""
    phases = [env["phase"] for env in trace]
    if "c14_governance" not in phases or "c9_asc" not in phases:
        return {"pass": False, "reason": "governance or asc phase missing"}
    if phases.index("c14_governance") > phases.index("c9_asc"):
        return {"pass": False, "reason": "c14_governance does not precede c9_asc"}
    cel = by_phase(trace).get("cel_discovery", {})
    gate = (cel.get("payload") or {}).get("governance_gate", {})
    if not gate.get("consulted"):
        return {"pass": False, "reason": "CEL governance_gate not consulted"}
    return {"pass": True}

def check_no_hardcoded_routing(trace, contract) -> Dict[str, Any]:
    """Selection must be descriptor-driven, not a static objective->provider map."""
    cel = by_phase(trace).get("cel_discovery", {})
    payload = cel.get("payload") or {}
    rq = payload.get("registry_query", {})
    sel = payload.get("selection", {})
    if not rq.get("descriptor"):
        return {"pass": False, "reason": "registry_query has no descriptor"}
    expected = contract["sub_tests"]["U1x_A"]["expected_provider"]
    if sel.get("provider") != expected:
        return {"pass": False, "reason": f"provider {sel.get('provider')} != expected {expected}"}
    return {"pass": True}

def check_continuity(trace) -> Dict[str, Any]:
    env = by_phase(trace).get("c15_continuity")
    if not env:
        return {"pass": False, "reason": "c15_continuity absent"}
    payload = env.get("payload") or {}
    if not (payload.get("persisted") and payload.get("readback")):
        return {"pass": False, "reason": "continuity persist/readback not demonstrated"}
    return {"pass": True}

def check_egress(trace, contract) -> Dict[str, Any]:
    env = by_phase(trace).get("c11_egress")
    if not env:
        return {"pass": False, "reason": "c11_egress absent"}
    payload = env.get("payload") or {}
    if payload.get("mode") != "dry_run":
        return {"pass": False, "reason": "egress not dry_run (would violate certification bound)"}
    if payload.get("governance_gate") != "allow":
        return {"pass": False, "reason": "egress not governance-gated"}
    return {"pass": True}

def check_pollution(trace_data) -> Dict[str, Any]:
    if not trace_data.get("pollution_check", False):
        return {"pass": False, "reason": "isolated namespace not clean (pollution)"}
    return {"pass": True}

# ---------------------------------------------------------------------------
def verdict(checks: Dict[str, Any], math_discoverable: bool) -> str:
    hard = ["lineage","cel_bridge","governance","no_hardcoded","continuity","egress","pollution"]
    if all(checks[k]["pass"] for k in hard):
        return "PASS"
    # FAIL if a critical integrity violation, else PARTIAL
    critical = ["cel_bridge","governance","no_hardcoded","lineage"]
    if any(not checks[k]["pass"] for k in critical):
        return "FAIL"
    return "PARTIAL"

def main():
    parser = argparse.ArgumentParser(description="U1x closed-loop verifier")
    parser.add_argument("--contract", type=Path, default=CONTRACT_PATH)
    parser.add_argument("--trace", type=Path, default=TRACE_PATH)
    args = parser.parse_args()

    try:
        contract = load_certification_contract(args.contract)
        enforce_certification_bounds(contract)
    except (CertificationContractError, ActionNotCertificationError) as e:
        print(f"[CERT HALT] {e}"); sys.exit(1)

    try:
        trace_data = load_trace(args.trace)
    except FileNotFoundError as e:
        print(f"[BLOCKED] {e}"); sys.exit(2)

    trace = trace_data["trace"]
    checks = {
        "lineage":       check_lineage_continuity(trace),
        "cel_bridge":    check_cel_bridge(trace),
        "governance":    check_governance(trace),
        "no_hardcoded":  check_no_hardcoded_routing(trace, contract),
        "continuity":    check_continuity(trace),
        "egress":        check_egress(trace, contract),
        "pollution":     check_pollution(trace_data),
    }
    math_discoverable = trace_data.get("math_discoverable", False)
    status = verdict(checks, math_discoverable)

    result = {
        "probe": "U1x_closed_loop",
        "status": status,
        "checks": checks,
        "math_discoverable": math_discoverable,
        "math_note": ("MATH_DISCOVERABLE" if math_discoverable
                      else "MATH_NOT_REGISTERED (next gap -> Constitutional Math v1 / CEL-2)"),
        "bounded_proposition": contract["bounded_proposition"],
    }

    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    EVIDENCE_DIR.mkdir(parents=True, exist_ok=True)
    out = RESULTS_DIR/"U1x_closed_loop_result.json"
    out.write_text(json.dumps(result, indent=2))
    (EVIDENCE_DIR/"U1x_checks.json").write_text(json.dumps(checks, indent=2))

    print("="*80)
    print(f"U1X VERDICT: {status}")
    print("="*80)
    for k, v in checks.items():
        mark = "PASS" if v["pass"] else "FAIL"
        extra = v.get("reason") or ", ".join(v.get("problems", [])) or ""
        print(f"  [{mark}] {k:12} {extra}")
    print(f"  math_substrate: {result['math_note']}")
    print(f"  result -> {out}")

if __name__ == "__main__":
    main()
