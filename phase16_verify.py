import json
import os
import re
import glob
from typing import List, Tuple

PHASE16_MD_PREFIXES = (
    "PHASE16_",
    "RESEARCH_",
    "AUTONOMOUS_",
    "INDEPENDENT_",
    "LONG_HORIZON_",
    "KNOWLEDGE_",
    "QUESTION_",
    "DISCOVERY_",
)

# Strict JSON set: only the artifacts we intend to validate.
PHASE16_JSON_MATCHERS = [
    lambda fn: fn.startswith("RESEARCH_") and fn.lower().endswith(".json"),
    lambda fn: fn.startswith("DISCOVERY_LINEAGE") and fn.lower().endswith(".json"),
    lambda fn: fn.startswith("PHASE16_") and fn.lower().endswith(".json"),
]

EXTRA_MD_FILES = [
    "PHASE16_SPEC_COMPLETION_REPORT.md",
    "PHASE16_PRE_IMPLEMENTATION_AUDIT.md",
    "DOCUMENT_REFERENCE_REPORT.md",
    "JSON_VALIDATION_REPORT.md",
    "OWNERSHIP_AUDIT.md",
    "REPLAY_AUDIT.md",
    "ARCHAEOLOGY_AUDIT.md",
    "IMPLEMENTATION_READINESS.md",
]

# Backticked filename references like: `SOME_FILE.md` or `SOME_FILE.json`
REF_RE = re.compile(r"`([^`]+\.(?:md|json))`")

def list_phase16_json_files() -> List[str]:
    files = sorted(os.listdir("."))
    out = []
    for f in files:
        if any(matcher(f) for matcher in PHASE16_JSON_MATCHERS):
            out.append(f)
    return out

def strict_parse_json(files: List[str]) -> Tuple[bool, List[Tuple[str, str]]]:
    bad = []
    for f in files:
        try:
            with open(f, "r", encoding="utf-8") as fp:
                json.load(fp)
        except Exception as e:
            bad.append((f, str(e)))
    return (len(bad) == 0), bad

def list_phase16_md_files() -> List[str]:
    md_files = []
    for f in os.listdir("."):
        if not f.lower().endswith(".md"):
            continue
        up = f.upper()
        if any(up.startswith(prefix) for prefix in PHASE16_MD_PREFIXES):
            md_files.append(f)
    for f in EXTRA_MD_FILES:
        if os.path.exists(f) and f not in md_files:
            md_files.append(f)
    return sorted(set(md_files))

def collect_markdown_filename_refs(md_files: List[str]) -> List[Tuple[str, str]]:
    refs = []
    for mf in md_files:
        with open(mf, "r", encoding="utf-8") as fp:
            txt = fp.read()
        for m in REF_RE.finditer(txt):
            refs.append((mf, m.group(1)))
    return refs

def verify_refs_exist(refs: List[Tuple[str, str]]) -> List[Tuple[str, str]]:
    existing = set(os.listdir("."))
    missing = []
    for src, target in refs:
        if target not in existing:
            missing.append((src, target))
    return missing

def main() -> None:
    # JSON validation
    json_files = list_phase16_json_files()
    ok, bad = strict_parse_json(json_files)

    print("=== PHASE16 THOROUGH DOC VERIFICATION (SPEC-ONLY) ===")
    print(f"JSON files found for strict parse: {len(json_files)}")
    print("Strict JSON parse:", "PASS" if ok else "FAIL")
    if bad:
        print("Bad JSON details (up to 20):")
        for f, err in bad[:20]:
            print(f"- {f}: {err}")

    # Markdown reference integrity
    md_files = list_phase16_md_files()
    refs = collect_markdown_filename_refs(md_files)
    missing = verify_refs_exist(refs)

    print()
    print(f"Markdown files scanned: {len(md_files)}")
    print(f"Backticked filename references found: {len(refs)}")
    print(f"Missing referenced files: {len(missing)}")
    if missing:
        print("Missing reference details (up to 30):")
        for src, target in missing[:30]:
            print(f"- {target} referenced from {src}")

    # Exit code
    if (not ok) or missing:
        raise SystemExit(1)

    print()
    print("DONE - All checks passed.")

if __name__ == "__main__":
    main()
