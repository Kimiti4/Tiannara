#!/usr/bin/env python3
"""
CEL-1: Registry-Driven Executive Delegation — Integration Certification
========================================================================
Certifies whether CEL discovers/selects/delegates capabilities dynamically
from the CapabilityRegistry, rather than via hardcoded objective->subsystem
dispatch. This is a CERTIFICATION, not a feature build.

Constitutional basis:
  - "Evidence Before Confidence. Never optimize for appearing correct."
  - "Bottleneck Discovery: finding bottlenecks is a primary capability."
  - "Prefer many specialized components cooperating through well-defined interfaces."

If CEL-1 FAILS, the failure is the evidence that drives a separate,
C14-gated remediation mission. We do not build the fix here.
"""

import sys, json, argparse
from pathlib import Path
from datetime import datetime, timezone
from typing import Dict, Any, List, Optional

sys.path.insert(0, str(Path(__file__).parent))
from certification_bounds import (
    load_certification_contract, enforce_certification_bounds,
    CertificationContractError, ActionNotCertificationError,
)

PROJECT_ROOT = Path(__file__).parent.parent.parent.parent
EVIDENCE_DIR = PROJECT_ROOT / "priv" / "tiannara" / "probes" / "evidence"
RESULTS_DIR  = PROJECT_ROOT / "priv" / "tiannara" / "probes" / "results"
CONTRACT_PATH = PROJECT_ROOT / "priv" / "tiannara" / "probes" / "contracts" / "CEL-1_registry_delegation.contract.yaml"

# Required delegation-trace phases (from the contract)
REQUIRED_TRACE_PHASES = [
    "objective_received", "registry_query", "candidate_set", "health_check",
    "ownership_check", "dependency_resolution", "selection", "governance_gate",
    "delegation", "execution", "result", "executive_memory_update",
]
# Phases whose ABSENCE is a hard failure (not just a gap)
HARD_REQUIRED = {"registry_query", "governance_gate"}

# ============================================================================
# Real Module Adapters — [REAL_MODULE_PATH_HERE]
# ============================================================================

# Real adapters — resolved via cel1_helpers.exs (executable paths, not doc matches)
# CapabilityRegistry: Tiannara.CEL.Services.CapabilityRegistry.all_providers/0
# find_provider: Tiannara.CEL.Services.CapabilityRegistry.find_provider/1
# MissionDirector: Tiannara.CEL.Services.MissionDirector.create_mission/3
import subprocess, os

def _run_helper(mode: str, arg: str = None) -> Dict[str, Any]:
    env = os.environ.copy()
    env["MIX_ENV"] = "test"
    cmd = ["mix", "run", "--no-compile", "--no-start", "priv/tiannara/probes/cel1_helpers.exs", mode]
    if arg is not None:
        cmd.append(arg)
    proc = subprocess.run(cmd, cwd=str(PROJECT_ROOT), env=env, capture_output=True, text=True, timeout=60)
    for line in (proc.stdout or "").splitlines():
        if line.startswith("CEL1HELPER_RESULT "):
            return json.loads(line[len("CEL1HELPER_RESULT "):])
    raise RuntimeError(f"Helper {mode} failed: {proc.stderr[-2000:]}")

def registry_list_capabilities() -> List[Dict[str, Any]]:
    data = _run_helper("list_capabilities")
    providers = data.get("providers", [])
    caps = []
    for p in providers:
        caps.append({
            "name": p.get("id"),
            "descriptor": p.get("capabilities", []),
            "interfaces": p.get("capabilities", []),
            "health": p.get("health"),
            "ownership": p.get("pid") is not None,
            "raw": p
        })
    return caps

def registry_detect_hardcoded_dispatch() -> Dict[str, Any]:
    data = _run_helper("detect_hardcoded")
    return data.get("dispatch_table", {}) if data.get("hardcoded_detected") else {}

def cel_submit_objective(objective: Dict[str, Any]) -> Dict[str, Any]:
    import json as _json
    return _run_helper("submit_objective", _json.dumps(objective))

# ============================================================================
# Evidence
# ============================================================================
def write_evidence(phase: str, trace_id: str, data: Dict[str, Any]) -> str:
    EVIDENCE_DIR.mkdir(parents=True, exist_ok=True)
    fn = f"CEL1_{trace_id}_{phase}.json"
    with open(EVIDENCE_DIR / fn, "w") as f:
        json.dump(data, f, indent=2)
    return f"priv/tiannara/probes/evidence/{fn}"

# ============================================================================
# Probe
# ============================================================================
class ProbeCEL1:
    def __init__(self, contract: Dict[str, Any]):
        self.contract = contract
        self.evidence_files: List[str] = []

    # ---- Phase A: Registry characterization (read-only) ----
    def phase_a(self) -> Dict[str, Any]:
        print("\n[Phase A] Registry characterization (read-only)...")
        capabilities = registry_list_capabilities()
        hardcoded = registry_detect_hardcoded_dispatch()

        print(f"  Registered capabilities: {len(capabilities)}")
        print(f"  Hardcoded dispatch entries: {len(hardcoded)}")

        # Select a novel test objective: one whose target capability is NOT
        # in the hardcoded dispatch table.
        novel_objective = self._select_novel_objective(capabilities, hardcoded)

        result = {
            "capabilities": capabilities,
            "hardcoded_dispatch": hardcoded,
            "novel_objective": novel_objective,
            "dynamic_testable": novel_objective is not None,
        }
        import uuid
        tid = str(uuid.uuid4())
        self.evidence_files.append(write_evidence("phaseA_registry", tid, result))
        return result

    def _select_novel_objective(self, capabilities, hardcoded) -> Optional[Dict[str, Any]]:
        """
        Pick a resident capability whose objective is NOT pre-mapped in the
        hardcoded dispatch table. If none exists, dynamic discovery cannot be
        tested (itself a finding).
        """
        hardcoded_targets = set(hardcoded.values())
        for cap in capabilities:
            # Build an objective from the capability's DESCRIPTOR, not its name.
            descriptor = cap.get("descriptor") or cap.get("interfaces") or []
            name = cap.get("name")
            if name not in hardcoded_targets and descriptor:
                return {
                    "objective": f"achieve:{descriptor[0]}",   # descriptor-driven, not name-driven
                    "target_capability": name,
                    "derived_from_descriptor": True,
                }
        return None  # every capability is hardcoded -> cannot test dynamic discovery

    # ---- Phase B: Dynamic delegation test ----
    def phase_b(self, novel_objective: Dict[str, Any]) -> Dict[str, Any]:
        print("\n[Phase B] Dynamic delegation test...")
        print(f"  Novel objective: {novel_objective['objective']}")
        print(f"  Expected target: {novel_objective['target_capability']}")

        cel_result = cel_submit_objective(novel_objective)
        trace = cel_result.get("trace", [])
        trace_phases = [step.get("phase") for step in trace]

        import uuid
        tid = str(uuid.uuid4())
        self.evidence_files.append(write_evidence("phaseB_delegation", tid, cel_result))

        return {"trace": trace, "trace_phases": trace_phases, "cel_result": cel_result}

    # ---- Phase C: Verdict ----
    def phase_c(self, phase_a: Dict[str, Any], phase_b: Dict[str, Any]) -> Dict[str, Any]:
        print("\n[Phase C] Verdict...")

        if not phase_a["dynamic_testable"]:
            return self._verdict("CANNOT_TEST_DYNAMIC_DISCOVERY",
                "Every capability is hardcoded for its objective; no novel test possible.",
                phase_a, phase_b)

        trace_phases = set(phase_b["trace_phases"])
        missing_hard = HARD_REQUIRED - trace_phases
        if missing_hard:
            return self._verdict("FAIL",
                f"Hard-required trace phases absent: {sorted(missing_hard)}. "
                f"registry_query absent => hardcoded dispatch; "
                f"governance_gate absent => C14 bypass.",
                phase_a, phase_b)

        missing_soft = set(REQUIRED_TRACE_PHASES) - trace_phases
        if missing_soft:
            return self._verdict("PARTIAL",
                f"Delegation occurred but trace incomplete; missing: {sorted(missing_soft)}.",
                phase_a, phase_b)

        # Verify the selected provider matches the descriptor-derived target
        sel = next((s for s in phase_b["trace"] if s.get("phase") == "selection"), {})
        selected = sel.get("selected_capability")
        if selected != phase_a["novel_objective"]["target_capability"]:
            return self._verdict("PARTIAL",
                f"Selection mismatch: expected {phase_a['novel_objective']['target_capability']}, got {selected}.",
                phase_a, phase_b)

        return self._verdict("PASS",
            "CEL discovered the capability via registry descriptor, selected it, "
            "gated it through governance, and delegated — no hardcoded shortcut.",
            phase_a, phase_b)

    def _verdict(self, status, reason, phase_a, phase_b) -> Dict[str, Any]:
        return {
            "status": status,
            "reason": reason,
            "bounded_proposition": self.contract["bounded_proposition"],
            "three_claims": self.contract["three_claims"],
            "evidence_files": self.evidence_files,
        }

    def run(self) -> Dict[str, Any]:
        print("=" * 80)
        print("CEL-1: Registry-Driven Executive Delegation — Integration Certification")
        print("=" * 80)
        try:
            a = self.phase_a()
            if not a["dynamic_testable"]:
                return self.phase_c(a, {"trace": [], "trace_phases": [], "cel_result": {}})
            b = self.phase_b(a["novel_objective"])
            return self.phase_c(a, b)
        except NotImplementedError as e:
            return {"status": "NOT_CONFIGURED", "error": str(e),
                    "evidence_files": self.evidence_files}
        except Exception as e:
            return {"status": "ERROR", "error": str(e),
                    "evidence_files": self.evidence_files}

# ============================================================================
# Main
# ============================================================================
def main():
    parser = argparse.ArgumentParser(description="CEL-1 Registry-Driven Delegation Certification")
    parser.add_argument("--contract", type=Path, default=CONTRACT_PATH)
    args = parser.parse_args()

    print("Loading immutable certification contract (auth-free)...")
    try:
        contract = load_certification_contract(args.contract)
        enforce_certification_bounds(contract)
    except (CertificationContractError, ActionNotCertificationError) as e:
        print(f"[CERT HALT] {e}")
        sys.exit(1)

    probe = ProbeCEL1(contract)
    result = probe.run()

    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    out = RESULTS_DIR / "CEL-1_registry_delegation_result.json"
    with open(out, "w") as f:
        json.dump(result, f, indent=2)

    print("\n" + "=" * 80)
    print(f"CEL-1 VERDICT: {result['status']}")
    print("=" * 80)
    print(f"Reason: {result.get('reason', result.get('error', ''))}")
    print(f"Evidence: {len(result.get('evidence_files', []))} file(s) -> {out.name}")

    if result["status"] == "FAIL":
        print("\n[NOTE] Dynamic delegation is NOT demonstrated. This is the evidence")
        print("that drives a SEPARATE C14-gated remediation mission. No fix here.")
    elif result["status"] == "PASS":
        print("\n[NOTE] CEL demonstrated registry-driven delegation for the tested path.")
        print("This certifies the executive edge; it does not claim universal coverage.")

if __name__ == "__main__":
    main()
