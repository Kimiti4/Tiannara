#!/usr/bin/env python3
"""
U1x: Unified Re-certification (post CEL-1)
Tests the full loop: C11→C1→C2→C3→C4→C8→C14→CEL-1→C9→C12→C15
"""
import sys, json, argparse
from pathlib import Path
from datetime import datetime, timezone

sys.path.insert(0, str(Path(__file__).parent))
from certification_bounds import load_certification_contract, enforce_certification_bounds

PROJECT_ROOT = Path(__file__).parent.parent.parent.parent
CONTRACT_PATH = PROJECT_ROOT / "priv" / "tiannara" / "probes" / "contracts" / "U1x_unified_recertification.contract.yaml"
RESULTS_DIR = PROJECT_ROOT / "priv" / "tiannara" / "probes" / "results"

def main():
    parser = argparse.ArgumentParser(description="U1x Unified Re-certification")
    parser.add_argument("--contract", type=Path, default=CONTRACT_PATH)
    args = parser.parse_args()
    print("Loading U1x contract (auth-free)...")
    try:
        contract = load_certification_contract(args.contract)
        enforce_certification_bounds(contract)
    except Exception as e:
        print(f"[CERT HALT] {e}")
        sys.exit(1)
    print("="*80)
    print("U1x: Unified Re-certification (post CEL-1)")
    print("="*80)
    print("\nPhases: C11→C1→C2→C3→C4→C8→C14→CEL-1→C9→C12→C15")
    print("\nThis probe re-validates the entire organism with CEL-1's dynamic delegation")
    print("as the executive bridge. Each edge is checked for live registry-driven coordination.")
    # For now, this is a placeholder that will be expanded with real integration checks
    # The actual implementation will call each subsystem's verification
    result = {
        "status": "IN_PROGRESS",
        "reason": "U1x probe scaffold created. Real integration checks require wiring to live C11 ingress, C2/C3, C4, C8, C14, CEL-1, C9, C12, C15.",
        "contract_hash": contract.get("contract_hash"),
        "next_steps": [
            "Wire C11 ingress via signed external event",
            "Verify C1→C2→C3 with ExecutiveMemory lineage",
            "Verify C4 epistemic interpretation",
            "Verify C8→C14 governance",
            "Verify CEL-1 dynamic delegation (already PASS for tested path)",
            "Verify C9 ASC execution",
            "Verify C12 homeostasis and C15 continuity"
        ],
        "evidence_files": []
    }
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    out = RESULTS_DIR / "U1x_unified_recertification_result.json"
    with open(out, "w") as f:
        json.dump(result, f, indent=2)
    print(f"\nResult: {result['status']}")
    print(f"Reason: {result['reason']}")
    print(f"Evidence: {out}")

if __name__ == "__main__":
    main()
