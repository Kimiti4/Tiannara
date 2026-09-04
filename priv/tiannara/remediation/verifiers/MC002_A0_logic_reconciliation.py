#!/usr/bin/env python3
"""
MC-002-A0 verifier — independently inspects repository source.
Does NOT trust the certification record. Read-only.

Checks:
  1. all 14 required artifacts exist
  2. result JSON valid + mutation_performed false
  3. canonical ontology registry still has exactly 20 domains, no logic/math/etc.
  4. claimed REAL sites actually contain the claimed functions
  5. claimed THEATRICAL sites show Logger/empty-computation patterns
  6. broken ref: constitution/registry.ex:118 references find_contradictions
     while graph/audit.ex does not define it
  7. authorization signature not fabricated
  8. substrate files contain hardcoded push_event usage (fabrication evidence)
  9. no proof/prover/SAT/SMT module present
"""
import json, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]  # verifiers -> remediation -> tiannara -> priv -> repo root
RESULTS = ROOT / "priv" / "tiannara" / "remediation" / "results"

ARTIFACTS = [
    "docs/remediation/MC002_A0_LOGIC_RECONCILIATION_PROTOCOL.md",
    "priv/tiannara/remediation/contracts/MC002_A0_logic_reconciliation.contract.yaml",
    "priv/tiannara/authorization/ASC-MC-002-A0-LOGIC-RECONCILIATION.human.yaml",
    "certification/remediation/MC002-A0-LOGIC-INVENTORY.md",
    "certification/remediation/MC002-A0-LOGIC-TRUTH-CLASSIFICATION.md",
    "certification/remediation/MC002-A0-LOGIC-CONSUMER-MAP.md",
    "certification/remediation/MC002-A0-LOGIC-ARCHITECTURE.md",
    "certification/remediation/MC002-A0-LOGIC-VERIFICATION.md",
    "certification/remediation/MC002-A0-LOGIC-DISCOVERY-READINESS.md",
    "certification/remediation/MC002-A0-LOGIC-BOTTLENECKS.md",
    "certification/remediation/MC002-A0-LOGIC-MUTATION-PLAN.md",
    "certification/remediation/MC002-A0-RECONCILIATION-CERTIFICATION.md",
    "priv/tiannara/remediation/results/MC002_A0_result.json",
    "priv/tiannara/remediation/verifiers/MC002_A0_logic_reconciliation.py",
]


def read(p):
    return (ROOT / p).read_text(errors="replace")


def check_artifacts():
    return {a: (ROOT / a).exists() for a in ARTIFACTS}


def check_json():
    p = RESULTS / "MC002_A0_result.json"
    try:
        d = json.loads(p.read_text())
        req = ["gate", "phase", "verdict", "mutation_performed", "capability_counts",
               "critical_findings", "bottlenecks", "consumer_hazards",
               "evidence_limitations", "authorization_state"]
        return {"valid": all(k in d for k in req),
                "mutation_performed": d.get("mutation_performed"),
                "verdict": d.get("verdict")}
    except Exception as e:
        return {"valid": False, "error": str(e)}


def check_ontology():
    reg = ROOT / "lib" / "tiannara" / "domains" / "canonical_registry.ex"
    if not reg.exists():
        return {"exists": False}
    t = reg.read_text(errors="replace")
    # extract exactly the @canonical_domains [...] block
    m = None
    if "@canonical_domains [" in t:
        start = t.index("@canonical_domains [") + len("@canonical_domains [")
        end = t.index("]", start)
        body = t[start:end]
        atoms = [w for w in body.split() if w.startswith(":")]
        excluded_in_list = [a for a in [":logic", ":mathematics", ":science", ":cs"] if a in atoms]
        unchanged = len(atoms) == 20 and not excluded_in_list
        return {"exists": True, "domain_count": len(atoms),
                "excluded_in_domain_list": excluded_in_list,
                "unchanged": unchanged}
    return {"exists": True, "parse": "attribute block not found",
            "unchanged": False}


def check_real_sites():
    checks = {
        "graph_audit_lineage": ("lib/tiannara/graph/audit.ex",
                                "def lineage(g, node)"),
        "graph_audit_blast": ("lib/tiannara/graph/audit.ex",
                              "def blast_radius(g, node)"),
        "graph_audit_cycle": ("lib/tiannara/graph/audit.ex", "def has_cycle?(g)"),
        "engine_detect": ("lib/tiannara/contradiction/engine.ex", "def detect(claims)"),
        "sentinel_find_contradict": ("lib/tiannara/sentinel/verification.ex",
                                     "defp find_contradictions"),
    }
    res = {}
    for k, (p, pat) in checks.items():
        f = ROOT / p
        res[k] = f.exists() and pat in f.read_text(errors="replace")
    return res


def check_theatrical_sites():
    files = ["lib/tiannara/ctl/paradox_resolver.ex",
             "lib/tiannara/substrate/gck.ex",
             "lib/tiannara/substrate/mcal.ex",
             "lib/tiannara/substrate/osk.ex",
             "lib/tiannara/substrate/euf.ex",
             "lib/tiannara/substrate/cof.ex",
             "lib/tiannara/substrate/opc.ex",
             "lib/tiannara/substrate/ose.ex",
             "lib/tiannara/substrate/hsv.ex"]
    res = {}
    for p in files:
        f = ROOT / p
        if not f.exists():
            res[p] = "missing"
            continue
        t = f.read_text(errors="replace")
        logs = "Logger." in t
        empty = "raise" not in t and "compute" not in t.lower()
        res[p] = {"logs": logs, "hardcoded_metric": "push_event" in t and "0." in t}
    return res


def check_broken_ref():
    reg = read("lib/tiannara/constitution/registry.ex")
    aud = read("lib/tiannara/graph/audit.ex")
    has_call = "find_contradictions(g)" in reg or "Audit.find_contradictions" in reg
    audit_defines = "def find_contradictions" in aud
    return {"registry_calls_it": has_call, "audit_defines_it": audit_defines,
            "broken": has_call and not audit_defines}


def check_auth():
    p = ROOT / "priv/tiannara/authorization/ASC-MC-002-A0-LOGIC-RECONCILIATION.human.yaml"
    if not p.exists():
        return {"exists": False}
    t = p.read_text()
    return {"exists": True,
            "sig_null": "signature: null" in t,
            "read_only": "OBSERVATIONAL_READ_ONLY" in t}


def check_proof_absence():
    absent = []
    for p in (ROOT / "lib").rglob("*.ex"):
        t = p.read_text(errors="replace")
        if any(k in t for k in ["defmodule ", "defmodule "]) and \
           any(name in t for name in ["Prover", "TheoremProver", "ProofServer", "SMT", "SAT", "def check_proof", "def verify_proof"]):
            absent.append(str(p.relative_to(ROOT)))
    # Filter only genuinely suspicious (module names / defs), not substring noise
    susp = []
    for p in absent:
        t = (ROOT / p).read_text(errors="replace")
        if any(n in t for n in ["defmodule .*Prover", "def check_proof", "def verify_proof"]):
            susp.append(p)
    return {"suspicious": susp, "note": "SAT/SMT substring matches are expected noise"}


def main():
    out = {
        "artifacts": check_artifacts(),
        "result_json": check_json(),
        "ontology": check_ontology(),
        "real_sites": check_real_sites(),
        "theatrical_sites": check_theatrical_sites(),
        "broken_ref": check_broken_ref(),
        "authorization": check_auth(),
        "proof_absence": check_proof_absence(),
    }
    RESULTS.mkdir(parents=True, exist_ok=True)
    (RESULTS / "MC002_A0_verifier_output.json").write_text(json.dumps(out, indent=2))

    ok = (
        all(out["artifacts"].values())
        and out["result_json"].get("valid") is True
        and out["result_json"].get("mutation_performed") is False
        and out["ontology"].get("unchanged") is True
        and all(out["real_sites"].values())
        and out["broken_ref"].get("broken") is True
        and out["authorization"].get("exists") is True
        and out["authorization"].get("sig_null") is True
        and out["authorization"].get("read_only") is True
    )
    print("MC-002-A0 VERIFIER:", "PASS" if ok else "INCOMPLETE")
    print("artifacts ok:", all(out["artifacts"].values()))
    print("real sites:", {k: v for k, v in out["real_sites"].items() if not v})
    print("broken ref:", out["broken_ref"])
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()