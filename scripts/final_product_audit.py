#!/usr/bin/env python3
"""Tiannara final-product release audit.

Run from repository root:
  python scripts/final_product_audit.py
  python scripts/final_product_audit.py --base-url http://127.0.0.1:8000

This is deliberately evidence-oriented: it never converts an unavailable
service into PASS and it flags hard-coded/mock surfaces for review.
"""
from __future__ import annotations
import argparse, ast, json, pathlib, re, subprocess, sys
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

ROOT=pathlib.Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument("--base-url",default="http://127.0.0.1:8000")
args=parser.parse_args()
checks=[]

def check(name, ok, detail):
    checks.append({"name":name,"status":"PASS" if ok else "FAIL","detail":detail})
    print(f"[{'PASS' if ok else 'FAIL'}] {name}: {detail}")

def run(name, cmd, cwd=ROOT, timeout=300):
    try:
        p=subprocess.run(cmd,cwd=cwd,text=True,capture_output=True,timeout=timeout)
        check(name,p.returncode==0,(p.stdout+p.stderr)[-1200:])
    except Exception as e: check(name,False,str(e))

def http(path, method="GET", body=None):
    try:
        data=None if body is None else json.dumps(body).encode()
        req=Request(args.base_url+path,data=data,method=method,headers={"Content-Type":"application/json"})
        with urlopen(req,timeout=8) as r: return r.status,json.loads(r.read())
    except Exception as e: return None,str(e)

# Static architecture checks
required=[
"tiannara_api/routes/chat.py",
"tiannara_core/integration/web_fetcher.py",
"tiannara_saas/app/dashboard/research/page.tsx",
"tiannara_saas/app/dashboard/cognitive-workspace/page.tsx",
"tiannara_observatory/apps/observatory_ui/src/app/page.tsx",
]
for p in required: check("required:"+p,(ROOT/p).exists(),str(ROOT/p))

# Python syntax
for p in [ROOT/"tiannara_api/routes/chat.py",ROOT/"scripts/final_product_audit.py"]:
    try: ast.parse(p.read_text(encoding="utf-8")); check("python-syntax:"+str(p.relative_to(ROOT)),True,"AST parsed")
    except Exception as e: check("python-syntax:"+str(p.relative_to(ROOT)),False,str(e))

# Explicit mock/theatrical indicators in runtime/API source.
patterns=re.compile(r'(?i)\b(?:mock_experiments|return get_mock_worlds|status: "operational"|confidence: 0\.95|TODO: Get from environment|coming soon)\b')
hits=[]
for base in [ROOT/"tiannara_api",ROOT/"tiannara_runtime",ROOT/"tiannara_observatory/apps/observatory_api"]:
    if base.exists():
        for p in base.rglob("*"):
            if p.suffix in {".py",".ex",".exs"} and p.is_file():
                try:
                    if patterns.search(p.read_text(errors="ignore")): hits.append(str(p.relative_to(ROOT)))
                except OSError: pass
check("theatrical-surface-scan",not hits,"No flagged patterns" if not hits else "Review: "+", ".join(hits[:20]))

# Live endpoint probes. These only PASS on real HTTP responses.
for path in ["/health","/api/v1/observatory/calibration/worlds"]:
    status,data=http(path)
    check("http:"+path,status==200,f"{status}: {data}")

# Chat and research probes require authentication in production; 401/403 is reported as blocked, not PASS.
for path,body in [
    ("/api/v1/chat",{"message":"Give me a concise system status and distinguish known from unknown."}),
    ("/api/v1/chat/research",{"query":"latest peer reviewed research on autonomous scientific discovery","num_results":2,"fetch_sources":False}),
]:
    status,data=http(path,"POST",body)
    check("http:"+path,status==200,f"{status}: {data if status==200 else 'authentication/dependency may be required'}")

# Optional full local suites; skipped when their toolchain is unavailable.
def tool(name): return subprocess.run(["bash","-lc",f"command -v {name} >/dev/null 2>&1"]).returncode==0
if tool("mix"):
    run("elixir-tests",["mix","test"],timeout=1800)
else: print("[SKIP] elixir-tests: mix unavailable")
if tool("npm"):
    run("saas-build",["npm","run","build"],cwd=ROOT/"tiannara_saas",timeout=1800)
    ui=ROOT/"tiannara_observatory/apps/observatory_ui"
    if (ui/"package.json").exists(): run("observatory-ui-build",["npm","run","build"],cwd=ui,timeout=1800)
else: print("[SKIP] node-builds: npm unavailable")
if tool("pytest"):
    run("python-tests",["pytest","-q"],timeout=1800)
else: print("[SKIP] python-tests: pytest unavailable")

failed=sum(x["status"]=="FAIL" for x in checks)
report={"checks":checks,"failed":failed,"generated_by":"scripts/final_product_audit.py"}
out=ROOT/"final_product_audit.json"; out.write_text(json.dumps(report,indent=2),encoding="utf-8")
print(f"\nAudit complete: {len(checks)} checks, {failed} failures. Report: {out}")
sys.exit(1 if failed else 0)
