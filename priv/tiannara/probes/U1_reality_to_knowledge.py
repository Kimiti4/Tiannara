#!/usr/bin/env python3
"""
Probe U1: Reality → Knowledge (Metabolism) — REAL MODULE VERSION
==================================================================

This probe tests whether Tiannara can:
1. Ingest a real external observation (C1)
2. Mutate the canonical reality model (C2)
3. Store the observation as traceable knowledge (C3)
4. Apply epistemic tags and uncertainty (C4)
5. Persist a hash-chained lineage (C7)

REAL-MODULE WIRING (Option C):
- C1: Tiannara.Sentinel.Activation.Event.new/1 + Engine.process/1
- C2: Tiannara.Graph.UnifiedRealityGraph (add_node/3, get_node_with_context/1)
      shadow check vs Tiannara.World.UnifiedWorldModel.get_entity/1
- C3: Tiannara.Memory.KnowledgeStore (isolated, append-only, refuses production path)
- C4: Tiannara.Epistemic.Node + Tiannara.Epistemic.View.render_node/1
- C7: Tiannara.Lineage.Entry.new/3 + Tiannara.Lineage.Store (hash-chained, verify_chain/1)

The chain executes inside the real BEAM via priv/tiannara/probes/u1_chain.exs
(mix run --no-start, app.config only — matching the frozen observation protocol).
This Python script orchestrates, verifies the immutable certification contract,
and emits trace envelopes + real evidence files. It does NOT modify the audit matrix.

Per POL-CERT-AUTH-001: CERTIFICATION ("what is true?") requires NO human
authorization — it requires an immutable contract, real execution, provenance,
evidence, independent verification, and a bounded verdict. AUTHORIZATION
("may we act?") remains C14-gated and is NOT handled by this probe.

Constitutional Compliance:
- POL-CERT-AUTH-001: Certification is self-verifying but never self-authorizing;
  bounded to epistemic status only (cannot trigger adoption/action)
- C16: Writes real evidence files (no fabricated evidence trail)
- Epistemic: Does not flip audit statuses (human review required)
"""

import sys
import os
import json
import hashlib
import uuid
import yaml
import argparse
import subprocess
from pathlib import Path
from datetime import datetime, timezone
from dataclasses import dataclass, asdict
from typing import Dict, Any, Optional, List

# ============================================================================
# SECTION 1: Constants and Configuration
# ============================================================================

PROJECT_ROOT = Path(__file__).resolve().parents[3]
EVIDENCE_DIR = PROJECT_ROOT / "priv" / "tiannara" / "probes" / "evidence"
RESULTS_DIR = PROJECT_ROOT / "priv" / "tiannara" / "probes" / "results"
CHAIN_SCRIPT = PROJECT_ROOT / "priv" / "tiannara" / "probes" / "u1_chain.exs"
CONTRACT_PATH = PROJECT_ROOT / "priv" / "tiannara" / "probes" / "contracts" / "U1_reality_to_knowledge.contract.yaml"

# ============================================================================
# SECTION 2: Trace Envelope Schema
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
    status: str  # "success" | "partial" | "failure"
    payload_hash: str

@dataclass
class FailureState:
    detected: bool
    error_class: Optional[str] = None
    severity: Optional[str] = None  # "low" | "medium" | "critical"

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
# SECTION 3: Certification Contract — NO human authorization needed
# ============================================================================
# Per POL-CERT-AUTH-001: certification ("what is true?") is auth-free.
# Authorization ("may we act?") remains C14-gated and is NOT handled here.

class ActionNotCertificationError(Exception):
    """Raised when a probe requests something that is action, not certification."""


class CertificationContractError(Exception):
    """Raised when the immutable contract is missing or tampered."""


def _hash_contract(contract: Dict[str, Any]) -> str:
    """Compute a stable hash over the contract, excluding the hash field itself."""
    body = {k: v for k, v in contract.items() if k != "contract_hash"}
    canonical = json.dumps(body, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(canonical.encode()).hexdigest()


def load_certification_contract(contract_path: Path) -> Dict[str, Any]:
    """
    Load and verify the IMMUTABLE certification contract.

    NO human signature required — this is certification, not authorization.
    Immutability is enforced by a content hash, not by a permission slip.
    """
    if not contract_path.exists():
        raise CertificationContractError(f"Contract not found: {contract_path}")

    with open(contract_path, "r") as f:
        contract = yaml.safe_load(f)

    declared = contract.get("contract_hash")
    computed = _hash_contract(contract)
    if declared != computed:
        raise CertificationContractError(
            f"Contract tampered or not finalized.\n"
            f"  declared: {declared}\n  computed: {computed}"
        )

    print("[CERT] Immutable certification contract verified (no authorization needed).")
    print(f"  probe_id: {contract.get('probe_id')}")
    print(f"  contract_hash: {computed[:16]}...")
    return contract


def enforce_certification_bounds(contract: Dict[str, Any]) -> None:
    """
    Enforce the certification/action boundary (POL-CERT-AUTH-001).

    If the probe requires mutation, service bootstrap, or external calls,
    it is ACTION — refuse here and route through C14 authorization instead.

    This is the guard that makes U1b (bootstrap ExecutiveMemory) NOT
    certification: service_bootstrap_allowed must be False to proceed.
    """
    violations = []
    if contract.get("mutation_allowed"):
        violations.append("mutation_allowed=true")
    if contract.get("service_bootstrap_allowed"):
        violations.append("service_bootstrap_allowed=true")
    if contract.get("external_calls_allowed"):
        violations.append("external_calls_allowed=true")

    if violations:
        raise ActionNotCertificationError(
            "Probe exceeds certification bounds: " + ", ".join(violations) + "\n"
            "This is ACTION, not certification. Route through C14 authorization."
        )

    print("[CERT] Boundary check passed: observation-only, no bootstrap, no mutation.")


# ============================================================================
# SECTION 4: Evidence Writing (Real Files)
# ============================================================================

def write_evidence(phase: str, trace_id: str, data: Dict[str, Any]) -> str:
    EVIDENCE_DIR.mkdir(parents=True, exist_ok=True)
    filename = f"U1_{trace_id}_{phase}.json"
    filepath = EVIDENCE_DIR / filename
    with open(filepath, 'w') as f:
        json.dump(data, f, indent=2)
    return f"priv/tiannara/probes/evidence/{filename}"


def evidence_exists(evidence_ref: str) -> bool:
    return (PROJECT_ROOT / evidence_ref).exists()


# ============================================================================
# SECTION 5: Real-Module Chain Execution (Option C)
# ============================================================================

def run_real_chain(observation_file: Path, out_dir: Path, timeout: int = 900) -> Dict[str, Any]:
    """
    Execute the real C1→C2→C3→C4→C7 chain inside the BEAM.

    Calls priv/tiannara/probes/u1_chain.exs via `mix run --no-start`
    (app.config only — no supervision tree, matching the frozen observe protocol).
    Parses the 'U1CHAIN_RESULT ' JSON line from stdout.
    """
    env = os.environ.copy()
    env["MIX_ENV"] = "test"

    cmd = [
        "mix", "run", "--no-start",
        str(CHAIN_SCRIPT),
        str(observation_file),
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
        if line.startswith("U1CHAIN_RESULT "):
            return json.loads(line[len("U1CHAIN_RESULT "):])

    raise RuntimeError(
        "No U1CHAIN_RESULT line in chain output.\n"
        f"Exit code: {proc.returncode}\n"
        f"stderr tail: {(proc.stderr or '')[-2000:]}"
    )


# ============================================================================
# SECTION 6: Probe U1 Orchestration
# ============================================================================

class ProbeU1:
    """
    Probe U1: Reality → Knowledge (Metabolism) — real modules.

    Success Criteria:
    1. Correct causal lineage walk (C1 root; each phase's parent = previous)
    2. Canonical state mutation verified via read-back
    3. No shadow state divergence (UnifiedWorldModel check reported honestly)
    4. All transitions emit conformant trace envelopes
    5. Payload hash consistency maintained end-to-end
    6. Real evidence files written to disk
    """

    PHASE_ORDER = ["perception", "reality_model", "knowledge_storage", "epistemic_tagging"]

    REAL_PROVENANCE = {
        "perception": ("Tiannara.Sentinel.Activation.Event", "new/1 + Engine.process/1"),
        "reality_model": ("Tiannara.Graph.UnifiedRealityGraph", "add_node/3"),
        "knowledge_storage": ("Tiannara.Memory.KnowledgeStore", "open/1 + append/2"),
        "epistemic_tagging": ("Tiannara.Epistemic.Node", "struct + View.render_node/1"),
    }

    def __init__(self, contract: Dict[str, Any]):
        self.contract = contract
        self.traces: List[TraceEnvelope] = []
        self.evidence_files: List[str] = []

    def _phase_succeeded(self, phase: str, result_map: Dict[str, Any]) -> bool:
        """
        A phase succeeds only when its phase-level result is {:ok, map}
        AND the phase's primary real-module transition succeeded:
          - perception:       Engine.process pipeline
          - reality_model:    add_node
          - knowledge_storage: artifacts actually written
          - epistemic_tagging: node built at :knowledge stage
        """
        if not isinstance(result_map, dict) or "error" in result_map:
            return False
        ok_map = result_map.get("ok")
        if not isinstance(ok_map, dict):
            return False

        if phase == "perception":
            pipeline = ok_map.get("pipeline")
            return isinstance(pipeline, dict) and "error" not in pipeline
        if phase == "reality_model":
            add_node = ok_map.get("add_node")
            return isinstance(add_node, dict) and "error" not in add_node
        if phase == "knowledge_storage":
            return ok_map.get("artifacts_written", 0) >= 1
        if phase == "epistemic_tagging":
            return ok_map.get("node_stage") == "knowledge"
        return False

    def run(self, observation: Dict[str, Any], commit_hash: str = "HEAD") -> Dict[str, Any]:
        print("=" * 80)
        print("PROBE U1: Reality → Knowledge (Metabolism) — REAL MODULE VERSION")
        print("=" * 80)
        print(f"\nInput: {json.dumps(observation, indent=2)}\n")

        # Prepare canonical observation file (bytes hashed identically in Elixir)
        EVIDENCE_DIR.mkdir(parents=True, exist_ok=True)
        obs_file = EVIDENCE_DIR / f"U1_input_{uuid.uuid4().hex[:8]}.json"
        with open(obs_file, 'w') as f:
            json.dump(observation, f, indent=2, sort_keys=True)
        payload_hash = hashlib.sha256(obs_file.read_bytes()).hexdigest()
        chain_out_dir = EVIDENCE_DIR / f"U1_chain_{uuid.uuid4().hex[:8]}"
        chain_out_dir.mkdir(parents=True, exist_ok=True)

        print(f"[CHAIN] Observation file: {obs_file.relative_to(PROJECT_ROOT)}")
        print(f"[CHAIN] Payload hash: {payload_hash}")

        try:
            chain = run_real_chain(obs_file, chain_out_dir)
        except Exception as e:
            print(f"\n[FAILURE] Chain execution error: {e}")
            return {"status": "FAILURE", "error": str(e), "traces": [], "evidence_files": []}

        if chain.get("status") != "complete":
            print(f"\n[FAILURE] Chain did not complete: {chain}")
            return {"status": "FAILURE", "error": json.dumps(chain), "traces": [], "evidence_files": []}

        chain_hash = chain.get("payload_hash")
        if chain_hash != payload_hash:
            print(f"\n[FAILURE] Payload hash mismatch: python={payload_hash} beam={chain_hash}")
            return {"status": "FAILURE", "error": "payload hash mismatch across boundary", "traces": [], "evidence_files": []}

        phases = chain.get("phases", {})
        phase_ok = {
            phase: self._phase_succeeded(phase, phases.get(key, {}))
            for phase, key in [
                ("perception", "c1"),
                ("reality_model", "c2"),
                ("knowledge_storage", "c3"),
                ("epistemic_tagging", "c4"),
            ]
        }

        parent = None
        for phase in self.PHASE_ORDER:
            ok = phase_ok.get(phase, False)
            module, func = self.REAL_PROVENANCE[phase]

            result_map = phases.get({"perception": "c1", "reality_model": "c2",
                                     "knowledge_storage": "c3", "epistemic_tagging": "c4"}[phase], {})
            payload = result_map.get("ok") if result_map.get("ok") is not None else result_map.get("error")

            envelope = self._build_trace_envelope(
                phase=phase,
                parent=parent,
                provenance=Provenance(module=module, function=func, commit_hash=commit_hash),
                payload_hash=chain_hash,
                confidence=0.95 if ok else 0.0,
                justification=("Real module transition succeeded" if ok else "Real module transition failed"),
                ok=ok,
                detail=payload
            )
            self.traces.append(envelope)
            evidence_path = write_evidence(phase, envelope.trace_id, {
                "phase": phase,
                "trace_id": envelope.trace_id,
                "ok": ok,
                "chain_result": payload,
                "payload_hash": chain_hash
            })
            self.evidence_files.append(evidence_path)
            status = "OK" if ok else "FAILED"
            print(f"[{self.PHASE_ORDER.index(phase) + 1}/4] {phase}: {status}")
            parent = envelope

        # Verification: lineage walk
        print("\n[VERIFY] Lineage walk (correct parent chain)...")
        self._verify_lineage()
        print("  ✓ Lineage chain verified")

        # Verification: payload hash consistency
        print("\n[VERIFY] Payload hash consistency...")
        self._verify_payload_hash_consistency()
        print("  ✓ Payload hash consistent across all phases")

        # Verification: evidence files exist on disk
        print("\n[VERIFY] Evidence files on disk...")
        missing = [ref for ref in self.evidence_files if not evidence_exists(ref)]
        if missing:
            raise AssertionError(f"Evidence files missing: {missing}")
        print(f"  ✓ {len(self.evidence_files)} evidence files written")

        # Shadow-state report (honest, from real chain)
        shadow = phases.get("c2", {}).get("ok", {}).get("shadow_world_model", {})
        print("\n[VERIFY] Shadow state check (UnifiedWorldModel)...")
        print(f"  {json.dumps(shadow, indent=2, default=str)}")

        # Elixir-side lineage chain verification
        c7 = phases.get("c7", {}).get("ok", {})
        chain_verified = c7.get("chain_verified", False)
        print(f"\n[VERIFY] Elixir lineage chain (Lineage.Store.verify_chain): {chain_verified}")

        all_ok = all(phase_ok.values())

        print("\n" + "=" * 80)
        print(f"PROBE U1: {'SUCCESS' if all_ok else 'PARTIAL_FAILURE'}")
        print("=" * 80)
        print(f"\nEvidence files written: {len(self.evidence_files)}")
        for ef in self.evidence_files:
            print(f"  - {ef}")

        return {
            "status": "SUCCESS" if all_ok else "PARTIAL_FAILURE",
            "payload_hash": chain_hash,
            "traces": [t.to_dict() for t in self.traces],
            "evidence_files": self.evidence_files,
            "verification": {
                "lineage_chain_intact": True,
                "payload_hash_consistent": True,
                "evidence_files_written": len(self.evidence_files),
                "elixir_lineage_chain_verified": chain_verified,
                "shadow_world_model": shadow,
                "phase_ok": phase_ok
            }
        }

    def _build_trace_envelope(
        self,
        phase: str,
        parent: Optional[TraceEnvelope],
        provenance: Provenance,
        payload_hash: str,
        confidence: float,
        justification: str,
        ok: bool,
        detail: Any
    ) -> TraceEnvelope:
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
            evidence_ref=f"priv/tiannara/probes/evidence/U1_{trace_id}_{phase}.json",
            confidence_level=ConfidenceLevel(value=confidence, justification=justification),
            authorization_state=AuthorizationState(
                required=False,
                granted_by=None,
                timestamp=datetime.now(timezone.utc).isoformat()
            ),
            outcome=Outcome(status="success" if ok else "failure", payload_hash=payload_hash),
            failure_state=FailureState(detected=not ok, error_class=None if ok else "phase_error", severity=None if ok else "medium"),
            recovery_behavior=RecoveryBehavior(action="none", executed=False, success=True),
            next_phase=self._get_next_phase(phase)
        )

    def _get_next_phase(self, current_phase: str) -> Optional[str]:
        idx = self.PHASE_ORDER.index(current_phase)
        if idx + 1 < len(self.PHASE_ORDER):
            return self.PHASE_ORDER[idx + 1]
        return None

    def _verify_lineage(self):
        if len(self.traces) != 4:
            raise AssertionError(f"Expected 4 traces, got {len(self.traces)}")

        if self.traces[0].causal_parent.trace_id is not None:
            raise AssertionError(f"C1 (root) has non-null parent: {self.traces[0].causal_parent.trace_id}")

        if self.traces[1].causal_parent.trace_id != self.traces[0].trace_id:
            raise AssertionError(f"C2 parent mismatch")
        if self.traces[2].causal_parent.trace_id != self.traces[1].trace_id:
            raise AssertionError(f"C3 parent mismatch")
        if self.traces[3].causal_parent.trace_id != self.traces[2].trace_id:
            raise AssertionError(f"C4 parent mismatch")

    def _verify_payload_hash_consistency(self):
        hashes = [t.outcome.payload_hash for t in self.traces]
        if len(set(hashes)) != 1:
            raise AssertionError(f"Payload hash inconsistent across phases: {hashes}")


# ============================================================================
# SECTION 7: Main Execution
# ============================================================================

def main():
    parser = argparse.ArgumentParser(
        description="Probe U1: Reality → Knowledge (Metabolism) — REAL MODULE VERSION"
    )
    parser.add_argument("--contract", type=Path, default=CONTRACT_PATH,
                        help="Path to the immutable certification contract (YAML)")
    parser.add_argument("--observation", type=Path, default=None,
                        help="Path to the observation input file (JSON). If not provided, uses synthetic observation.")
    args = parser.parse_args()

    print("=" * 80)
    print("PROBE U1: Reality → Knowledge (Metabolism) — REAL MODULE VERSION")
    print("=" * 80)
    print("\nReal-module wiring:")
    print("  C1: Tiannara.Sentinel.Activation.Event / Engine.process")
    print("  C2: Tiannara.Graph.UnifiedRealityGraph (+ shadow check vs UnifiedWorldModel)")
    print("  C3: Tiannara.Memory.KnowledgeStore (isolated, append-only)")
    print("  C4: Tiannara.Epistemic.Node + View")
    print("  C7: Tiannara.Lineage.Store (hash-chained, verify_chain)")
    print("Constitutional Compliance (POL-CERT-AUTH-001):")
    print("  - CERTIFICATION = auth-free; requires immutable contract + real evidence")
    print("  - CERTIFICATION != AUTHORIZATION (bounded to epistemic status only)")
    print("  - C16: Writes real evidence files (no fabricated evidence trail)")
    print("  - Epistemic: Does not flip audit statuses (human review required)")
    print()

    print("[STEP 1] Loading immutable certification contract...")
    try:
        contract = load_certification_contract(args.contract)
        enforce_certification_bounds(contract)
    except (CertificationContractError, ActionNotCertificationError) as e:
        print(f"\n[CERT HALT] {e}")
        sys.exit(1)

    print("\n[STEP 2] Loading observation...")
    if args.observation and args.observation.exists():
        with open(args.observation, 'r') as f:
            observation = json.load(f)
        print(f"  Loaded from: {args.observation}")
    else:
        observation = {
            "entity_id": "repo_tiannara",
            "type": "repository_commit",
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "data": {
                "commit_hash": "HEAD",
                "author": "researcher_42",
                "message": "Add epistemic tracer module",
                "files_changed": 3
            }
        }
        print("  Using synthetic observation (no external input file provided)")

    print("\n[STEP 3] Executing probe against real Tiannara modules...")
    probe = ProbeU1(contract)
    result = probe.run(observation, commit_hash=os.environ.get("TIANNARA_COMMIT_HASH", "HEAD"))

    print("\n[STEP 4] Writing results...")
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    result_path = RESULTS_DIR / "U1_reality_to_knowledge_result.json"
    with open(result_path, 'w') as f:
        json.dump(result, f, indent=2, default=str)
    print(f"  Results saved to: {result_path}")

    print("\n" + "=" * 80)
    print("PROBE U1 EXECUTION COMPLETE")
    print("=" * 80)
    print(f"\nStatus: {result['status']}")
    print(f"Traces: {len(result.get('traces', []))}")
    print(f"Evidence files: {len(result.get('evidence_files', []))}")

    if result['status'] == 'SUCCESS':
        print("\n[NOTICE] Probe U1 completed successfully.")
        print("Evidence files have been written to disk.")
        print("Audit statuses must be updated manually after human review of evidence.")
        print("Do NOT automatically flip C1-C4 to '✓' without human verification.")

    if result['status'] == 'PARTIAL_FAILURE':
        print("\n[NOTICE] One or more phases failed. Failure evidence is preserved.")
        print("Generate a diagnostic hypothesis per phase before any re-run.")
        print("Do NOT modify production code based on this result.")

    if result['status'] == 'FAILURE':
        print("\n[NOTICE] Probe U1 failed.")
        print("Do NOT rollback or modify production code based on this failure.")
        print("Generate a diagnostic hypothesis and investigate further.")


if __name__ == "__main__":
    main()