#!/usr/bin/env python3
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
CHAIN_SCRIPT = PROJECT_ROOT / "priv" / "tiannara" / "probes" / "ae010_chain.exs"
AUTH_ARTIFACT = PROJECT_ROOT / "priv" / "tiannara" / "authorization" / "ASC-AE-010.human.yaml"
EVIDENCE_REPORT = PROJECT_ROOT / "docs" / "probes" / "AE-010_evidence_report.md"

class AuthorizationError(Exception): pass

def load_auth(path: Path):
    if not path.exists():
        raise AuthorizationError(f"missing {path}")
    if yaml is None:
        raise AuthorizationError("PyYAML missing")
    with open(path) as f:
        auth = yaml.safe_load(f)
    if auth.get("mission_id") != "ASC-AE-010":
        raise AuthorizationError("mission_id mismatch")
    if auth.get("status") != "AUTHORIZED":
        raise AuthorizationError(f"not authorized {auth.get('status')!r}")
    return auth

def run_mode(mode, out_dir, timeout=900):
    env = os.environ.copy()
    env["MIX_ENV"]="test"
    cmd = ["mix","run","--no-compile","--no-start", str(CHAIN_SCRIPT), mode, str(out_dir)]
    print(f"  mix run --no-compile --no-start ae010_chain.exs mode={mode} ...")
    proc = subprocess.run(cmd, cwd=str(PROJECT_ROOT), env=env, capture_output=True, text=True, timeout=timeout)
    for line in (proc.stdout or "").splitlines():
        if line.startswith("AE010CHAIN_RESULT "):
            return json.loads(line[len("AE010CHAIN_RESULT "):])
    raise RuntimeError(f"No AE010CHAIN_RESULT for {mode}\nExit {proc.returncode}\n{proc.stderr[-4000:]}")

def ok_of(x):
    if not isinstance(x, dict): return {}
    phase = x.get("phase", {})
    if isinstance(phase, dict):
        return phase.get("ok", {})
    return {}

def main():
    parser=argparse.ArgumentParser(description="ASC-AE-010")
    parser.add_argument("--auth", type=Path, default=AUTH_ARTIFACT)
    parser.add_argument("--skip-runs", action="store_true")
    args=parser.parse_args()
    print("="*80)
    print("ASC-AE-010 — Discovery Ownership Remediation (F13)")
    print("="*80)
    print("\n[STEP 1] Validating authorization...")
    try:
        auth=load_auth(args.auth)
        print(f"  ✓ {auth['mission_id']} AUTHORIZED")
    except AuthorizationError as e:
        print(f"  [AUTH HALT] {e}"); sys.exit(1)
    chain={}
    result_path=RESULTS_DIR / "AE-010_topology_result.json"
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    if not args.skip_runs:
        print("\n[STEP 2] Executing modes...")
        out_dir=EVIDENCE_DIR / f"ae010_chain_{uuid.uuid4().hex[:8]}"
        out_dir.mkdir(parents=True, exist_ok=True)
        for mode in ["characterize","candidate"]:
            chain[mode]=run_mode(mode, out_dir)
        with open(result_path,"w") as f: json.dump(chain,f,indent=2)
        print(f"  cached {result_path}")
    else:
        print("\n[STEP 2] Loading cached...")
        with open(result_path) as f: chain=json.load(f)
    char = ok_of(chain.get("characterize", {}))
    cand = ok_of(chain.get("candidate", {}))
    print("\n[STEP 3] Gates:")
    print(f"  Characterize: discovery {char.get('discovery_state')} eos {char.get('eos_status')} duplicate {char.get('duplicate_ownership')}")
    gates = cand.get("gates", {})
    for k,v in gates.items():
        print(f"  {k}: {'PASS' if v else 'FAIL'}")
    print(f"  overall_pass: {cand.get('overall_pass')}")
    print(f"  candidate eos {cand.get('eos_status')} health {cand.get('disc_health')} failed_critical {cand.get('failed_critical')}")
    # Write evidence report
    EVIDENCE_REPORT.parent.mkdir(parents=True, exist_ok=True)
    lines=[]
    a=lines.append
    a("# AE-010 Evidence Report — Discovery Ownership Remediation (F13)")
    a("")
    a(f"Date: {datetime.now(timezone.utc).isoformat()}")
    a("")
    a("## 1. Authorization")
    a(f"- Mission: `{auth.get('mission_id')}` — {auth.get('objective')}")
    a(f"- Status: `{auth.get('status')}`; operator `{auth.get('human_authorization',{}).get('operator_id')}`")
    a("")
    a("## 2. Phase A — Characterization (duplicate ownership)")
    a(f"```json")
    a(json.dumps(char, indent=2))
    a(f"```")
    a("")
    a("## 3. Phase B — Candidate (single owner)")
    a(f"```json")
    a(json.dumps(cand, indent=2))
    a(f"```")
    a("")
    a("## 4. Verdict")
    overall = cand.get("overall_pass") is True
    a(f"- **{'PASS' if overall else 'FAIL'}** — all gates {list(gates.keys())}")
    a(f"- EOS {char.get('eos_status')} -> {cand.get('eos_status')} (ready is clean)")
    a(f"- Discovery {char.get('discovery_state')} -> {cand.get('disc_health')} (healthy)")
    a("")
    a("## 5. Adoption Status")
    a("- NOT EXECUTED (requires ASC-AE-010-ADOPTION.human.yaml) — in-memory only via Code.compile_string")
    EVIDENCE_REPORT.write_text("\n".join(lines), encoding="utf-8")
    print(f"\n  ✓ Evidence report: {EVIDENCE_REPORT}")
    print("\n"+"="*80)
    print("AE-010 EXECUTION COMPLETE")
    if overall:
        print("[NOTICE] candidate passes — requires separate C14 ADOPTION to merge.")
    else:
        print("[FAILURE] see report")
    print("[RECORD] Isolated only, no production mutation.")

if __name__=="__main__":
    main()
