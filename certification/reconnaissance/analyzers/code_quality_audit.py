"""
Move 6 — Code-quality audit analyzer (master.md section 4).

Deterministic, read-only, T0-bound. Measures T0 .ex/.exs/.py files against
objective thresholds and emits CODE findings with file:line evidence.

What this analyzer does NOT do (explicitly out of scope):
  - semantic judgments (god-process intent, abstraction leakage, coupling)
  - call graphs / circular-dependency detection (requires graphs; deferred)
  - magic-value judgments (cannot distinguish legitimate constants)
  - supervision-policy judgments (strategy choice is a design decision)
  - runtime behavior claims (growth, leaks, hotspots, races need execution)
  - remediation, refactoring suggestions, or severity-as-verdict

Severity bands are mechanical (line-count/count-based) and documented in
the output. A finding is an observation with evidence, not a verdict that
code must change.

Reads T0 content from a caller-provided worktree path. Never touches git
beyond what the caller already did. Writes exactly one file when asked.
"""
from __future__ import annotations

import os
import re
import sys

sys.dont_write_bytecode = True
import sys

sys.dont_write_bytecode = True

# ---------------------------------------------------------------------------
# Objective criteria. Each criterion: id, what is measured, threshold,
# severity band, rationale. Thresholds are documented so a later move can
# re-run with different bands and compare.
# ---------------------------------------------------------------------------
CRITERIA = [
    {
        "id": "CQ-C01",
        "family": "complexity",
        "name": "excessive-function-length",
        "measures": "lines per function body (Elixir def/defp, Python def, blank/comment lines excluded from body count)",
        "threshold": ">60 lines MEDIUM, >120 lines HIGH",
        "rationale": "Reviewability bound; long bodies correlate with untestable branches. Threshold is conventional, recorded so it can be re-run with other bands.",
    },
    {
        "id": "CQ-C02",
        "family": "complexity",
        "name": "excessive-module-size",
        "measures": "total file lines",
        "threshold": ">1500 lines HIGH",
        "rationale": "Single-file comprehension bound.",
    },
    {
        "id": "CQ-C03",
        "family": "complexity",
        "name": "deep-nesting",
        "measures": "max leading-indent depth in 2-space units (Elixir) / 4-space levels (Python), comment/blank lines ignored",
        "threshold": ">5 units HIGH (approximate; regex-based, see limits)",
        "rationale": "Nesting depth correlates with branch-comprehension cost. Approximate: continuation lines and heredocs can inflate the measure; flagged rows carry the measured depth so a reader can verify.",
    },
    {
        "id": "CQ-D01",
        "family": "design",
        "name": "god-module-candidate",
        "measures": "public function count per file (Elixir def/defdelegate at any indent; Python top-level def)",
        "threshold": ">40 MEDIUM (candidate only, not a verdict)",
        "rationale": "Count-only signal for further review; a large public surface may be legitimate (facades). Recorded as candidate, never as failure.",
    },
    {
        "id": "CQ-R01",
        "family": "reliability",
        "name": "swallowed-exception",
        "measures": "rescue/except clauses whose body is trivial (Elixir: bare `rescue _ ->` or body in {:ok, nil, :error, _}; Python: bare `except:` or `except Exception:` with pass-only body)",
        "threshold": "any occurrence MEDIUM",
        "rationale": "Swallowed errors hide failure modes. Narrow patterns only; Logger-then-reraise and specific-exception handling are NOT flagged.",
    },
    {
        "id": "CQ-M01",
        "family": "maintainability",
        "name": "commented-out-implementation",
        "measures": "comment lines matching code keywords (def/defmodule/class/import/alias/require/@spec)",
        "threshold": "any occurrence LOW (informational)",
        "rationale": "Commented-out code rots and misleads readers. Informational only.",
    },
    {
        "id": "CQ-M03",
        "family": "maintainability",
        "name": "duplicated-configuration-key",
        "measures": "identical top-level config keys (config :app, key) across config/*.exs files",
        "threshold": "any duplicate LOW (informational)",
        "rationale": "Duplicate config keys across files create silent-override risk. Mechanical key comparison only.",
    },
    {
        "id": "CQ-M04",
        "family": "maintainability",
        "name": "todo-fixme-density",
        "measures": "TODO|FIXME|XXX|HACK comment markers per file",
        "threshold": ">5 markers LOW (informational)",
        "rationale": "Count-based debt signal only; marker presence is not itself a defect.",
    },
]

NOT_ASSESSED = [
    {"id": "CQ-D02", "name": "circular-dependencies", "reason": "Requires call graph; call-graph generation is forbidden in this program phase."},
    {"id": "CQ-D03", "name": "abstraction-leakage/hidden-global-state/implicit-coupling", "reason": "Requires semantic analysis; regex cannot distinguish legitimate layering from leakage."},
    {"id": "CQ-R02", "name": "unbounded-growth/resource-leaks/hotspots", "reason": "Requires runtime execution; static markers too noisy to be objective."},
    {"id": "CQ-R03", "name": "supervision-strategy judgments", "reason": "Restart strategy is a design decision, not objectively wrong."},
    {"id": "CQ-R04", "name": "retry-storm/failure-amplification", "reason": "Requires runtime observation."},
    {"id": "CQ-M02", "name": "magic-values", "reason": "Cannot distinguish legitimate constants (ports, timeouts, thresholds) from magic numbers without semantic analysis."},
]

# ---------------------------------------------------------------------------
# Measurement helpers (line/regex based; deterministic)
# ---------------------------------------------------------------------------
ELIXIR_DEF_RE = re.compile(r"^(\s*)(defp?\s+[\w\?!]+)")
PYTHON_DEF_RE = re.compile(r"^( *)def\s+([\w]+)\s*\(")
ELIXIR_DELEGATE_RE = re.compile(r"^\s*defdelegate\s+")
TODO_RE = re.compile(r"#.*\b(TODO|FIXME|XXX|HACK)\b")
COMMENTED_CODE_RE = re.compile(r"^\s*#\s*(def\s|defmodule\s|class\s|import\s|alias\s|require\s|@spec\s)")
CONFIG_KEY_RE = re.compile(r"^\s*config\s+:([A-Za-z0-9_]+)\s*,\s*:?([A-Za-z0-9_]+)?")
ELIXIR_RESCUE_TRIVIAL_RE = re.compile(r"^\s*rescue\s+_\s*->\s*(:(ok|error)|nil|_)?\s*$")
PYTHON_BARE_EXCEPT_RE = re.compile(r"^\s*except\s*:\s*$|^\s*except\s+Exception\s*:\s*$")


def _indent_units(line: str, width: int) -> int:
    stripped = line.lstrip(" ")
    if not stripped or stripped.startswith("#"):
        return 0
    leading = len(line) - len(line.lstrip(" "))
    return leading // width


def _function_spans(lines, lang):
    """Yield (start_lineno_1based, name, body_line_count). Blank/comment lines
    excluded from body count. A function ends at the next same-or-lower-indent
    def, or at a dedent below its own indent (approximate for Elixir `end`)."""
    spans = []
    if lang == "elixir":
        pat, w = ELIXIR_DEF_RE, 2
    elif lang == "python":
        pat, w = PYTHON_DEF_RE, 4
    else:
        return spans
    defs = []
    for i, ln in enumerate(lines):
        m = pat.match(ln)
        if m:
            if lang == "python":
                indent = len(m.group(1))
                name = m.group(2)
            else:
                indent = len(ln) - len(ln.lstrip(" "))
                name = ln.strip().split()[1].split("(")[0]
            defs.append((i, name, indent, w))
    for idx, (start, name, indent, w) in enumerate(defs):
        end = len(lines)
        for j in range(start + 1, len(lines)):
            lj = lines[j]
            if not lj.strip() or lj.strip().startswith("#"):
                continue
            li = len(lj) - len(lj.lstrip(" "))
            if lang == "elixir":
                # Elixir: next def at any indent, or `end` at/below own indent
                if ELIXIR_DEF_RE.match(lj):
                    end = j
                    break
                if lj.strip() == "end" and li <= indent:
                    end = j + 1
                    break
            else:
                if li <= indent and (PYTHON_DEF_RE.match(lj) or re.match(r"^(class|if|for|while|with|try|@)", lj.strip())):
                    end = j
                    break
        body = [l for l in lines[start + 1:end] if l.strip() and not l.strip().startswith("#")]
        spans.append((start + 1, name, len(body)))
    return spans


def _max_indent(lines, width):
    return max([_indent_units(l, width) for l in lines] or [0])


def measure_file(path, text):
    """Return list of raw measurement dicts (no thresholds applied here)."""
    ext = os.path.splitext(path)[1].lower()
    lang = "elixir" if ext in (".ex", ".exs") else ("python" if ext == ".py" else None)
    if lang is None:
        return []
    lines = text.splitlines()
    out = []
    out.append({"metric": "file_lines", "value": len(lines)})
    width = 2 if lang == "elixir" else 4
    out.append({"metric": "max_indent_units", "value": _max_indent(lines, width)})
    for start, name, body in _function_spans(lines, lang):
        out.append({"metric": "function_body_lines", "value": body, "name": name, "line": start})
    if lang == "elixir":
        pub = len(ELIXIR_DEF_RE.findall(text)) + len(ELIXIR_DELEGATE_RE.findall(text))
    else:
        pub = len([l for l in lines if PYTHON_DEF_RE.match(l)])
    out.append({"metric": "public_function_count", "value": pub})
    # rescue/except analysis with one-line lookahead for trivial bodies
    for i, ln in enumerate(lines):
        if lang == "elixir" and ELIXIR_RESCUE_TRIVIAL_RE.match(ln):
            out.append({"metric": "swallowed_exception", "value": 1, "line": i + 1, "text": ln.strip()[:100]})
        if lang == "python" and PYTHON_BARE_EXCEPT_RE.match(ln):
            nxt = [l.strip() for l in lines[i + 1:i + 4] if l.strip() and not l.strip().startswith("#")]
            if nxt and nxt[0] in ("pass", "..."):
                out.append({"metric": "swallowed_exception", "value": 1, "line": i + 1, "text": ln.strip()[:100]})
    for i, ln in enumerate(lines):
        if COMMENTED_CODE_RE.match(ln):
            out.append({"metric": "commented_out_code", "value": 1, "line": i + 1, "text": ln.strip()[:100]})
    todos = sum(1 for ln in lines if TODO_RE.search(ln))
    if todos:
        out.append({"metric": "todo_markers", "value": todos})
    return out


def apply_thresholds(path, measurements):
    """Turn measurements into findings. Returns list of finding dicts."""
    findings = []
    for m in measurements:
        v = m["value"]
        if m["metric"] == "function_body_lines":
            if v > 120:
                findings.append({"criterion": "CQ-C01", "severity": "HIGH", "path": path, "line": m.get("line"), "detail": f"function {m.get('name')} body {v} lines (>120)"})
            elif v > 60:
                findings.append({"criterion": "CQ-C01", "severity": "MEDIUM", "path": path, "line": m.get("line"), "detail": f"function {m.get('name')} body {v} lines (>60)"})
        elif m["metric"] == "file_lines":
            if v > 1500:
                findings.append({"criterion": "CQ-C02", "severity": "HIGH", "path": path, "line": 1, "detail": f"file {v} lines (>1500)"})
        elif m["metric"] == "max_indent_units":
            if v > 5:
                findings.append({"criterion": "CQ-C03", "severity": "HIGH", "path": path, "line": 1, "detail": f"max indent depth {v} units (>5, approximate)"})
        elif m["metric"] == "public_function_count":
            if v > 40:
                findings.append({"criterion": "CQ-D01", "severity": "MEDIUM", "path": path, "line": 1, "detail": f"{v} public functions (>40, candidate only)"})
        elif m["metric"] == "swallowed_exception":
            findings.append({"criterion": "CQ-R01", "severity": "MEDIUM", "path": path, "line": m.get("line"), "detail": f"trivial handler: {m.get('text')}"})
        elif m["metric"] == "commented_out_code":
            findings.append({"criterion": "CQ-M01", "severity": "LOW", "path": path, "line": m.get("line"), "detail": f"commented-out code: {m.get('text')}"})
        elif m["metric"] == "todo_markers":
            if v > 5:
                findings.append({"criterion": "CQ-M04", "severity": "LOW", "path": path, "line": 1, "detail": f"{v} TODO/FIXME markers (>5)"})
    return findings


def collect_config_keys(files):
    """files: list of (path, text) for config/*.exs. Returns duplicate-key findings."""
    seen = {}
    findings = []
    for path, text in files:
        for i, ln in enumerate(text.splitlines()):
            m = CONFIG_KEY_RE.match(ln)
            if m:
                key = (m.group(1), m.group(2) or "")
                if key in seen:
                    findings.append({"criterion": "CQ-M03", "severity": "LOW", "path": path, "line": i + 1, "detail": f"duplicate config key {key} (first seen in {seen[key]})"})
                else:
                    seen[key] = f"{path}:{i + 1}"
    return findings


def run_audit(worktree, t0_commit):
    """Walk the T0 worktree, measure every .ex/.exs/.py file, apply
    thresholds. Returns the findings document dict (not written)."""
    import datetime as _dt
    started = _dt.datetime.now(_dt.timezone.utc).isoformat()
    findings = []
    files_measured = 0
    files_skipped_size = 0
    config_inputs = []
    for dirpath, dirnames, filenames in os.walk(worktree, followlinks=False, onerror=lambda e: None):
        dirnames[:] = [d for d in dirnames if d != ".git"]
        for fn in filenames:
            ext = os.path.splitext(fn)[1].lower()
            if ext not in (".ex", ".exs", ".py"):
                continue
            full = os.path.join(dirpath, fn)
            rel = os.path.relpath(full, worktree).replace("\\", "/")
            try:
                size = os.path.getsize(full)
            except OSError:
                continue
            if size > 5 * 1024 * 1024:
                files_skipped_size += 1
                continue
            try:
                with open(full, "r", encoding="utf-8", errors="replace") as f:
                    text = f.read()
            except OSError:
                continue
            files_measured += 1
            findings.extend(apply_thresholds(rel, measure_file(rel, text)))
            if rel.startswith("config/") and ext == ".exs":
                config_inputs.append((rel, text))
    findings.extend(collect_config_keys(config_inputs))
    by_criterion = {}
    by_severity = {}
    for fl in findings:
        by_criterion[fl["criterion"]] = by_criterion.get(fl["criterion"], 0) + 1
        by_severity[fl["severity"]] = by_severity.get(fl["severity"], 0) + 1
    return {
        "artifact": "CODE_FINDINGS_M6",
        "artifact_status": "POST_T0",
        "move": 6,
        "program": "TIA_FORENSIC_RECON_ENGINE",
        "schema_version": "1.0.0",
        "t0_commit": t0_commit,
        "run_started_at": started,
        "criteria": CRITERIA,
        "not_assessed": NOT_ASSESSED,
        "summary": {
            "files_measured": files_measured,
            "files_skipped_over_size": files_skipped_size,
            "findings_total": len(findings),
            "by_criterion": by_criterion,
            "by_severity": by_severity,
        },
        "method_limits": [
            "Line/regex based; no parsing, no type info, no semantic analysis.",
            "Elixir function-end detection is approximate (next-def or dedent-end heuristic).",
            "Indent-depth counts continuation lines and heredocs; flagged rows carry depth for reader verification.",
            "CQ-D01 counts public surface only; facades legitimately exceed it (recorded as candidate).",
            "CQ-R01 uses narrow trivial-handler patterns only; specific-exception handling never flagged.",
        ],
        "findings": findings,
    }


def main(argv):
    import argparse
    import hashlib
    import json
    ap = argparse.ArgumentParser(description="Move 6 code-quality audit (read-only, T0 worktree)")
    ap.add_argument("--worktree", required=True)
    ap.add_argument("--t0-commit", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args(argv)
    doc = run_audit(args.worktree, args.t0_commit)
    tmp = args.out + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="\n") as f:
        json.dump(doc, f, ensure_ascii=False, indent=2)
        f.write("\n")
    os.replace(tmp, args.out)
    print(f"CODE findings: {doc['summary']['findings_total']} "
          f"across {doc['summary']['files_measured']} files "
          f"(skipped {doc['summary']['files_skipped_over_size']})")
    print(f"by severity: {doc['summary']['by_severity']}")
    print(f"wrote {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
