#!/usr/bin/env python3
"""
Probe U5/U6: External Reality Ingress & Propagation
====================================================
Tests C11 (Boundary) -> C1 (Perception) -> C2 (Reality Model) -> C3 (Knowledge).

Constitutional Compliance:
- Auth-free certification (POL-CERT-AUTH-001)
- Permits external READS (Ingress), forbids external WRITES (Egress)
- Honestly records the C1->C2 causal break if C2 remains deferred

Controls:
- Positive (valid signed payload): must be accepted at C11 with verified
  signature + provenance, propagate through C1, attempt C2 (expected break
  recorded honestly), and C3 must NOT accept state on a broken chain.
- Negative (tampered payload, stale signature): must be REJECTED at C11 —
  no mock/unverified external reality is accepted as evidence, no side channel.

REAL-MODULE WIRING (executed in the BEAM via priv/tiannara/probes/u5_chain.exs):
- C11: filesystem ingress + sha256 signature verification + Observatory
       governance consult (TiannaraOS.Governance.CapabilityChecker
       authorize?/3, :can_observe @ :observability). READ-ONLY.
- C1:  Tiannara.Sentinel.Activation.Event.new/1 + Engine.process/1
- C2:  Tiannara.Graph.UnifiedRealityGraph.add_node/3 (attempted; known
       ExecutiveMemory :noproc dependency per U1 F2 — recorded, not masked)
- C3:  Tiannara.Memory.KnowledgeStore (only on an intact causal chain)

This script orchestrates both controls, emits trace envelopes + real evidence
files, and verifies the ingress invariants. It does NOT modify the audit matrix.
"""

import sys
import os
import json
import uuid
import hashlib
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
CHAIN_SCRIPT = PROJECT_ROOT / "priv" / "tiannara" / "probes" / "u5_chain.exs"
CONTRACT_PATH = PROJECT_ROOT / "priv" / "tiannara" / "probes" / "contracts" / "U5_U6_external_reality_ingress.contract.yaml"

# ============================================================================
# Trace Envelope (same schema as U1/U4)
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

def write_evidence(prefix: str, trace_id: str, phase: str, data: Dict[str, Any]) -> str:
    """Write evidence file to disk. Returns relative path."""
    EVIDENCE_DIR.mkdir(parents=True, exist_ok=True)
    filename = f"U5_{trace_id}_{phase}.json"
    filepath = EVIDENCE_DIR / filename
    with open(filepath, "w") as f:
        json.dump(data, f, indent=2)
    return f"priv/tiannara/probes/evidence/{filename}"

# ============================================================================
# Real-Module Chain Execution
# ============================================================================

def run_u5_chain(payload_file: Path, signature: str, out_dir: Path, timeout: int = 900) -> Dict[str, Any]:
    """
    Execute the real C11→C1→C2→C3 chain inside the BEAM for one run.

    Calls priv/tiannara/probes/u5_chain.exs via `mix run --no-start`
    (app.config only — no supervision tree). Parses the 'U5CHAIN_RESULT '
    JSON line from stdout.
    """
    env = os.environ.copy()
    env["MIX_ENV"] = "test"

    cmd = [
        "mix", "run", "--no-start",
        str(CHAIN_SCRIPT),
        str(payload_file),
        signature,
        str(out_dir)
    ]

    print(f"  mix run --no-start {CHAIN_SCRIPT.name} ...")
    proc = subprocess.run(
        cmd,
        cwd=str(PROJECT_ROOT),
        env=env,
        capture_output=True,
        text=True,
        timeout=timeout
    )

    for line in (proc.stdout or "").splitlines():
        if line.startswith("U5CHAIN_RESULT "):
            return json.loads(line[len("U5CHAIN_RESULT "):])

    raise RuntimeError(
        "No U5CHAIN_RESULT line in chain output.\n"
        f"Exit code: {proc.returncode}\n"
        f"stderr tail: {(proc.stderr or '')[-2000:]}"
    )

# ============================================================================
# Probe U5/U6 Orchestration
# ============================================================================

class ProbeU5U6:
    """
    Probe U5/U6: External Reality Ingress & Propagation

    Tests the causal path:
    C11 (Boundary) → C1 (Perception) → C2 (Reality Model) → C3 (Knowledge)

    With a signed-ingress control (must be accepted) and a tampered-ingress
    control (must be rejected), to prove no unverified external reality is
    accepted as evidence and no unauthorized side channel is created.
    """

    REAL_PROVENANCE = {
        "c11_ingress": ("TiannaraOS.Governance.CapabilityChecker", "authorize?/3 (:can_observe @ :observability)"),
        "c1_perception": ("Tiannara.Sentinel.Activation.Event", "new/1 + Engine.process/1"),
        "c2_reality_model": ("Tiannara.Graph.UnifiedRealityGraph", "add_node/3"),
        "c3_knowledge": ("Tiannara.Memory.KnowledgeStore", "open/1 + append/2 + all/1"),
    }

    def __init__(self, contract: Dict[str, Any]):
        self.contract = contract
        self.traces: List[TraceEnvelope] = []
        self.evidence_files: List[str] = []
        self.causal_breaks: List[str] = []

    def _sign(self, payload: bytes) -> str:
        return hashlib.sha256(payload).hexdigest()

    def run(self, external_event: Dict[str, Any]) -> Dict[str, Any]:
        """Execute U5/U6 with valid-ingress and tampered-ingress controls."""

        print("=" * 80)
        print("PROBE U5/U6: External Reality Ingress & Propagation")
        print("=" * 80)
        print(f"\nBounded proposition:")
        print(f"  {self.contract['bounded_proposition']}")
        print(f"\nExternal event: {json.dumps(external_event, indent=2)}\n")

        EVIDENCE_DIR.mkdir(parents=True, exist_ok=True)

        # --- Valid signed payload (positive control) ---
        valid_file = EVIDENCE_DIR / f"U5_external_payload_{uuid.uuid4().hex[:8]}.json"
        canonical = json.dumps(external_event, indent=2, sort_keys=True)
        valid_file.write_text(canonical)
        valid_sig = self._sign(valid_file.read_bytes())
        print(f"[PAYLOAD] Valid payload file: {valid_file.relative_to(PROJECT_ROOT)}")
        print(f"[PAYLOAD] Signature (sha256): {valid_sig}")

        # --- Tampered payload (negative control: stale signature) ---
        tampered_file = EVIDENCE_DIR / f"U5_external_payload_tampered_{uuid.uuid4().hex[:8]}.json"
        tampered = dict(external_event)
        tampered["content"] = "TAMPERED: payload modified after signing"
        tampered_file.write_text(json.dumps(tampered, indent=2, sort_keys=True))
        print(f"[PAYLOAD] Tampered payload file: {tampered_file.relative_to(PROJECT_ROOT)}")
        print(f"[PAYLOAD] Signature (stale, original): {valid_sig}")

        results = {}

        # --- Positive control: valid signed ingress ---
        print("\n" + "=" * 40)
        print("CONTROL: Valid signed ingress")
        print("=" * 40)
        chain_out_dir = EVIDENCE_DIR / f"U5_chain_{uuid.uuid4().hex[:8]}"
        chain_out_dir.mkdir(parents=True, exist_ok=True)
        try:
            results["valid_ingress"] = self._run_valid_control(
                valid_file, valid_sig, chain_out_dir,
                commit_hash=os.environ.get("TIANNARA_COMMIT_HASH", "HEAD")
            )
            print(f"\n  Result: {results['valid_ingress']['status']}")
        except AssertionError as e:
            results["valid_ingress"] = {"status": "FAILURE", "error": str(e)}
            print(f"\n  [FAILURE] {e}")
        except Exception as e:
            results["valid_ingress"] = {"status": "FAILURE", "error": str(e)}
            print(f"\n  [FAILURE] {e}")

        # --- Negative control: tampered ingress must be rejected ---
        print("\n" + "=" * 40)
        print("CONTROL: Tampered ingress (must be REJECTED)")
        print("=" * 40)
        chain_out_dir2 = EVIDENCE_DIR / f"U5_chain_{uuid.uuid4().hex[:8]}"
        chain_out_dir2.mkdir(parents=True, exist_ok=True)
        try:
            results["tampered_ingress"] = self._run_tampered_control(
                tampered_file, valid_sig, chain_out_dir2,
                commit_hash=os.environ.get("TIANNARA_COMMIT_HASH", "HEAD")
            )
            print(f"\n  Result: {results['tampered_ingress']['status']}")
        except AssertionError as e:
            results["tampered_ingress"] = {"status": "FAILURE", "error": str(e)}
            print(f"\n  [FAILURE] {e}")
        except Exception as e:
            results["tampered_ingress"] = {"status": "FAILURE", "error": str(e)}
            print(f"\n  [FAILURE] {e}")

        # --- Overall verdict ---
        results["bounded_proposition"] = self.contract["bounded_proposition"]
        results["verdict_scope"] = self.contract["verdict_scope"]
        results["verdict_targets"] = self.contract["verdict_targets"]
        results["evidence_files"] = self.evidence_files
        results["causal_breaks"] = self.causal_breaks

        valid_ok = results.get("valid_ingress", {}).get("status") == "PARTIAL_SUCCESS_CAUSAL_BREAK"
        tampered_ok = results.get("tampered_ingress", {}).get("status") == "REJECTED"

        if valid_ok and tampered_ok:
            results["status"] = "PARTIAL_SUCCESS_CAUSAL_BREAK"
        else:
            results["status"] = "FAILURE"

        return results

    def _run_valid_control(self, payload_file: Path, signature: str, out_dir: Path,
                           commit_hash: str) -> Dict[str, Any]:
        """Run the valid signed ingress through the real chain."""
        chain = run_u5_chain(payload_file, signature, out_dir)

        if chain.get("status") != "complete":
            raise RuntimeError(f"Chain did not complete: {chain}")
        if chain.get("payload_hash") != signature:
            raise AssertionError(
                f"Payload hash mismatch: python={signature} beam={chain.get('payload_hash')}"
            )

        phases = chain.get("phases", {})
        c11 = self._ok_of(phases.get("c11", {}), "C11 ingress")
        c1 = self._ok_of(phases.get("c1", {}), "C1 perception")
        c2 = phases.get("c2", {})
        c3 = phases.get("c3", {})

        # Verify: signature verified at boundary
        print(f"\n  [VERIFY] C11 signature verification...")
        if not c11.get("signature_verified"):
            raise AssertionError("C11 did not verify the valid signature")
        print(f"    ✓ Signature verified (sha256: {signature[:16]}...)")

        # Verify: provenance captured
        print(f"\n  [VERIFY] Provenance captured...")
        if not c11.get("provenance"):
            raise AssertionError("C11 captured no provenance")
        print(f"    ✓ Provenance: {c11.get('provenance')}")

        # Verify: governance consulted at the ingress boundary
        print(f"\n  [VERIFY] Governance consulted (Observatory :can_observe)...")
        gov = c11.get("governance_consult", {})
        if "ok" not in gov:
            raise AssertionError(f"Governance consult failed at C11: {gov}")
        print(f"    ✓ {c11.get('governance_institution')} → {gov.get('ok')}")

        # Verify: perception consumed the event
        print(f"\n  [VERIFY] C1 perception consumed the event...")
        if "engine" not in c1:
            raise AssertionError(f"C1 perception failed: {c1}")
        engine = c1.get("engine", {})
        if "ok" not in engine:
            raise AssertionError(f"C1 engine failed: {engine.get('error')}")
        print(f"    ✓ Event {c1.get('event_id')} ingested (source={c1.get('event_source')})")

        # Verify: C2 attempted, causal break recorded honestly (expected)
        print(f"\n  [VERIFY] C2 attempted and causal break recorded honestly...")
        c2_inner = c2.get("ok", {})
        c2_add = c2_inner.get("add_node", {})
        if "ok" in c2_add:
            raise AssertionError(
                f"UNEXPECTED: C2 succeeded. C2 was deferred with ExecutiveMemory "
                f"dependency — if it now works, this must be reviewed, not assumed."
            )
        if "error" not in c2_add:
            raise AssertionError(f"C2 did not return a verifiable result: {c2}")
        break_msg = f"C1->C2 broken: {c2_add.get('error')}"
        self.causal_breaks.append(break_msg)
        print(f"    [CAUSAL BREAK] {break_msg}")
        print(f"    ✓ Break recorded honestly (not masked)")

        # Verify: C3 did NOT accept state on a broken chain
        print(f"\n  [VERIFY] C3 refused state on broken chain...")
        if "ok" in c3:
            raise AssertionError(
                "C3 accepted knowledge state even though the causal chain broke at C1->C2. "
                "This would create shadow state."
            )
        if not c3.get("skipped", False):
            raise AssertionError(f"C3 behavior unexpected: {c3}")
        print(f"    ✓ C3 skipped with reason: {c3.get('reason')}")

        # Build envelopes
        control_traces = []
        parent = None
        for phase in ["c11_ingress", "c1_perception", "c2_reality_model", "c3_knowledge"]:
            module, func = self.REAL_PROVENANCE[phase]
            if phase == "c11_ingress":
                ok = True
                confidence = 0.95
            elif phase == "c1_perception":
                ok = True
                confidence = 0.90
            elif phase == "c2_reality_model":
                ok = False
                confidence = 0.90
            else:
                ok = False
                confidence = 0.90

            envelope = self._build_envelope(
                phase=f"{phase}_valid",
                parent=parent,
                provenance=Provenance(module=module, function=func, commit_hash=commit_hash),
                payload_hash=signature,
                confidence=confidence,
                ok=ok,
                failure_detail=c2_add.get("error") if phase == "c2_reality_model" else
                              (c3.get("reason") if phase == "c3_knowledge" else None)
            )
            control_traces.append(envelope)
            self.evidence_files.append(write_evidence("U5", envelope.trace_id, phase, {
                "phase": phase,
                "trace_id": envelope.trace_id,
                "ok": ok,
                "chain_result": c11 if phase == "c11_ingress" else
                               (c1 if phase == "c1_perception" else
                                (c2 if phase == "c2_reality_model" else c3)),
                "payload_hash": signature
            }))
            print(f"  [{'OK' if ok else 'BREAK'}] {phase}")
            parent = envelope

        # Verify: single trace id lineage (no shadow path)
        print(f"\n  [VERIFY] Single trace lineage C11→C1→C2→C3...")
        self._verify_lineage(control_traces)
        print(f"    ✓ One trace id spans the ingress chain (no shadow path)")

        self.traces.extend(control_traces)

        return {
            "status": "PARTIAL_SUCCESS_CAUSAL_BREAK",
            "control": "valid_signed_ingress",
            "signature_verified": c11.get("signature_verified"),
            "governance_consult": c11.get("governance_consult"),
            "causal_break": c2_add.get("error"),
            "c3_behavior": "refused state (chain broken)",
            "traces": [t.to_dict() for t in control_traces],
        }

    def _run_tampered_control(self, payload_file: Path, signature: str, out_dir: Path,
                              commit_hash: str) -> Dict[str, Any]:
        """Run the tampered payload — must be rejected at the C11 boundary."""
        chain = run_u5_chain(payload_file, signature, out_dir)

        if chain.get("status") != "complete":
            raise RuntimeError(f"Chain did not complete: {chain}")

        phases = chain.get("phases", {})
        c11 = phases.get("c11", {}).get("ok", {})
        c1 = phases.get("c1", {})
        c2 = phases.get("c2", {})
        c3 = phases.get("c3", {})

        # Verify: rejected at boundary
        print(f"\n  [VERIFY] Tampered payload rejected at C11...")
        if c11.get("signature_verified", True):
            raise AssertionError(
                "SECURITY VIOLATION: tampered payload was accepted as evidence. "
                "Mock/unverified external reality must never be accepted."
            )
        print(f"    ✓ Rejected (hash {chain.get('payload_hash')[:16]}... != signature {signature[:16]}...)")

        # Verify: no downstream propagation
        print(f"\n  [VERIFY] No downstream propagation after rejection...")
        for phase_name, phase_res in [("C1", c1), ("C2", c2), ("C3", c3)]:
            if phase_res.get("skipped") is not True:
                raise AssertionError(
                    f"{phase_name} ran despite rejected ingress — unauthorized side channel."
                )
        print(f"    ✓ C1/C2/C3 skipped — no unauthorized side channel")

        envelope = self._build_envelope(
            phase="c11_ingress_rejected",
            parent=None,
            provenance=Provenance(
                module="TiannaraOS.Governance.CapabilityChecker",
                function="authorize?/3 (:can_observe @ :observability)",
                commit_hash=commit_hash
            ),
            payload_hash=signature,
            confidence=0.95,
            ok=False,
            failure_detail="signature_verified=false: payload hash mismatch at C11 ingress"
        )
        self.traces.append(envelope)
        self.evidence_files.append(write_evidence("U5", envelope.trace_id, "c11_ingress_rejected", {
            "phase": "c11_ingress_rejected",
            "trace_id": envelope.trace_id,
            "ok": False,
            "chain_result": c11,
            "payload_hash": signature
        }))

        return {
            "status": "REJECTED",
            "control": "tampered_ingress",
            "signature_verified": False,
            "traces": [envelope.to_dict()],
        }

    def _ok_of(self, result_map: Dict[str, Any], what: str) -> Dict[str, Any]:
        if "error" in result_map or "ok" not in result_map:
            raise AssertionError(f"{what} failed: {result_map.get('error') or result_map}")
        return result_map["ok"]

    def _build_envelope(
        self, phase: str, parent: Optional[TraceEnvelope],
        provenance: Provenance, payload_hash: str,
        confidence: float, ok: bool, failure_detail: Optional[str] = None
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
            evidence_ref=f"priv/tiannara/probes/evidence/U5_{trace_id}_{phase}.json",
            confidence_level=ConfidenceLevel(
                value=confidence,
                justification="Real module transition succeeded" if ok else failure_detail
            ),
            authorization_state=AuthorizationState(
                required=False,  # Certification probe — no authorization needed
                granted_by=None,
                timestamp=None
            ),
            outcome=Outcome(status="success" if ok else "failed", payload_hash=payload_hash),
            failure_state=FailureState(
                detected=not ok,
                error_class="causal_break" if failure_detail else None,
                severity="known_deferred_dependency" if failure_detail else None
            ),
            recovery_behavior=RecoveryBehavior(
                action="record_causal_break_no_mask" if not ok else "none",
                executed=True,
                success=True
            ),
            next_phase=None
        )

    def _verify_lineage(self, traces: List[TraceEnvelope]):
        """Verify single-trace causal chain C11→C1→C2→C3."""
        if len(traces) != 4:
            raise AssertionError(f"Expected 4 traces, got {len(traces)}")

        if traces[0].causal_parent.trace_id is not None:
            raise AssertionError(f"C11 (root) has non-null parent")

        for i in range(1, 4):
            if traces[i].causal_parent.trace_id != traces[i - 1].trace_id:
                raise AssertionError(
                    f"Phase {i} parent mismatch: expected {traces[i - 1].trace_id}, "
                    f"got {traces[i].causal_parent.trace_id}"
                )

# ============================================================================
# Main Execution
# ============================================================================

def main():
    parser = argparse.ArgumentParser(
        description="Probe U5/U6: External Reality Ingress & Propagation"
    )
    parser.add_argument(
        "--contract", type=Path, default=CONTRACT_PATH,
        help="Path to the certification contract (YAML)"
    )
    parser.add_argument(
        "--event", type=Path, default=None,
        help="Path to external event file (JSON). If not provided, uses synthetic event."
    )
    args = parser.parse_args()

    print("=" * 80)
    print("PROBE U5/U6: External Reality Ingress & Propagation")
    print("=" * 80)
    print("\nConstitutional Compliance:")
    print("  - Auth-free certification (POL-CERT-AUTH-001)")
    print("  - External READS permitted (Ingress); external WRITES forbidden (Egress = ACTION)")
    print("  - No production mutation, bootstrap, or adoption")
    print("  - Verdict targets integration edges, not entire capabilities")
    print("  - Bounded proposition: C11 ingress propagates with intact provenance or is rejected")
    print()

    # Step 1: Load certification contract (auth-free)
    print("[STEP 1] Loading immutable certification contract...")
    try:
        contract = load_certification_contract(args.contract)
        enforce_certification_bounds(contract)
        print(f"  ✓ Contract verified (hash: {contract['contract_hash'][:16]}...)")
        print(f"  ✓ Boundary check passed: read-only ingress, no mutation, no bootstrap, no adoption")
    except (CertificationContractError, ActionNotCertificationError) as e:
        print(f"\n  [CERT HALT] {e}")
        sys.exit(1)

    # Step 2: Load external event
    print("\n[STEP 2] Loading external event...")
    if args.event and args.event.exists():
        with open(args.event, "r") as f:
            external_event = json.load(f)
        print(f"  Loaded from: {args.event}")
    else:
        external_event = {
            "type": "repository_commit_event",
            "repository": "tiannara-mindcache-prosthetic",
            "commit": "test-commit-hash",
            "message": "External reality probe event",
            "content": {"files_changed": ["docs/example.md"]},
            "timestamp": datetime.now(timezone.utc).isoformat()
        }
        print("  Using synthetic external event (no external input file provided)")

    # Step 3: Execute probe
    print("\n[STEP 3] Executing probe (valid + tampered ingress controls)...")
    probe = ProbeU5U6(contract)
    result = probe.run(external_event)

    # Step 4: Write results
    print("\n[STEP 4] Writing results...")
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    result_path = RESULTS_DIR / "U5_U6_external_reality_ingress_result.json"
    with open(result_path, "w") as f:
        json.dump(result, f, indent=2)
    print(f"  Results saved to: {result_path}")

    # Step 5: Report
    print("\n" + "=" * 80)
    print("PROBE U5/U6 EXECUTION COMPLETE")
    print("=" * 80)
    print(f"\nStatus: {result['status']}")
    print(f"Bounded proposition: {result['bounded_proposition']}")
    print(f"Verdict targets: {result['verdict_targets']}")
    print(f"Evidence files: {len(result.get('evidence_files', []))}")

    if result["status"] == "PARTIAL_SUCCESS_CAUSAL_BREAK":
        print("\n[NOTICE] C11 ingress verified; causal chain honestly broken at C1→C2.")
        print("This evidence formally justifies the C2 Remediation Mission.")
        for break_msg in result.get("causal_breaks", []):
            print(f"  - {break_msg}")
    else:
        print("\n[FAILURE] See evidence files for diagnostic.")

    print("\n[CERTIFICATION RECORD] This probe produced certification evidence only.")
    print("No production action, external mutation, or C11 Egress was authorized or executed.")


if __name__ == "__main__":
    main()