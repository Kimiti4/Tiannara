#!/usr/bin/env python3
"""TCP-002.3 Stage 0 — EFDI source, caller, test and lifecycle inventory.

Produces a source-backed inventory of every module in the application-stack
forecasting subsystem, together with the evidence needed to decide its role in
the TCP-002.3 integration.

Everything reported here is derived from the source at the current checkout.
No claim is made from a module's name or from an architecture document.

Usage:
    python tools/tcp/tcp0023_efdi_inventory.py [--repo ROOT] [--out-dir DIR]

Outputs:
    certification/tcp/TCP_002_3_EFDI_INVENTORY.csv
    certification/tcp/TCP_002_3_EFDI_INVENTORY.md
"""

import argparse
import csv
import io
import os
import re
from collections import Counter, defaultdict

FORECASTING_DIR = os.path.join("lib", "tiannara", "forecasting")
SKIP = {"_build", "deps", "node_modules", ".git", "__pycache__", "target"}
for d in ("pytest-cache-files",):
    SKIP.add(d)


def read(path):
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        return fh.read()


def strip_docs(text):
    text = re.sub(r"@moduledoc\s+\"\"\".*?\"\"\"", "", text, flags=re.S)
    text = re.sub(r"@moduledoc\s+\"(?:[^\"\\]|\\.)*\"", "", text)
    text = re.sub(r"@doc\s+\"\"\".*?\"\"\"", "", text, flags=re.S)
    text = re.sub(r"@doc\s+\"(?:[^\"\\]|\\.)*\"", "", text)
    text = re.sub(r"#[^\n]*", "", text)
    return text


def first_sentence(doc):
    doc = " ".join(doc.split())
    if not doc:
        return ""
    m = re.match(r"(.*?[.!?])(\s|$)", doc)
    return (m.group(1) if m else doc)[:220]


PERSISTENCE = {
    "ets": r":ets\.(new|insert|lookup|delete|tab2list|match|select)",
    "dets": r":dets\.(open|open_file)",
    "persistent_term": r":persistent_term\.",
    "mnesia": r":mnesia\.",
    "repo": r"\bRepo\.(all|one|insert|update|transaction|get)",
    "file": r"\bFile\.(write|read|rm|stream|write!)",
    "process_state": r"Agent\.|GenServer\.start|use GenServer|use Agent",
    "no_persistence": None,
}


def public_api(body):
    return re.findall(r"^\s*def\s+(\w+)", body, re.M)


def error_atoms(body):
    return sorted(set(re.findall(r"\{:error,\s*:(\w+)\}", body)))


def classify(module, body, callers, testers, persistence):
    """Repository-grounded status for one module."""
    pubs = public_api(body)
    ops = [p for p in pubs if not p.startswith("_")]

    if not ops:
        return "stub", "no public functions"

    # a module whose every public function returns a fixed literal is a stub
    returns = re.findall(r"def\s+(\w+)\([^)]*\)\s*(?:do|,\s*do:)\s*(?:\n\s*)?\{?(:ok,|:error,|%\{|\{:ok)", body)
    if returns and len(returns) >= max(1, len(ops)):
        return "stub", "public API returns canned values only"

    if persistence == [] and not callers and not testers:
        return "disconnected", "no persistence, no callers, no tests"

    if not callers and not testers:
        return "disconnected", "referenced only inside the forecasting directory"

    if not testers:
        return "partial", "no test references"

    return "implemented", ""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", default=os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))
    ap.add_argument("--out-dir", default=None)
    args = ap.parse_args()

    repo = os.path.abspath(args.repo)
    out_dir = args.out_dir or os.path.join(repo, "certification", "tcp")
    os.makedirs(out_dir, exist_ok=True)

    fc_root = os.path.join(repo, FORECASTING_DIR)

    # ---- index the whole repository ----------------------------------------
    sources, tests = {}, {}
    for dp, dn, fn in os.walk(repo):
        dn[:] = [d for d in dn if d not in SKIP and not d.startswith("pytest-cache-files")]
        for f in fn:
            p = os.path.join(dp, f)
            rel = os.path.relpath(p, repo).replace("\\", "/")
            if f.endswith(".ex"):
                sources[rel] = read(p)
            elif f.endswith(".exs"):
                tests[rel] = read(p)

    module_re = re.compile(r"defmodule\s+([A-Za-z0-9_.]+)\s+do")
    fc_modules = {}

    for rel, text in sources.items():
        if not rel.startswith(FORECASTING_DIR.replace("\\", "/") + "/"):
            continue
        for name in module_re.findall(text):
            fc_modules[name] = rel

    # who mentions whom
    mentioners = defaultdict(set)
    for rel, text in sources.items():
        for name in module_re.findall(text):
            for other in fc_modules:
                if other != name and re.search(r"\b" + re.escape(other) + r"\b", text):
                    mentioners[other].add(rel)
    for rel, text in tests.items():
        for name in module_re.findall(text):
            for other in fc_modules:
                if re.search(r"\b" + re.escape(other) + r"\b", text):
                    mentioners[other].add(rel)

    testers = defaultdict(set)
    for rel, text in tests.items():
        for name in fc_modules:
            if re.search(r"\b" + re.escape(name) + r"\b", text):
                testers[name].add(rel)

    # ---- per-module rows ---------------------------------------------------
    rows = []
    for name in sorted(fc_modules):
        rel = fc_modules[name]
        raw = sources[rel]
        body = strip_docs(raw)
        doc_m = re.search(r'@moduledoc\s+"""(.*?)"""', raw, re.S) or re.search(r'@moduledoc\s+"((?:[^"\\]|\\.)*)"', raw)
        doc = doc_m.group(1) if doc_m else ""
        pubs = public_api(body)
        errs = error_atoms(body)
        persistence = [k for k, pat in PERSISTENCE.items() if pat and re.search(pat, body)]

        callers = sorted(mentioners.get(name, set()) - {rel})
        external_callers = [c for c in callers if not c.startswith(FORECASTING_DIR.replace("\\", "/"))]
        test_refs = sorted(testers.get(name, set()))

        status, note = classify(name, body, callers, test_refs, persistence)

        rows.append({
            "module": name,
            "path": rel,
            "responsibility": first_sentence(doc),
            "public_functions": len(pubs),
            "public_api": ", ".join(pubs[:12]),
            "error_atoms": ", ".join(errs[:10]),
            "persistence": ", ".join(persistence) if persistence else "none",
            "callers_total": len(callers),
            "callers_outside_forecasting": len(external_callers),
            "external_callers": "; ".join(external_callers[:5]),
            "test_files": "; ".join(test_refs[:5]),
            "test_count": len(test_refs),
            "status": status,
            "note": note,
        })

    # ---- write CSV ---------------------------------------------------------
    cols = ["module", "path", "responsibility", "public_functions", "public_api",
            "error_atoms", "persistence", "callers_total", "callers_outside_forecasting",
            "external_callers", "test_files", "test_count", "status", "note"]
    csv_path = os.path.join(out_dir, "TCP_002_3_EFDI_INVENTORY.csv")
    with open(csv_path, "w", encoding="utf-8", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=cols, lineterminator="\n")
        w.writeheader()
        for r in rows:
            w.writerow(r)

    # ---- write Markdown ----------------------------------------------------
    by_status = Counter(r["status"] for r in rows)
    with_persist = [r for r in rows if r["persistence"] != "none"]
    with_tests = [r for r in rows if r["test_count"] > 0]
    externally = [r for r in rows if r["callers_outside_forecasting"] > 0]
    orphan = [r for r in rows if r["callers_outside_forecasting"] == 0]

    md = io.StringIO()
    md.write("# TCP-002.3 Stage 0 — EFDI Source and Caller Inventory\n\n")
    md.write("**Generated by** `tools/tcp/tcp0023_efdi_inventory.py` — re-derivable from source.\n")
    md.write(f"**Scope:** `{FORECASTING_DIR}/`\n")
    md.write(f"**HEAD:** `{os.popen('git -C "%s" rev-parse HEAD' % repo).read().strip()}`\n\n")
    md.write(f"**Modules inventoried: {len(rows)}**\n\n")

    md.write("## 1. Status summary\n\n")
    md.write("| Status | Modules |\n|---|---|\n")
    for k, v in by_status.most_common():
        md.write(f"| `{k}` | {v} |\n")
    md.write("\n")
    md.write("| Reachability measure | Modules |\n|---|---|\n")
    md.write(f"| Have at least one test reference | {len(with_tests)} of {len(rows)} |\n")
    md.write(f"| Have at least one caller outside the forecasting directory | {len(externally)} of {len(rows)} |\n")
    md.write(f"| Have **no** caller outside the forecasting directory | {len(orphan)} of {len(rows)} |\n")
    md.write(f"| Have some form of persistence | {len(with_persist)} of {len(rows)} |\n\n")

    md.write("## 2. The distinction that matters\n\n")
    md.write("Reachable from the public API is **not** operationally exercised, and "
             "operationally exercised is **not** independently verified. The inventory "
             "keeps these apart:\n\n")
    md.write("| Class | Meaning |\n|---|---|\n")
    md.write("| `implemented` | has public functions, at least one test reference |\n")
    md.write("| `partial` | has public functions but no test reference |\n")
    md.write("| `disconnected` | no caller outside its own directory, or nothing to persist |\n")
    md.write("| `stub` | public API returns canned values only |\n\n")

    md.write("## 3. Modules by status\n\n")
    for status in ("implemented", "partial", "disconnected", "stub"):
        sub = [r for r in rows if r["status"] == status]
        if not sub:
            continue
        md.write(f"### 3.{['implemented','partial','disconnected','stub'].index(status)+1} {status} ({len(sub)})\n\n")
        md.write("| Module | Public fns | Persistence | Ext. callers | Tests | Note |\n|---|---|---|---|---|---|\n")
        for r in sorted(sub, key=lambda x: x["module"]):
            md.write(f"| `{r['module']}` | {r['public_functions']} | {r['persistence']} "
                     f"| {r['callers_outside_forecasting']} | {r['test_count']} | {r['note']} |\n")
        md.write("\n")

    md.write("## 4. Persistence inventory\n\n")
    md.write("| Module | Mechanism |\n|---|---|\n")
    for r in sorted(with_persist, key=lambda x: x["module"]):
        md.write(f"| `{r['module']}` | {r['persistence']} |\n")
    md.write("\n")

    md.write("## 5. Publicly reachable but externally unused\n\n")
    md.write("These modules are internally coherent and have no consumer outside the "
             "forecasting directory. They are the surface TCP-002.3 must integrate.\n\n")
    md.write("| Module | Responsibility | Public API (first 8) |\n|---|---|---|\n")
    for r in sorted(orphan, key=lambda x: x["module"]):
        md.write(f"| `{r['module']}` | {r['responsibility'] or '—'} | {r['public_api'][:150]} |\n")
    md.write("\n")

    md.write("## 6. Error contracts already in use\n\n")
    all_errors = Counter()
    for r in rows:
        for e in [x.strip() for x in r["error_atoms"].split(",") if x.strip()]:
            all_errors[e] += 1
    md.write("| Error atom | Modules |\n|---|---|\n")
    for e, c in all_errors.most_common():
        md.write(f"| `:{e}` | {c} |\n")
    md.write("\n")

    md_path = os.path.join(out_dir, "TCP_002_3_EFDI_INVENTORY.md")
    with open(md_path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(md.getvalue())

    print("modules inventoried:", len(rows))
    print("status:", dict(by_status))
    print("with tests:", len(with_tests), " externally called:", len(externally), " orphan:", len(orphan))
    print("with persistence:", len(with_persist))
    print("wrote:", csv_path)
    print("wrote:", md_path)


if __name__ == "__main__":
    main()
