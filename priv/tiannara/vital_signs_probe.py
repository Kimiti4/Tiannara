#!/usr/bin/env python3
"""
Tiannara Organism Vital Signs Probe
Evaluates whether the system is operating as a unified, living scientific organism.
Reads the evidence-based contract at priv/tiannara/unified_capability_contract.yaml.

Vital signs (per constitutional engineering instructions):
  Metabolism  : continuous information flow (Perception -> Reality Graph)
  Homeostasis : self-correction and anomaly detection (Cognitive Immune System)
  Adaptation  : continuous self-improvement (Capability Evolution)
  Purpose     : goal-directed behavior augmenting human intelligence (Unified Loop Integrity)
"""

import sys

try:
    import yaml
except ImportError:
    print("[CRITICAL] PyYAML not installed. Install with: pip install pyyaml")
    sys.exit(1)

CONTRACT_PATH = "priv/tiannara/unified_capability_contract.yaml"


def load_contract(filepath: str) -> dict:
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            return yaml.safe_load(f)
    except FileNotFoundError:
        print(f"[CRITICAL] Cannot find {filepath}. Organism is DECEASED (No contract).")
        sys.exit(1)


def highest_state(state: dict) -> str:
    order = ["D", "S", "R", "I", "V", "P"]
    for level in reversed(order):
        if state.get(level) is True:
            return level
    return ""


def meets(state: dict, threshold: str) -> bool:
    order = ["D", "S", "R", "I", "V", "P"]
    return order.index(highest_state(state)) >= order.index(threshold)


def mark(state: dict, level: str) -> str:
    v = state.get(level)
    if v is True:
        return "x"
    if v is None:
        return "?"
    return "-"


def check_vital_signs(contract: dict) -> None:
    print("=" * 60)
    print(" TIANNARA ORGANISM VITAL SIGNS DIAGNOSTIC")
    print("=" * 60)

    caps = {c["id"]: c for c in contract["capabilities"]}
    vital = {
        "Metabolism (Information Flow)": False,
        "Homeostasis (Self-Correction)": False,
        "Adaptation (Evolution)": False,
        "Purpose (Unified Loop Integrity)": False,
    }

    if meets(caps["C1"]["state"], "R") and meets(caps["C2"]["state"], "R"):
        vital["Metabolism (Information Flow)"] = True
        print("[x] METABOLISM: Reality perception is flowing into the reality model.")
    else:
        print("[ ] METABOLISM: Perception and/or Reality Model not runtime-operating (or unassessed).")

    if meets(caps["C12"]["state"], "I"):
        vital["Homeostasis (Self-Correction)"] = True
        print("[x] HOMEOSTASIS: Cognitive immune system is integrated and monitoring.")
    else:
        print("[ ] HOMEOSTASIS: Immune system not demonstrated integrated (runtime unassessed).")

    if meets(caps["C13"]["state"], "V"):
        vital["Adaptation (Evolution)"] = True
        print("[x] ADAPTATION: Capability evolution pipeline is validated and active.")
    else:
        print("[ ] ADAPTATION: Evolution pipeline not validated.")

    loop = ["C1", "C2", "C3", "C5", "C8", "C9", "C11"]
    loop_intact = all(meets(caps[c]["state"], "I") for c in loop) and meets(caps["C14"]["state"], "I")
    if loop_intact:
        vital["Purpose (Unified Loop Integrity)"] = True
        print("[x] PURPOSE: Unified perception-to-action loop is intact and governed.")
    else:
        missing = [c for c in loop if not meets(caps[c]["state"], "I")]
        print(f"[ ] PURPOSE: Unified loop fragmented. Not at Integration: {missing}")

    print("-" * 60)
    alive = sum(vital.values())
    adaptation_alive = vital["Adaptation (Evolution)"]
    print(f" VITAL SIGNS: {alive}/4   (x=verified, ?=unassessed, -=absent)")
    if alive == 4:
        print(" GREEN: ALIVE — operating as a unified, evolving scientific organism.")
        print("        Next Step: Execute U1-U8 cross-system probes under real workload (State 'P').")
    elif alive >= 2:
        print(" YELLOW: DORMANT / FRAGMENTED — core systems exist, but the unified loop is broken.")
        print("         Next Step: Prioritize integrating C2 (Reality Graph) and C11 (External Action).")
    elif adaptation_alive:
        print(" YELLOW: DORMANT — the evolution engine (C13) is alive and validated, and the ASC-slice")
        print("         loop is documented; the unified circulatory system (C1/C2/C12/C11) is unassessed.")
        print("         Next Step: Priority-0 substrate audit, then U1/U4 probes (post AE-003 closure).")
    else:
        print(" RED: DECEASED / SIMULACRUM — collection of disconnected modules.")
        print("      Next Step: Halt feature development. Focus entirely on U1 (Reality -> Knowledge) integration.")
    print("=" * 60)

    print("\n State table (honest contract; x=verified true, ?=unassessed, -=absent):")
    for c in contract["capabilities"]:
        h = highest_state(c["state"])
        marks = "".join(mark(c["state"], l) for l in ["D", "S", "R", "I", "V", "P"])
        print(f"  {c['id']:>3} {c['name']:<32} {marks}   highest={h or 'NONE'}   [{c.get('assessment', 'unassessed')}]")


if __name__ == "__main__":
    contract = load_contract(CONTRACT_PATH)
    check_vital_signs(contract)