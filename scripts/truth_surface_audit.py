#!/usr/bin/env python3
"""Truth-surface audit for Tiannara production code.

Finds common theatrical-success indicators. This is a detector, not a proof:
every finding requires human classification because randomness can be legitimate
inside an evolutionary simulation, while the same construct is unacceptable
inside verification, health, certification or execution paths.
"""
from pathlib import Path
import re
import json

ROOT = Path(__file__).resolve().parents[1]
TARGETS = [ROOT / "lib", ROOT / "tiannara_core", ROOT / "tiannara_runtime", ROOT / "tiannara_api"]
SKIP = {"test", "tests", "docs", "certification", "priv", "scripts", "scratch", "data"}
PATTERNS = [
    (r"TODO.*implement", "implementation placeholder"),
    (r"Placeholder", "placeholder"),
    (r"simulat(?:e|ed).*success", "simulated success"),
    (r"return\s+\{[^\n]*status[^\n]*implemented", "implemented-looking return"),
    (r"success_probability\s*=", "probabilistic fabricated success"),
    (r":rand\.uniform\(\).*success", "random success"),
    (r"def\s+validate[^\n]*\n(?:.|\n){0,300}do:\s*:validated", "unconditional validation"),
    (r"health.*1\.0", "hard-coded health"),
    (r"def\s+health[^\n]*.*healthy", "constant health"),
]
EXTS = {".ex", ".exs", ".py"}

def scan():
    findings = []
    for base in TARGETS:
        if not base.exists():
            continue
        for path in base.rglob("*"):
            if path.suffix not in EXTS or any(part in SKIP for part in path.parts):
                continue
            try:
                text = path.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                continue
            for line_no, line in enumerate(text.splitlines(), 1):
                for pattern, category in PATTERNS:
                    if re.search(pattern, line, re.I):
                        findings.append({
                            "file": str(path.relative_to(ROOT)),
                            "line": line_no,
                            "category": category,
                            "text": line.strip()[:240],
                        })
    return findings

if __name__ == "__main__":
    findings = scan()
    report = {
        "status": "findings_require_classification" if findings else "clean_for_scanned_patterns",
        "count": len(findings),
        "findings": findings,
        "note": "A finding is not automatically a defect; production execution/health/certification paths must be reviewed first."
    }
    print(json.dumps(report, indent=2))
    raise SystemExit(2 if findings else 0)
