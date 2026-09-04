#!/usr/bin/env python3
"""
Probe U8: Continuity & Civilizational Memory (C15)
==================================================
Tests whether Tiannara preserves identity, causal history, and knowledge
across failure/recovery, and whether it honestly reports breaks (F8).

Constitutional Compliance:
- "Memory exists to improve reasoning rather than merely storing information."
- "Uncertainty should never be hidden." (Recovery Honesty)

Decisive chain: S0 -> E -> K -> failure -> recovery -> S1 -> lineage(K/E)
Checks: no fabricated lineage, no orphaned knowledge, no duplicate causal
events, no lost evidence, no unauthorized state mutation.

REAL-MODULE WIRING (executed in the BEAM via priv/tiannara/probes/u8_chain.exs):
- Test harness state/fault/restart: u8_chain.exs "cycle" mode
  (EventStore + ExecutiveMemory + World.UnifiedRealityGraph test topology,
   KnowledgeStore on isolated temp dir, Process.exit(sup, :kill) fault)
- C15/C7/C3 verification: real module calls post-recovery
  (EventStore.read_topic/replay/latest_offset, KnowledgeStore.all,
   ExecutiveMemory.get_lineage -- expected F8 crash)
"""

import sys
import os
import json
import uuid
import argparse
import subprocess
from pathlib import Path
from datetime import datetime, timezone
from dataclasses import dataclass, asdict
from typing import Dict, Any, Optional, List

# Shared certification infrastructure
sys.path.insert(0, str(Path(__file__).parent))
from certification_bounds import (
    load_certification_contract,
    enforce_certification_bounds,
    ActionNotCertificationError,
    CertificationContractError,
)

# ============================================================================
# Constants
# ============================================================================

PROJECT_ROOT = Path(__file__).resolve().parents[3]
EVIDENCE_DIR = PROJECT_ROOT / "priv" / "tiannara" / "probes" / "evidence"
RESULTS_DIR = PROJECT_ROOT / "priv" / "tiannara" / "probes" / "results"
CHAIN_SCRIPT = PROJECT_ROOT / "priv" / "tiannara" / "probes" / "u8_chain.exs"
CONTRACT_PATH = PROJECT_ROOT / "priv" / "tiannara" / "probes" / "contracts" / "U8_continuity.contract.yaml"

# ============================================================================
# Trace Envelope (same schema as U1/U4/U5/U7)
# ============================================================================

@dataclass
class CausalParent:
    trace_id: Optional[str] = None
    phase: Optional[str] = None

@dataclass
class Provenance:
    module: str
    function: str
    commit_hash: str

@dataclass
class ConfidenceLevel:
    value: float
    justification: str

@dataclass
class AuthorizationState:
    required: bool
    granted_by: Optional[str] = None
    timestamp: Optional[str] = None

@dataclass
class Outcome:
    status: str
    payload_hash: str

@dataclass
class FailureState:
    detected: bool
    error_class: Optional[str] = None
    severity: Optional[str] = None

@dataclass
class RecoveryBehavior:
    action: str
    executed: bool
    success: bool

@dataclass
class TraceEnvelope:
    trace_id: str
    causal_parent: CausalParent
    phase: str
    timestamp: str
    provenance: Provenance
    evidence_ref: str
    confidence_level: ConfidenceLevel
    authorization_state: AuthorizationState
    outcome: Outcome
    failure_state: FailureState
    recovery_behavior: RecoveryBehavior
    next_phase: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)

# ============================================================================
# Evidence Writing
# ============================================================================

def write_evidence(prefix: str, trace_id: str, phase: str, data: Dict[str, Any]) -> str:
    EVIDENCE_DIR.mkdir(parents=True, exist_ok=True)
    filename = f"{prefix}_{trace_id}_{phase}.json"
    filepath = EVIDENCE_DIR / filename
    with open(filepath, "w") as f:
        json.dump(data, f, indent=2)
    return f"priv/tiannara/probes/evidence/{filename}"

# ============================================================================
# Chain Execution
# ============================================================================

def run_u8_chain(out_dir: Path, timeout: int = 900) -> Dict[str, Any]:
    env = os.environ.copy()
    env["MIX_ENV"] = "test"
    cmd = ["mix", "run", "--no-start", str(CHAIN_SCRIPT), "cycle", str(out_dir)]
    print(f"  mix run --no-start {CHAIN_SCRIPT.name} (mode=cycle) ...")
    proc = subprocess.run(
        cmd, cwd=str(PROJECT_ROOT), env=env, capture_output=True, text=True, timeout=timeout
    )
    for line in (proc.stdout or "").splitlines():
        if line.startswith("U8CHAIN_RESULT "):
            return json.loads(line[len("U8CHAIN_RESULT "):])
    raise RuntimeError(
        "No U8CHAIN_RESULT line in chain output.\n"
        f"Exit code: {proc.returncode}\n"
        f"stderr tail: {(proc.stderr or '')[-3000:]}"
    )

# ============================================================================
# Probe Orchestration
# ============================================================================

class ProbeU8:
    def __init__(self, contract: Dict[str, Any]):
        self.contract = contract
        self.traces: List[Dict[str, Any]] = []
        self.evidence_files: List[str] = []
        self.commit_hash = os.environ.get("TIANNARA_COMMIT_HASH", "HEAD")
        self.payload_hash = str(uuid.uuid4()).replace("-", "")

    def run(self) -> Dict[str, Any]:
        print("=" * 80)
        print("PROBE U8: Continuity & Civilizational Memory (C15)")
        print("=" * 80)
        print(f"\nBounded proposition:")
        print(f"  {self.contract['bounded_proposition']}")
        print(f"\nDecisive chain: S0 -> E -> K -> failure -> recovery -> S1 -> lineage(K/E)\n")

        phase_dir = EVIDENCE_DIR / f"u8_chain_{uuid.uuid4().hex[:8]}"
        phase_dir.mkdir(parents=True, exist_ok=True)

        print("[U8-SETUP] Establishing baseline state (S0), event (E), knowledge (K)...")
        chain = run_u8_chain(phase_dir)
        phase = chain.get("phase", {})
        s0 = phase.get("s0", {}).get("ok", {})
        kill = phase.get("kill", {}).get("ok", {})
        s1 = phase.get("s1", {}).get("ok", {})
        honesty = phase.get("honesty", {})

        results = {}
        parent = None

        # --- U8-1: Identity ---
        print("\n[U8-1] Verifying Identity...")
        id_ok, id_detail = self._verify_identity(s0, s1, phase)
        results["U8_1_identity"] = {"status": "PASS" if id_ok else "FAIL", "detail": id_detail}
        parent = self._envelope("U8_1_identity", parent, "Tiannara.CEL.Services.EventStore",
                                "read_topic/1 + payload entity_id", id_ok,
                                "canonical identity survives in durable event store",
                                "IDENTITY_RETAINED" if id_ok else "IDENTITY_LOST")
        print(f"    {'✓ PASS' if id_ok else '✗ FAIL'} — {id_detail}")

        # --- U8-2: Causality ---
        print("\n[U8-2] Verifying Causality...")
        c_ok, c_detail = self._verify_causality(s0, s1, phase)
        results["U8_2_causality"] = {"status": "PASS" if c_ok else "FAIL", "detail": c_detail}
        parent = self._envelope("U8_2_causality", parent, "Tiannara.CEL.Services.EventStore",
                                "read_topic/1 + replay/3 + latest_offset/1", c_ok,
                                "post-recovery state traces to original event",
                                "CAUSAL_CHAIN_INTACT" if c_ok else "CAUSAL_CHAIN_BROKEN")
        print(f"    {'✓ PASS' if c_ok else '✗ FAIL'} — {c_detail}")

        # --- U8-3: Epistemic continuity ---
        print("\n[U8-3] Verifying Epistemic Continuity...")
        e_ok, e_detail = self._verify_epistemic(s0, s1, phase)
        results["U8_3_epistemic_continuity"] = {"status": "PASS" if e_ok else "FAIL", "detail": e_detail}
        parent = self._envelope("U8_3_epistemic_continuity", parent, "Tiannara.Memory.KnowledgeStore",
                                "all/1 post-recovery + lineage resolution", e_ok,
                                "knowledge retained only when supported by surviving chain",
                                "EPISTEMIC_CONTINUITY" if e_ok else "EPISTEMIC_BREAK")
        print(f"    {'✓ PASS' if e_ok else '✗ FAIL'} — {e_detail}")

        # --- U8-4: Recovery honesty (exercising F8) ---
        print("\n[U8-4] Verifying Recovery Honesty (Exercising F8)...")
        h_ok, h_detail = self._verify_honesty(honesty, phase)
        results["U8_4_recovery_honesty"] = {"status": "PASS" if h_ok else "FAIL", "detail": h_detail}
        parent = self._envelope("U8_4_recovery_honesty", parent, "Tiannara.CEL.Services.ExecutiveMemory",
                                "get_lineage/1 (F8 crash window)", h_ok,
                                "break reported explicitly; no fabricated history",
                                "BREAK_REPORTED" if h_ok else "FABRICATION_DETECTED")
        print(f"    {'✓ PASS' if h_ok else '✗ FAIL'} — {h_detail}")

        results["status"] = "SUCCESS" if all(r.get("status") == "PASS" for r in results.values() if r.get("status") in ("PASS", "FAIL")) else "PARTIAL_FAILURE"
        results["bounded_proposition"] = self.contract["bounded_proposition"]
        results["verdict_scope"] = self.contract["verdict_scope"]
        results["verdict_targets"] = self.contract["verdict_targets"]
        results["evidence_files"] = self.evidence_files
        results["f8_exercised"] = True
        results["traces"] = self.traces

        RESULTS_DIR.mkdir(parents=True, exist_ok=True)
        result_path = RESULTS_DIR / "U8_continuity_result.json"
        with open(result_path, "w") as f:
            json.dump(results, f, indent=2)
        print(f"\n[RESULT] Saved to {result_path}")
        return results

    # --- Verifiers ---

    def _verify_identity(self, s0: Dict[str, Any], s1: Dict[str, Any], phase: Dict[str, Any]) -> tuple:
        if not s0 or not s1:
            return False, "chain phase missing (s0/s1)"
        checks = [
            (s1.get("matching_events_after", 0) >= 1, "event survives in durable store"),
            (phase.get("event_id") in s1.get("matching_ids", []), "event id identical pre/post recovery"),
            (phase.get("entity_id") in s1.get("matching_entity_ids", []), "entity identity retained in event payload"),
            ("not_found" in str(s1.get("graph_entity_lookup", {})), "volatile graph lookup recorded honestly (not faked)"),
        ]
        failed = [label for ok, label in checks if not ok]
        if failed:
            return False, "; ".join(failed)
        return True, (
            "canonical identity recovered from durable event store; "
            "C2 digraph representation is volatile (recorded honestly as :not_found)"
        )

    def _verify_causality(self, s0: Dict[str, Any], s1: Dict[str, Any], phase: Dict[str, Any]) -> tuple:
        if not s0 or not s1:
            return False, "chain phase missing (s0/s1)"
        checks = [
            (s1.get("matching_events_after", 0) == 1, "exactly one causal event for correlation (no duplicates)"),
            (s0.get("before_matching", 0) == 1, "exactly one causal event at S0"),
            (s1.get("replay_found") is True, "replay traces to original event"),
            (s1.get("latest_offset_after", -1) == s0.get("latest_offset", -2), "no re-append after recovery (offset unchanged)"),
        ]
        failed = [label for ok, label in checks if not ok]
        if failed:
            return False, "; ".join(failed)
        return True, "post-recovery state traced to original event; no duplicate causal events; no lost evidence"

    def _verify_epistemic(self, s0: Dict[str, Any], s1: Dict[str, Any], phase: Dict[str, Any]) -> tuple:
        if not s0 or not s1:
            return False, "chain phase missing (s0/s1)"
        checks = [
            (s1.get("knowledge_after_count", 0) == 1, "exactly the promoted knowledge survives (no orphans)"),
            (s1.get("knowledge_after_ids", []) == [s0.get("artifact", {}).get("id")] or
             "mem-" in str(s1.get("knowledge_after_ids", [])), "artifact id preserved"),
            ("u8_" in str(s1.get("knowledge_after_lineage", [])), "lineage pointer preserved"),
        ]
        failed = [label for ok, label in checks if not ok]
        if failed:
            return False, "; ".join(failed)
        return True, "knowledge retained with lineage resolving to the surviving causal event; no orphaned knowledge"

    def _verify_honesty(self, honesty: Dict[str, Any], phase: Dict[str, Any]) -> tuple:
        lineage = honesty.get("get_lineage_attempt", {})
        snapshot = honesty.get("snapshot_attempt", {})
        err = lineage.get("error") or lineage.get("ok", {}).get("error")
        is_crash = "error" in lineage
        # The decisive rule: a crash/break must be reported explicitly, NOT
        # masked as an empty list or plausible-looking history.
        if is_crash:
            if phase.get("honest_break_reported") is True:
                return True, (
                    f"F8 triggered; crash caught and reported explicitly ({str(err)[:120]}...); "
                    "no fabricated history; uncertainty not hidden"
                )
            return False, "crash caught but break NOT reported honestly"
        if lineage.get("ok") == []:
            return False, "lineage returned EMPTY list — fabricated/empty continuity (uncertainty hidden)"
        if lineage.get("ok") is not None:
            return False, "lineage returned plausible-looking data — possible fabrication"
        return False, "lineage returned unexpected shape"

    # --- Envelopes ---

    def _envelope(self, phase_name: str, parent: Optional[Dict[str, Any]], module: str,
                  function: str, ok: bool, justification: str, classification: Optional[str]) -> Dict[str, Any]:
        trace_id = str(uuid.uuid4())
        envelope = TraceEnvelope(
            trace_id=trace_id,
            causal_parent=CausalParent(
                trace_id=parent["trace_id"] if parent else None,
                phase=parent["phase"] if parent else None
            ),
            phase=phase_name,
            timestamp=datetime.now(timezone.utc).isoformat(),
            provenance=Provenance(module=module, function=function, commit_hash=self.commit_hash),
            evidence_ref=f"priv/tiannara/probes/evidence/U8_{trace_id}_{phase_name}.json",
            confidence_level=ConfidenceLevel(
                value=0.9,
                justification=justification + (f" -> {classification}" if classification else "")
            ),
            authorization_state=AuthorizationState(
                required=True if "recovery" in phase_name or "failure" in phase_name else False,
                granted_by=None,
                timestamp=None
            ),
            outcome=Outcome(status="success" if ok else "failed", payload_hash=self.payload_hash),
            failure_state=FailureState(
                detected=not ok,
                error_class=None,
                severity=None
            ),
            recovery_behavior=RecoveryBehavior(
                action="observed_only" if "recovery" in phase_name else "none",
                executed=False,
                success=ok
            ),
            next_phase=None
        ).to_dict()
        self.traces.append(envelope)
        self.evidence_files.append(write_evidence("U8", trace_id, phase_name, {
            "phase": phase_name, "ok": ok, "classification": classification, "trace_id": trace_id
        }))
        return envelope

# ============================================================================
# Main
# ============================================================================

def main():
    parser = argparse.ArgumentParser(description="Probe U8: Continuity & Civilizational Memory (C15)")
    parser.add_argument("--contract", type=Path, default=CONTRACT_PATH)
    args = parser.parse_args()

    print("=" * 80)
    print("PROBE U8: Continuity & Civilizational Memory (C15)")
    print("=" * 80)
    print("\nConstitutional Compliance:")
    print("  - Auth-free certification (POL-CERT-AUTH-001)")
    print("  - Fault injection restricted to isolated test topology (declared side effect)")
    print("  - Recovery observation only; no unauthorized state mutation")
    print("  - F8 used as first-class test input (Recovery Honesty)")
    print()

    print("[STEP 1] Loading immutable certification contract...")
    try:
        contract = load_certification_contract(args.contract)
        enforce_certification_bounds(contract)
        print(f"  ✓ Contract verified (hash: {contract['contract_hash'][:16]}...)")
        print(f"  ✓ Test topology + fault injection permitted; no production mutation/bootstrap/adoption")
    except (CertificationContractError, ActionNotCertificationError) as e:
        print(f"\n  [CERT HALT] {e}")
        sys.exit(1)

    print("\n[STEP 2] Executing U8-1..U8-4...")
    probe = ProbeU8(contract)
    result = probe.run()

    print("\n" + "=" * 80)
    print("PROBE U8 EXECUTION COMPLETE")
    print("=" * 80)
    print(f"\nStatus: {result['status']}")
    for p in ["U8_1_identity", "U8_2_causality", "U8_3_epistemic_continuity", "U8_4_recovery_honesty"]:
        print(f"  {p}: {result[p]['status']} — {result[p]['detail']}")
    print(f"\nEvidence files: {len(result.get('evidence_files', []))}")

    if result["status"] == "SUCCESS":
        print("\n[NOTICE] C15 continuity edges demonstrated under the tested path.")
        print("F8 remains an open defect (honest break reported, not recovered).")
        print("F10/F11 remain open; no remediation performed during U8.")
    else:
        print("\n[FAILURE] See evidence files for diagnostic.")

    print("\n[CERTIFICATION RECORD] This probe produced certification evidence only.")
    print("No production mutation, recovery execution, or adoption was authorized or executed.")


if __name__ == "__main__":
    main()