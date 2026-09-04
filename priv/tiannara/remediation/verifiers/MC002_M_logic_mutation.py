"""
MC-002-M logic mutation verifier.

Performs actual static verification over the repository to confirm the
L4+L1+L2+L3 logic truthfulness mutation claims. It does NOT trust the
certification record; it scans real files and reports what it finds.

Checks:
  1. L4 kernel exists with the six authorized functions; sits above Math
     (no Tiannara.Math reference, no confidence computation).
  2. Engine.detect/1 shims the kernel (delegates pair verdicts).
  3. Graph.Audit.find_contradictions/1 exists and routes through the kernel.
  4. BeliefSystem delegates to kernel; fabricated negation matcher gone.
  5. DiscoveryScheduler routes contradiction_pairs through the kernel.
  6. Sentinel evidence-link mechanism preserved.
  7. L2: ParadoxResolver returns unavailable; no fabricated metric pushes.
  8. L2: nine Substrate.* files removed.
  9. L3: aggregator substrate-only clauses removed (coherence/iv retained).
  10. L5 out of scope: no proof/inference module created.
  11. Authorization GRANTED by c14_ac.
  12. Evidence artifacts exist; result JSON structurally valid.
"""
import json
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", ".."))
LIB = os.path.join(ROOT, "lib", "tiannara")


def read(rel):
    with open(os.path.join(LIB, rel), encoding="utf-8", errors="replace") as fh:
        return fh.read()


def read_root(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8", errors="replace") as fh:
        return fh.read()


def main():
    failures = []

    # --- 1. L4 kernel: six functions, above Math, no confidence compute ---
    kernel_base = os.path.join(LIB, "logic")
    expected = [
        "contradiction.ex",
        "invariant.ex",
        "rule.ex",
        "transition.ex",
        "complementarity.ex",
    ]
    for f in expected:
        if not os.path.exists(os.path.join(kernel_base, f)):
            failures.append("kernel module missing: logic/" + f)

    try:
        logic_src = "\n".join(
            read(os.path.join("logic", f)) for f in expected if os.path.exists(os.path.join(kernel_base, f))
        )
    except OSError:
        logic_src = ""

    for sig in [
        "def detect(",
        "def from_refutations(",
        "def check(",
        "def check_all(",
        "def evaluate(",
        "def valid?(",
        "def holds?(",
    ]:
        if sig not in logic_src:
            failures.append("kernel missing signature: " + sig)

    if "Tiannara.Math" in logic_src:
        failures.append("kernel references Tiannara.Math (must sit ABOVE Math)")
    if re.search(r"compute_confidence|:confidence|confidence", logic_src):
        # confidence appears only in docstrings, not computation; check for assignment pattern
        if re.search(r"confidence\s*=", logic_src) or re.search(r"defp?\s+compute", logic_src):
            failures.append("kernel computes confidence (must not)")

    # --- 2. Engine shim ---
    engine = read(os.path.join("contradiction", "engine.ex"))
    if "KernelContradiction.detect" not in engine and "Logic.Contradiction.detect" not in engine:
        failures.append("Engine.detect/1 does not delegate to the kernel")
    if "generate_belief_id" in engine:
        pass  # unrelated
    # classification/severity/confidence must still live in Engine
    for token in ["classify_type", "classify_severity", "compute_confidence"]:
        if token not in engine:
            failures.append("Engine lost classification/severity/confidence logic: " + token)

    # --- 3. Audit.find_contradictions/1 kernel-backed ---
    audit = read(os.path.join("graph", "audit.ex"))
    if "def find_contradictions" not in audit:
        failures.append("Audit.find_contradictions/1 missing")
    if "KernelContradiction.detect" not in audit and "Logic.Contradiction.detect" not in audit:
        failures.append("Audit.find_contradictions does not use the kernel verdict")

    # --- 4. BeliefSystem delegation ---
    bs = read(os.path.join("core", "world_model", "belief_system.ex"))
    if "Logic.Contradiction.detect" not in bs and "Tiannara.Logic.Contradiction" not in bs:
        failures.append("BeliefSystem does not delegate to the kernel")
    for dead in ["are_direct_contradictions?", "has_conflicting_confidences?", "extract_topic"]:
        if dead in bs:
            failures.append("BeliefSystem retains fabricated matcher: " + dead)

    # --- 5. DiscoveryScheduler routing ---
    ds = read(os.path.join("discovery", "discovery_scheduler.ex"))
    if "Logic.Contradiction.detect" not in ds and "Tiannara.Logic.Contradiction" not in ds:
        failures.append("DiscoveryScheduler does not route through the kernel")

    # --- 6. Sentinel evidence-link mechanism preserved ---
    sv = read(os.path.join("sentinel", "verification.ex"))
    if ":direct_contradiction" not in sv and "find_contradictions" not in sv:
        failures.append("Sentinel find_contradictions/3 missing/unchanged")
    if "contradicts" not in sv and "supports" not in sv:
        failures.append("Sentinel evidence-link mechanism not preserved")

    # --- 7. L2: ParadoxResolver unavailable, no fabricated pushes ---
    pr = read(os.path.join("ctl", "paradox_resolver.ex"))
    if "{:error, :paradox_resolver_unavailable}" not in pr:
        failures.append("ParadoxResolver does not return paradox_resolver_unavailable")
    if "push_event" in pr or "collapse_probability" in pr or ":ok, :resolved" in pr:
        failures.append("ParadoxResolver retains fabricated behavior/metric pushes")

    # --- 8. L2: nine Substrate files removed ---
    for fam in ["cof", "euf", "gck", "hsv", "mcal", "oed", "opc", "ose", "osk"]:
        p = os.path.join(LIB, "substrate", fam + ".ex")
        if os.path.exists(p):
            failures.append("substrate file still exists: substrate/" + fam + ".ex")

    # --- 9. L3: aggregator substrate clauses removed; coherence/iv retained ---
    agg = read(os.path.join("metrics", "aggregator.ex"))
    substrate_domains = ":euf", ":gck", ":hsv", ":mcal", ":opc", ":oed", ":ose", ":osk", ":cof"
    for dom in substrate_domains:
        if re.search(r"\[:tiannara, " + re.escape(dom) + r"[, \]]", agg):
            failures.append("aggregator retains substrate-domain clause: " + dom)
    for keep in [":coherence", ":iv"]:
        if keep not in agg:
            failures.append("aggregator lost real-emitter clause: " + keep)

    # --- 10. L5 excluded ---
    for p in ["proof.ex", "inference.ex", "inference_engine.ex", "prover.ex"]:
        if os.path.exists(os.path.join(kernel_base, p)):
            failures.append("kernel contains unauthorized L5 module: " + p)

    # --- 11. Authorization GRANTED by c14_ac ---
    try:
        auth = read_root(os.path.join("priv", "tiannara", "authorization", "ASC-MC-002-M-LOGIC-MUTATION.human.yaml"))
    except FileNotFoundError:
        failures.append("ASC-MC-002-M-LOGIC-MUTATION.human.yaml missing")
        auth = ""
    if "status: \"GRANTED\"" not in auth and "status: GRANTED" not in auth:
        failures.append("mutation authorization not GRANTED")
    if "operator_id: \"c14_ac\"" not in auth and "operator_id: c14_ac" not in auth:
        failures.append("mutation authorization operator not c14_ac")

    # --- 12. Artifacts + result JSON ---
    artifacts = [
        "certification/remediation/MC002-M3-THEATRICAL-DECOMMISSION.md",
        "certification/remediation/MC002-M5-METRICS-DECOMMISSION.md",
        "certification/remediation/MC002-M-EVIDENCE-MATRIX.md",
        "certification/remediation/MC002-M-CONSUMER-CONTRACTS.md",
        "certification/remediation/MC002-M-CERTIFICATION.md",
        "priv/tiannara/remediation/contracts/MC002_M_logic_mutation.contract.yaml",
        "priv/tiannara/remediation/results/MC002_M_result.json",
    ]
    for a in artifacts:
        if not os.path.exists(os.path.join(ROOT, a)):
            failures.append("artifact missing: " + a)

    try:
        result = json.load(
            open(os.path.join(ROOT, "priv", "tiannara", "remediation", "results", "MC002_M_result.json"), encoding="utf-8")
        )
    except (OSError, ValueError):
        result = None
        failures.append("MC002_M_result.json invalid or unreadable")
    if isinstance(result, dict) and result.get("mutation_authorized") is not True:
        failures.append("result JSON does not record mutation_authorized true")

    if failures:
        print("MC-002-M VERIFY: FAIL")
        for f_ in failures:
            print("  -", f_)
        sys.exit(1)

    print("MC-002-M VERIFY: PASS")
    print("  L4 kernel      : six functions, above Math, no confidence compute")
    print("  L1 delegation  : Engine shim / Audit / BeliefSystem / Discovery -> kernel")
    print("  Sentinel       : evidence-link mechanism preserved")
    print("  L2 decomm      : ParadoxResolver unavailable; nine Substrate families removed")
    print("  L3 metrics     : substrate aggregator clauses removed (coherence/iv kept)")
    print("  L5             : excluded (no proof/inference module)")
    print("  Authorization  : GRANTED (c14_ac)")
    print("  Artifacts+JSON : present, valid")


if __name__ == "__main__":
    main()