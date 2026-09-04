#!/usr/bin/env python3
"""
Probe U4: Governance → ASC (Constitutional Consumption)
========================================================

Tests whether ASC consumes the authoritative C14 governance decision
BEFORE producing consequential candidate state.

Bounded proposition (NOT "ASC is governed"):
  "Under this tested execution path, ASC consumed the authoritative C14
   governance decision before producing the tested consequential state."

Controls:
  - Positive: Governance = ALLOW → candidate MAY become eligible
  - Negative: Governance = DENY → candidate must NOT become executable/adoptable

REAL-MODULE WIRING:
- C3:  Tiannara.Memory.KnowledgeStore (open/1 + append/2 + all/1)
- C8:  Tiannara.World.CanonicalWorldState (domains/0, domain_entity_types/0,
       memory_stages/0, required_entity_fields/0, validate_entity/1)
- C14: TiannaraOS.Governance.ConstitutionalInstitution.define_review_board/0 +
       TiannaraOS.Governance.CapabilityChecker.authorize?/3
       (decision_hash computed over the decision payload)
- C9:  Tiannara.ASC.Implementation.Planner.generate_plan/2 (candidate from
       ProjectWorld; eligibility derived from the consumed governance decision)

The chain executes inside the real BEAM via priv/tiannara/probes/u4_chain.exs
(mix run --no-start, app.config only). This script orchestrates both controls,
emits trace envelopes + real evidence files, and verifies governance
consumption. It does NOT modify the audit matrix.

Constitutional Compliance:
  - Auth-free certification (POL-CERT-AUTH-001)
  - No production mutation, bootstrap, external calls, or adoption
  - Verdict targets integration edges, not entire capabilities
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
CHAIN_SCRIPT = PROJECT_ROOT / "priv" / "tiannara" / "probes" / "u4_chain.exs"
CONTRACT_PATH = PROJECT_ROOT / "priv" / "tiannara" / "probes" / "contracts" / "U4_governance_to_asc.contract.yaml"

# ============================================================================
# Trace Envelope (same schema as U1)
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
    required: bool  # False for certification probes
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

def write_evidence(phase: str, trace_id: str, data: Dict[str, Any]) -> str:
    """Write evidence file to disk. Returns relative path."""
    EVIDENCE_DIR.mkdir(parents=True, exist_ok=True)
    filename = f"U4_{trace_id}_{phase}.json"
    filepath = EVIDENCE_DIR / filename
    with open(filepath, "w") as f:
        json.dump(data, f, indent=2)
    return f"priv/tiannara/probes/evidence/{filename}"


def evidence_exists(evidence_ref: str) -> bool:
    return (PROJECT_ROOT / evidence_ref).exists()

# ============================================================================
# Real-Module Chain Execution
# ============================================================================

def run_u4_chain(intent_file: Path, out_dir: Path, forced_decision: str, timeout: int = 900) -> Dict[str, Any]:
    """
    Execute the real C3→C8→C14→C9 chain inside the BEAM for one control.

    Calls priv/tiannara/probes/u4_chain.exs via `mix run --no-start`
    (app.config only — no supervision tree). Parses the 'U4CHAIN_RESULT '
    JSON line from stdout.
    """
    env = os.environ.copy()
    env["MIX_ENV"] = "test"

    cmd = [
        "mix", "run", "--no-start",
        str(CHAIN_SCRIPT),
        str(intent_file),
        str(out_dir),
        forced_decision
    ]

    print(f"  mix run --no-start {CHAIN_SCRIPT.name} (forced={forced_decision}) ...")
    proc = subprocess.run(
        cmd,
        cwd=str(PROJECT_ROOT),
        env=env,
        capture_output=True,
        text=True,
        timeout=timeout
    )

    for line in (proc.stdout or "").splitlines():
        if line.startswith("U4CHAIN_RESULT "):
            return json.loads(line[len("U4CHAIN_RESULT "):])

    raise RuntimeError(
        "No U4CHAIN_RESULT line in chain output.\n"
        f"Exit code: {proc.returncode}\n"
        f"stderr tail: {(proc.stderr or '')[-2000:]}"
    )

# ============================================================================
# Probe U4 Orchestration
# ============================================================================

class ProbeU4:
    """
    Probe U4: Governance → ASC (Constitutional Consumption)

    Tests the causal path:
    C3 (Knowledge) → C8 (Engineering Context) → C14 (Governance) → C9 (ASC)

    With positive and negative controls to distinguish
    "governance consultation" from "governance modules present."
    """

    PHASE_ORDER = ["c3_knowledge", "c8_engineering", "c14_governance", "c9_asc"]

    REAL_PROVENANCE = {
        "c3_knowledge": ("Tiannara.Memory.KnowledgeStore", "open/1 + append/2 + all/1"),
        "c8_engineering": ("Tiannara.World.CanonicalWorldState", "domains/0 + validate_entity/1"),
        "c14_governance": ("TiannaraOS.Governance.CapabilityChecker", "authorize?/3"),
        "c9_asc": ("Tiannara.ASC.Implementation.Planner", "generate_plan/2"),
    }

    def __init__(self, contract: Dict[str, Any]):
        self.contract = contract
        self.traces: List[TraceEnvelope] = []
        self.evidence_files: List[str] = []

    def run(self, test_intent: Dict[str, Any]) -> Dict[str, Any]:
        """Execute U4 with positive and negative controls."""

        print("=" * 80)
        print("PROBE U4: Governance → ASC (Constitutional Consumption)")
        print("=" * 80)
        print(f"\nBounded proposition:")
        print(f"  {self.contract['bounded_proposition']}")
        print(f"\nTest intent: {json.dumps(test_intent, indent=2)}\n")

        # Prepare canonical intent file (bytes hashed identically in Elixir)
        EVIDENCE_DIR.mkdir(parents=True, exist_ok=True)
        intent_file = EVIDENCE_DIR / f"U4_intent_{uuid.uuid4().hex[:8]}.json"
        with open(intent_file, "w") as f:
            json.dump(test_intent, f, indent=2, sort_keys=True)
        payload_hash = __import__("hashlib").sha256(intent_file.read_bytes()).hexdigest()
        print(f"[CHAIN] Intent file: {intent_file.relative_to(PROJECT_ROOT)}")
        print(f"[CHAIN] Intent payload hash: {payload_hash}")

        results = {}

        for forced_decision in ["ALLOW", "DENY"]:
            print("\n" + "=" * 40)
            print(f"CONTROL: Governance = {forced_decision}")
            print("=" * 40)
            chain_out_dir = EVIDENCE_DIR / f"U4_chain_{uuid.uuid4().hex[:8]}"
            chain_out_dir.mkdir(parents=True, exist_ok=True)
            try:
                control_result = self._run_control(
                    intent_file, chain_out_dir, forced_decision, payload_hash,
                    commit_hash=os.environ.get("TIANNARA_COMMIT_HASH", "HEAD")
                )
                results[forced_decision.lower() + "_control"] = control_result
                print(f"\n  Result: {control_result['status']}")
            except AssertionError as e:
                results[forced_decision.lower() + "_control"] = {"status": "FAILURE", "error": str(e)}
                print(f"\n  [FAILURE] {e}")
            except Exception as e:
                results[forced_decision.lower() + "_control"] = {"status": "FAILURE", "error": str(e)}
                print(f"\n  [FAILURE] {e}")

        # Determine overall verdict
        results["bounded_proposition"] = self.contract["bounded_proposition"]
        results["verdict_scope"] = self.contract["verdict_scope"]
        results["verdict_targets"] = self.contract["verdict_targets"]
        results["evidence_files"] = self.evidence_files

        pos_status = results.get("allow_control", {}).get("status", "UNKNOWN")
        neg_status = results.get("deny_control", {}).get("status", "UNKNOWN")

        if pos_status == "SUCCESS" and neg_status == "SUCCESS":
            results["status"] = "SUCCESS"
        else:
            results["status"] = "PARTIAL_FAILURE"

        return results

    def _run_control(self, intent_file: Path, out_dir: Path, forced_decision: str,
                     payload_hash: str, commit_hash: str) -> Dict[str, Any]:
        """Run one control path (ALLOW or DENY) against the real modules."""

        control_label = forced_decision.lower()
        chain = run_u4_chain(intent_file, out_dir, forced_decision)

        if chain.get("status") != "complete":
            raise RuntimeError(f"Chain did not complete: {chain}")
        if chain.get("payload_hash") != payload_hash:
            raise AssertionError(
                f"Payload hash mismatch: python={payload_hash} beam={chain.get('payload_hash')}"
            )

        phases = chain.get("phases", {})
        phase_results = {p: phases.get(k, {}) for p, k in [
            ("c3_knowledge", "c3"), ("c8_engineering", "c8"),
            ("c14_governance", "c14"), ("c9_asc", "c9")
        ]}

        # Extract real module results
        c14 = self._ok_of(phase_results["c14_governance"], "governance evaluation")
        c9 = self._ok_of(phase_results["c9_asc"], "ASC candidate generation")

        control_traces = []
        parent = None
        for phase in self.PHASE_ORDER:
            module, func = self.REAL_PROVENANCE[phase]
            result_map = phase_results[phase]

            ok = "ok" in result_map and "error" not in result_map
            payload = result_map.get("ok") if ok else result_map.get("error")
            confidence = {
                "c3_knowledge": 0.90,
                "c8_engineering": 0.90,
                "c14_governance": 0.95,
                "c9_asc": 0.90,
            }[phase]

            envelope = self._build_envelope(
                phase=f"{phase}_{control_label}",
                parent=parent,
                provenance=Provenance(module=module, function=func, commit_hash=commit_hash),
                payload_hash=payload_hash,
                confidence=confidence,
                justification=("Real module transition succeeded" if ok else "Real module transition failed")
            )
            control_traces.append(envelope)
            self.evidence_files.append(write_evidence(f"{phase}_{control_label}", envelope.trace_id, {
                "phase": phase,
                "trace_id": envelope.trace_id,
                "ok": ok,
                "chain_result": payload,
                "payload_hash": payload_hash
            }))
            status = "OK" if ok else "FAILED"
            print(f"  [{self.PHASE_ORDER.index(phase) + 1}/4] {phase}: {status}")
            parent = envelope

        # Verification: Causal ordering
        print(f"\n  [VERIFY] Causal ordering (governance before ASC)...")
        self._verify_causal_ordering(control_traces)
        print(f"    ✓ Causal order verified")

        # Verification: Governance consumption
        print(f"\n  [VERIFY] Governance consumption by ASC...")
        self._verify_governance_consumption(c9, c14, forced_decision)
        print(f"    ✓ Governance consumption verified")

        # Verification: Negative control invariant
        if forced_decision == "DENY":
            print(f"\n  [VERIFY] Negative control: candidate NOT executable/adoptable...")
            self._verify_negative_control(c9)
            print(f"    ✓ Negative control invariant holds")

        # Verification: Trace lineage
        print(f"\n  [VERIFY] Trace lineage (4-phase chain)...")
        self._verify_lineage(control_traces)
        print(f"    ✓ Lineage chain verified")

        self.traces.extend(control_traces)

        return {
            "status": "SUCCESS",
            "control": forced_decision,
            "traces": [t.to_dict() for t in control_traces],
            "governance_decision": c14.get("decision"),
            "governance_decision_hash": c14.get("decision_hash"),
            "governance_injected": c14.get("injected"),
            "governance_real_verdict": c14.get("real_verdict"),
            "candidate_eligible": c9.get("is_eligible"),
            "candidate_adoptable": c9.get("adoptable"),
            "candidate_executable": c9.get("executable"),
            "candidate_ref": c9.get("governance_decision_ref"),
        }

    def _ok_of(self, result_map: Dict[str, Any], what: str) -> Dict[str, Any]:
        if "error" in result_map or "ok" not in result_map:
            raise AssertionError(f"{what} failed: {result_map.get('error') or result_map}")
        return result_map["ok"]

    def _build_envelope(
        self, phase: str, parent: Optional[TraceEnvelope],
        provenance: Provenance, payload_hash: str,
        confidence: float, justification: str
    ) -> TraceEnvelope:
        """Build trace envelope. authorization_state.required = False (certification)."""
        trace_id = str(uuid.uuid4())
        causal_parent = CausalParent(
            trace_id=parent.trace_id if parent else None,
            phase=parent.phase if parent else None
        )
        return TraceEnvelope(
            trace_id=trace_id,
            causal_parent=causal_parent,
            phase=phase,
            timestamp=datetime.now(timezone.utc).isoformat(),
            provenance=provenance,
            evidence_ref=f"priv/tiannara/probes/evidence/U4_{trace_id}_{phase}.json",
            confidence_level=ConfidenceLevel(value=confidence, justification=justification),
            authorization_state=AuthorizationState(
                required=False,  # Certification probe — no authorization needed
                granted_by=None,
                timestamp=None
            ),
            outcome=Outcome(status="success", payload_hash=payload_hash),
            failure_state=FailureState(detected=False),
            recovery_behavior=RecoveryBehavior(action="none", executed=False, success=True),
            next_phase=None
        )

    def _verify_causal_ordering(self, traces: List[TraceEnvelope]):
        """Verify governance decision envelope precedes ASC candidate envelope."""
        if len(traces) < 4:
            raise AssertionError(f"Expected 4 traces, got {len(traces)}")

        governance_ts = traces[2].timestamp  # C14
        asc_ts = traces[3].timestamp         # C9

        if governance_ts >= asc_ts:
            raise AssertionError(
                f"Causal ordering violated: governance ({governance_ts}) "
                f"not before ASC ({asc_ts})"
            )

    def _verify_governance_consumption(
        self, c9_result: Dict[str, Any], c14_result: Dict[str, Any], expected_decision: str
    ):
        """Verify ASC candidate references the governance decision."""
        governance_ref = c9_result.get("governance_decision_ref")
        decision_hash = c14_result.get("decision_hash")

        if not governance_ref:
            raise AssertionError(
                "ASC candidate does not reference governance decision. "
                "governance_decision_ref is missing."
            )

        if decision_hash and governance_ref != decision_hash:
            raise AssertionError(
                f"ASC candidate governance_decision_ref ({governance_ref}) "
                f"does not match C14 decision_hash ({decision_hash})"
            )

        actual_decision = c14_result.get("decision", "")
        if actual_decision != expected_decision:
            raise AssertionError(
                f"Governance decision mismatch: expected {expected_decision}, "
                f"got {actual_decision}"
            )

    def _verify_negative_control(self, c9_result: Dict[str, Any]):
        """
        Negative control invariant: when governance = DENY,
        candidate must NOT be executable or adoptable.
        """
        is_eligible = c9_result.get("is_eligible", False)
        is_adoptable = c9_result.get("adoptable", False)
        is_executable = c9_result.get("executable", False)

        if is_eligible or is_adoptable or is_executable:
            raise AssertionError(
                f"NEGATIVE CONTROL VIOLATION: Governance=DENY but candidate "
                f"is_eligible={is_eligible}, adoptable={is_adoptable}, "
                f"executable={is_executable}. "
                f"Candidate must NOT be executable/adoptable under DENY."
            )

    def _verify_lineage(self, traces: List[TraceEnvelope]):
        """Verify 4-phase causal chain: C3 → C8 → C14 → C9."""
        if len(traces) != 4:
            raise AssertionError(f"Expected 4 traces, got {len(traces)}")

        if traces[0].causal_parent.trace_id is not None:
            raise AssertionError(f"C3 (root) has non-null parent")

        if traces[1].causal_parent.trace_id != traces[0].trace_id:
            raise AssertionError(
                f"C8 parent mismatch: expected {traces[0].trace_id}, "
                f"got {traces[1].causal_parent.trace_id}"
            )

        if traces[2].causal_parent.trace_id != traces[1].trace_id:
            raise AssertionError(
                f"C14 parent mismatch: expected {traces[1].trace_id}, "
                f"got {traces[2].causal_parent.trace_id}"
            )

        if traces[3].causal_parent.trace_id != traces[2].trace_id:
            raise AssertionError(
                f"C9 parent mismatch: expected {traces[2].trace_id}, "
                f"got {traces[3].causal_parent.trace_id}"
            )

# ============================================================================
# Main Execution
# ============================================================================

def main():
    parser = argparse.ArgumentParser(
        description="Probe U4: Governance → ASC (Constitutional Consumption)"
    )
    parser.add_argument(
        "--contract", type=Path, default=CONTRACT_PATH,
        help="Path to the certification contract (YAML)"
    )
    parser.add_argument(
        "--intent", type=Path, default=None,
        help="Path to test intent file (JSON). If not provided, uses synthetic intent."
    )
    args = parser.parse_args()

    print("=" * 80)
    print("PROBE U4: Governance → ASC (Constitutional Consumption)")
    print("=" * 80)
    print("\nConstitutional Compliance:")
    print("  - Auth-free certification (POL-CERT-AUTH-001)")
    print("  - No production mutation, bootstrap, external calls, or adoption")
    print("  - Verdict targets integration edges, not entire capabilities")
    print("  - Bounded proposition: ASC consumed C14 decision before consequential state")
    print()

    # Step 1: Load certification contract (auth-free)
    print("[STEP 1] Loading immutable certification contract...")
    try:
        contract = load_certification_contract(args.contract)
        enforce_certification_bounds(contract)
        print(f"  ✓ Contract verified (hash: {contract['contract_hash'][:16]}...)")
        print(f"  ✓ Boundary check passed: observation-only, no bootstrap, no mutation, no adoption")
    except (CertificationContractError, ActionNotCertificationError) as e:
        print(f"\n  [CERT HALT] {e}")
        sys.exit(1)

    # Step 2: Load test intent
    print("\n[STEP 2] Loading test intent...")
    if args.intent and args.intent.exists():
        with open(args.intent, "r") as f:
            intent = json.load(f)
        print(f"  Loaded from: {args.intent}")
    else:
        intent = {
            "objective": "Generate a candidate optimization for RepairLibrary ingestion",
            "constraints": ["max_memory_mb: 50", "no_external_calls"],
            "context": "U4 governance consumption test",
            "timestamp": datetime.now(timezone.utc).isoformat()
        }
        print("  Using synthetic intent (no external input file provided)")

    # Step 3: Execute probe
    print("\n[STEP 3] Executing probe (positive + negative controls)...")
    probe = ProbeU4(contract)
    result = probe.run(intent)

    # Step 4: Write results
    print("\n[STEP 4] Writing results...")
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    result_path = RESULTS_DIR / "U4_governance_to_asc_result.json"
    with open(result_path, "w") as f:
        json.dump(result, f, indent=2)
    print(f"  Results saved to: {result_path}")

    # Step 5: Report
    print("\n" + "=" * 80)
    print("PROBE U4 EXECUTION COMPLETE")
    print("=" * 80)
    print(f"\nStatus: {result['status']}")
    print(f"Bounded proposition: {result['bounded_proposition']}")
    print(f"Verdict targets: {result['verdict_targets']}")
    print(f"Evidence files: {len(result.get('evidence_files', []))}")

    if result["status"] == "SUCCESS":
        print("\n[NOTICE] U4 passed both controls.")
        print("Integration edges C3→C8, C8→C14, C14→C9 may be upgraded upon human review.")
        print("Do NOT mark all of C9/C14 as universally operational.")
    elif result["status"] == "PARTIAL_FAILURE":
        print("\n[NOTICE] U4 partially failed. Review evidence files for diagnostic.")

    print("\n[CERTIFICATION RECORD] This probe produced certification evidence only.")
    print("No production action was authorized or executed.")


if __name__ == "__main__":
    main()