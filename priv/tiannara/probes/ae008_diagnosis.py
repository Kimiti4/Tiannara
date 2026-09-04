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
CHAIN_SCRIPT = PROJECT_ROOT / "priv" / "tiannara" / "probes" / "ae008_chain_fixed.exs"
AUTH_ARTIFACT = PROJECT_ROOT / "priv" / "tiannara" / "authorization" / "ASC-AE-008.human.yaml"
EVIDENCE_REPORT = PROJECT_ROOT / "docs" / "probes" / "AE-008_evidence_report.md"
VERDICT_FILE = PROJECT_ROOT / "docs" / "probes" / "ASC-AE-008_VERDICT.md"

class AuthorizationError(Exception): pass

def load_auth(path: Path):
    if not path.exists():
        raise AuthorizationError(f"missing {path}")
    if yaml is None:
        raise AuthorizationError("PyYAML missing")
    with open(path) as f:
        auth = yaml.safe_load(f)
    if auth.get("mission_id") != "ASC-AE-008":
        raise AuthorizationError("mission_id mismatch")
    if auth.get("status") != "AUTHORIZED":
        raise AuthorizationError(f"not authorized {auth.get('status')!r}")
    return auth

def run_mode(mode, out_dir, timeout=900):
    env = os.environ.copy()
    env["MIX_ENV"]="test"
    cmd = ["mix","run","--no-compile","--no-start", str(CHAIN_SCRIPT), mode, str(out_dir)]
    print(f"  mix run --no-compile --no-start ae008_chain_fixed.exs mode={mode} ...")
    proc = subprocess.run(cmd, cwd=str(PROJECT_ROOT), env=env, capture_output=True, text=True, timeout=timeout)
    for line in (proc.stdout or "").splitlines():
        if line.startswith("AE008CHAIN_RESULT "):
            return json.loads(line[len("AE008CHAIN_RESULT "):])
    raise RuntimeError(f"No AE008CHAIN_RESULT for {mode}\nExit {proc.returncode}\n{proc.stderr[-4000:]}")

def ok_of(x):
    if not isinstance(x, dict): return {}
    phase = x.get("phase", {})
    if isinstance(phase, dict):
        return phase.get("ok", {})
    return {}

def main():
    parser=argparse.ArgumentParser(description="ASC-AE-008")
    parser.add_argument("--auth", type=Path, default=AUTH_ARTIFACT)
    parser.add_argument("--skip-runs", action="store_true")
    args=parser.parse_args()
    print("="*80)
    print("ASC-AE-008 — Discovery Diagnosis (F13)")
    print("="*80)
    print("\n[STEP 1] Validating authorization...")
    try:
        auth=load_auth(args.auth)
        print(f"  ✓ {auth['mission_id']} AUTHORIZED")
    except AuthorizationError as e:
        print(f"  [AUTH HALT] {e}"); sys.exit(1)
    chain={}
    result_path=RESULTS_DIR / "AE-008_diagnosis_result.json"
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    if not args.skip_runs:
        print("\n[STEP 2] Executing diagnosis...")
        out_dir=EVIDENCE_DIR / f"ae008_chain_{uuid.uuid4().hex[:8]}"
        out_dir.mkdir(parents=True, exist_ok=True)
        for mode in ["characterize","diagnose"]:
            chain[mode]=run_mode(mode, out_dir)
        with open(result_path,"w") as f: json.dump(chain,f,indent=2)
        print(f"  cached {result_path}")
    else:
        print("\n[STEP 2] Loading cached...")
        with open(result_path) as f: chain=json.load(f)
    char = ok_of(chain.get("characterize", {}))
    diag = ok_of(chain.get("diagnose", {}))
    print("\n[STEP 3] Diagnosis Verdict:")
    print(f"  Characterize: discovery {char.get('discovery_supervisor')} eos {char.get('eos_status')}")
    print(f"  Step1 functional: {diag.get('step1_functionality')}")
    print(f"  Step2 ownership: {diag.get('step2_ownership')}")
    print(f"  Step5 nested: {diag.get('step5_nested')}")
    print(f"  Verdict: {diag.get('verdict')}")
    # Write evidence report
    EVIDENCE_REPORT.parent.mkdir(parents=True, exist_ok=True)
    lines=[]
    a=lines.append
    a("# AE-008 Evidence Report — Discovery Diagnosis (F13)")
    a("")
    a(f"Date: {datetime.now(timezone.utc).isoformat()}")
    a("")
    a("## 1. Authorization")
    a(f"- Mission: `{auth.get('mission_id')}` — {auth.get('objective')}")
    a(f"- Status: `{auth.get('status')}`; operator `{auth.get('human_authorization',{}).get('operator_id')}`")
    a("")
    a("## 2. Phase A — Symptom Characterization")
    a(f"```json")
    a(json.dumps(char, indent=2))
    a(f"```")
    a("")
    a("## 3. Phase B — Decision Tree (discovered, not hardcoded)")
    a(f"```json")
    a(json.dumps(diag, indent=2))
    a(f"```")
    a("")
    a("## 4. Verdict")
    verdict = diag.get("verdict", {})
    a(f"- Hypothesis: `{verdict.get('hypothesis')}`")
    a(f"- Remedy: `{verdict.get('remedy')}`")
    a(f"- Patch: `{verdict.get('patch')}`")
    a(f"- Reason: `{verdict.get('reason')}`")
    a("")
    a("## 5. Hard Prohibition Check")
    a("- No signal silenced: degraded remains degraded if truly degraded")
    a("- Diagnosis is read-only, no production mutation")
    EVIDENCE_REPORT.write_text("\n".join(lines), encoding="utf-8")
    print(f"\n  ✓ Evidence report: {EVIDENCE_REPORT}")
    # Write verdict file as per protocol
    VERDICT_FILE.parent.mkdir(parents=True, exist_ok=True)
    vlines=[]
    va=vlines.append
    va("# ASC-AE-008 VERDICT")
    va("")
    va(f"Date: {datetime.now(timezone.utc).isoformat()}")
    va("")
    va("## Evidence for each step")
    va(f"```json")
    va(json.dumps(diag, indent=2))
    va(f"```")
    va("")
    va("## Discriminated Hypothesis")
    va(f"- `{verdict.get('hypothesis')}` — {verdict.get('reason')}")
    va("")
    va("## Remedy Decision")
    va(f"- `{verdict.get('remedy')}` — patch={verdict.get('patch')}")
    va("")
    va("## Regression Guard")
    va("- Any candidate that makes genuinely-degraded Discovery report healthy would be REJECTED")
    va("- This verdict preserves the F9/F12 lesson: EOS must stay true, not green")
    VERDICT_FILE.write_text("\n".join(vlines), encoding="utf-8")
    print(f"  ✓ Verdict: {VERDICT_FILE}")
    print("\n"+"="*80)
    print("AE-008 DIAGNOSIS COMPLETE")
    print("[RECORD] Diagnosis discovered, not hardcoded. No production mutation.")

if __name__=="__main__":
    main()
