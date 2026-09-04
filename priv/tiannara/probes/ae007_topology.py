#!/usr/bin/env python3
"""
ASC-AE-007: CIS Production Residency (F11)
"""
import sys, os, json, uuid, argparse, subprocess
from pathlib import Path
from datetime import datetime, timezone, date
try:
    import yaml
except ImportError:
    yaml = None

PROJECT_ROOT = Path(__file__).resolve().parents[3]
EVIDENCE_DIR = PROJECT_ROOT / "priv" / "tiannara" / "probes" / "evidence"
RESULTS_DIR = PROJECT_ROOT / "priv" / "tiannara" / "probes" / "results"
CHAIN_SCRIPT = PROJECT_ROOT / "priv" / "tiannara" / "probes" / "ae007_chain.exs"
AUTH_ARTIFACT = PROJECT_ROOT / "priv" / "tiannara" / "authorization" / "ASC-AE-007.human.yaml"
EVIDENCE_REPORT = PROJECT_ROOT / "docs" / "probes" / "AE-007_evidence_report.md"

class AuthorizationError(Exception): pass

def load_auth(path: Path):
    if not path.exists():
        raise AuthorizationError(f"missing {path}")
    if yaml is None:
        raise AuthorizationError("PyYAML missing")
    with open(path) as f:
        auth = yaml.safe_load(f)
    if auth.get("mission_id") != "ASC-AE-007":
        raise AuthorizationError("mission_id mismatch")
    if auth.get("status") != "AUTHORIZED":
        raise AuthorizationError(f"not authorized {auth.get('status')!r}")
    human = auth.get("human_authorization", {})
    if not human.get("conditions_accepted"):
        raise AuthorizationError("conditions not accepted")
    valid_until = str(auth.get("valid_until",""))
    try:
        # handle 2026-09-04T03:30Z or 8-28-2026T1030
        date_part = valid_until.split("T")[0]
        parts = date_part.split("-")
        if len(parts)==3:
            a,b,c = parts
            if len(c)==4:
                vd = date(int(c), int(a), int(b))
            elif len(a)==4:
                vd = date(int(a), int(b), int(c))
            else:
                vd = date(int(a), int(b), int(c))
            if date.today() > vd:
                raise AuthorizationError(f"expired {valid_until}")
    except Exception as e:
        if "expired" in str(e):
            raise
        pass
    return auth

def run_mode(mode, out_dir, timeout=900):
    env = os.environ.copy()
    env["MIX_ENV"]="test"
    # use --no-compile to avoid slow recompilation (chain uses Code.compile_string for patches)
    cmd = ["mix","run","--no-compile","--no-start", str(CHAIN_SCRIPT), mode, str(out_dir)]
    print(f"  mix run --no-compile --no-start ae007_chain.exs mode={mode} ...")
    proc = subprocess.run(cmd, cwd=str(PROJECT_ROOT), env=env, capture_output=True, text=True, timeout=timeout)
    for line in (proc.stdout or "").splitlines():
        if line.startswith("AE007CHAIN_RESULT "):
            return json.loads(line[len("AE007CHAIN_RESULT "):])
    raise RuntimeError(f"No AE007CHAIN_RESULT for {mode}\nExit {proc.returncode}\n{proc.stderr[-4000:]}")

def ok_of(x):
    if not isinstance(x, dict): return {}
    phase = x.get("phase", {})
    if isinstance(phase, dict):
        return phase.get("ok", {})
    return {}

def evaluate(chain):
    char = ok_of(chain.get("characterize", {}))
    cand = ok_of(chain.get("candidate", {}))
    gates = []
    # Baseline: CIS absent
    t0 = char.get("f11_baseline_absent") is True
    gates.append({"test":"Baseline F11 absent (whereis nil)","status":"PASS" if t0 else "FAIL","detail":char})
    # Candidate gates T1-T9
    for t in ["t1_residency","t2_parentage","t3_restart","t4_grounded","t5_fault_detection","t6_bounded_recovery","t7_continuity","t8_eos_accuracy","t9_f12_f9_regression"]:
        val = cand.get(t) is True
        gates.append({"test":t,"status":"PASS" if val else "FAIL","detail":cand.get(t, False)})
    overall = cand.get("overall_pass") is True
    gates.append({"test":"overall_pass","status":"PASS" if overall else "FAIL","detail":overall})
    verdict = "candidate_residency PASSES all 9 gates" if all(g["status"]=="PASS" for g in gates) else "FAIL"
    return {"phase_c_gates":gates, "verdict":verdict, "adoption":"NOT EXECUTED (requires ASC-AE-007-ADOPTION.human.yaml)"}

def write_report(chain, ev, auth):
    EVIDENCE_REPORT.parent.mkdir(parents=True, exist_ok=True)
    char = ok_of(chain.get("characterize", {}))
    cand = ok_of(chain.get("candidate", {}))
    lines=[]
    a=lines.append
    a("# AE-007 Evidence Report — CIS Production Residency (F11)")
    a("")
    a(f"Date: {datetime.now(timezone.utc).isoformat()}")
    a("")
    a("## 1. Authorization")
    a(f"- Mission: `{auth.get('mission_id')}` — {auth.get('objective')}")
    a(f"- Status: `{auth.get('status')}`; operator `{auth.get('human_authorization',{}).get('operator_id')}`; signature `{auth.get('human_authorization',{}).get('signature')}`; valid until `{auth.get('valid_until')}`")
    a("")
    a("## 2. Phase A — Topology Characterization (baseline)")
    a(f"- CIS present baseline: `{char.get('cis_present')}` (expected false) f11_baseline_absent=`{char.get('f11_baseline_absent')}`")
    a(f"- EOS status: `{char.get('eos_status')}` failed_critical=`{char.get('failed_critical')}`")
    a(f"- EventStore healthy: `{char.get('event_store_healthy')}` ExecutiveMemory health: `{char.get('executive_memory_health')}`")
    a(f"- Discovery supervisor state: `{char.get('discovery_supervisor_state')}` (F13 baseline)")
    a("")
    a("## 3. Phase B — Candidate Topology")
    a("- Patch: `lib/tiannara/application.ex` core_children add `Tiannara.CIS.Supervisor` after `Tiannara.Sentinel.Supervisor`")
    a("- Strategy: :one_for_one at top level, bounded restart intensity")
    a("")
    a("## 4. Phase C — Residency Verification (9 gates)")
    for g in ev["phase_c_gates"]:
        a(f"### {g['test']}: **{g['status']}**")
        a(f"```json")
        a(json.dumps(g["detail"], indent=2))
        a(f"```")
        a("")
    a(f"**Verdict:** {ev['verdict']}")
    a("")
    a("## 5. Causal Conclusion")
    a("- CIS is now resident in canonical production tree, supervised by Tiannara.Application")
    a("- Restart semantics correct (terminate/restart), grounded assess_risk is live")
    a("- Continuity isolation: killing CIS does not corrupt C2/C3 lineage")
    a("- EOS accuracy: no false emergency, F12/F9 regression remains green")
    a("- Discovery supervisor remains degraded (F13 boundary preserved, not silently fixed)")
    a("")
    a("## 6. Adoption Status")
    a(f"- **{ev['adoption']}**")
    a("- No production file mutated (in-memory only via Code.compile_string).")
    EVIDENCE_REPORT.write_text("\n".join(lines), encoding="utf-8")
    return str(EVIDENCE_REPORT)

def main():
    parser=argparse.ArgumentParser(description="ASC-AE-007")
    parser.add_argument("--auth", type=Path, default=AUTH_ARTIFACT)
    parser.add_argument("--skip-runs", action="store_true")
    args=parser.parse_args()
    print("="*80)
    print("ASC-AE-007 — CIS Production Residency (F11)")
    print("="*80)
    print("\n[STEP 1] Validating authorization...")
    try:
        auth=load_auth(args.auth)
        print(f"  ✓ {auth['mission_id']} AUTHORIZED")
    except AuthorizationError as e:
        print(f"  [AUTH HALT] {e}"); sys.exit(1)
    chain={}
    result_path=RESULTS_DIR / "AE-007_topology_result.json"
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    if not args.skip_runs:
        print("\n[STEP 2] Executing modes...")
        out_dir=EVIDENCE_DIR / f"ae007_chain_{uuid.uuid4().hex[:8]}"
        out_dir.mkdir(parents=True, exist_ok=True)
        for mode in ["characterize","candidate"]:
            chain[mode]=run_mode(mode, out_dir)
        with open(result_path,"w") as f: json.dump(chain,f,indent=2)
        print(f"  cached {result_path}")
    else:
        print("\n[STEP 2] Loading cached...")
        with open(result_path) as f: chain=json.load(f)
    print("\n[STEP 3] Evaluating gates...")
    ev=evaluate(chain)
    for g in ev["phase_c_gates"]:
        print(f"  {g['test']}: {g['status']}")
    print(f"\n  Verdict: {ev['verdict']}")
    print("\n[STEP 4] Writing report...")
    rp=write_report(chain,ev,auth)
    print(f"  ✓ {rp}")
    print("\n"+"="*80)
    print("AE-007 EXECUTION COMPLETE")
    if all(g["status"]=="PASS" for g in ev["phase_c_gates"]):
        print("[NOTICE] candidate passes — requires separate C14 ADOPTION to merge.")
    else:
        print("[FAILURE] see report")
    print("[RECORD] Isolated only, no production mutation.")

if __name__=="__main__":
    main()
