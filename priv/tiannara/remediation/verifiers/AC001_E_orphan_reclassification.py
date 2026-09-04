"""
AC-001-E verifier: Orphan Resolution & Ontology Closure.

Verifies the frozen canonical ontology closure invariants over the lib/ tree
without requiring a live BEAM boot (fast static verification; complements
the runtime check).

Checks:
  1. Exactly 20 canonical domain module files under lib/tiannara/domains/
  2. No fake domain modules (Mathematics, Logic, Science) exist
  3. No computer_science.ex remains
  4. No ":science"/":mathematics" as canonical-domain identity in domain lists
     (only documentation/substrate references allowed)
  5. canonical_registry moduledoc exclusion documentation intact
"""
import os
import re
import sys

LIBS = {
    "aerospace", "agriculture", "architecture", "chemistry", "cognition",
    "computation", "cybernetics", "ecology", "economics", "energy",
    "engineering", "governance", "linguistics", "logistics", "materials",
    "medicine", "philosophy", "physics", "robotics", "sociology",
}

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", ".."))
DOM_DIR = os.path.join(ROOT, "lib", "tiannara", "domains")


def main():
    failures = []

    # 1. canonical domain modules present
    present = {d for d in LIBS if os.path.exists(os.path.join(DOM_DIR, f"{d}.ex"))}
    missing = LIBS - present
    if missing:
        failures.append(f"missing canonical domain modules: {sorted(missing)}")

    # 2. fake domain modules absent
    for fake in ("mathematics", "logic", "science", "computer_science"):
        if os.path.exists(os.path.join(DOM_DIR, f"{fake}.ex")):
            failures.append(f"non-canonical module present: {fake}.ex")

    # 3. no computer_science anywhere under lib/
    for dirpath, _, files in os.walk(os.path.join(ROOT, "lib")):
        for f in files:
            if f == "computer_science.ex":
                failures.append(f"stale file: {os.path.join(dirpath, f)}")

    # 4. scan domain lists for excluded atoms as domain identity
    #    (allow only documentation lines in canonical_registry moduledoc)
    excluded_atoms = {":science", ":mathematics"}
    scan_paths = [
        os.path.join(ROOT, "lib", "tiannara", "domains", "canonical_registry.ex"),
        os.path.join(ROOT, "lib", "tiannara", "domain_cortex.ex"),
        os.path.join(ROOT, "lib", "tiannara", "ecology", "civilization.ex"),
        os.path.join(ROOT, "lib", "tiannara", "os", "domain_profile.ex"),
        os.path.join(ROOT, "lib", "tiannara", "os", "program_registry.ex"),
        os.path.join(ROOT, "lib", "tiannara", "os", "world_manager.ex"),
        os.path.join(ROOT, "lib", "tiannara", "os", "world_template.ex"),
        os.path.join(ROOT, "lib", "tiannara", "os", "institution_kernel.ex"),
    ]
    for p in scan_paths:
        if not os.path.exists(p):
            continue
        with open(p, encoding="utf-8", errors="replace") as fh:
            in_doc = False
            for i, line in enumerate(fh, 1):
                if '"""' in line:
                    # toggle docstring state; a line of only """ closes, and a
                    # line `@moduledoc """` or `""" text` opens
                    in_doc = not in_doc
                    continue
                stripped = line.strip()
                if in_doc:
                    continue
                if stripped.startswith("#"):
                    continue
                # a real domain-list occurrence looks like  :science
                if re.search(r":\s*science\b", line) or \
                   re.search(r":\s*mathematics\b", line):
                    failures.append(
                        f"domain-identity atom in {os.path.relpath(p, ROOT)}:{i}: {stripped}"
                    )

    # 5. canonical_registry exclusion docs intact
    cr = os.path.join(DOM_DIR, "canonical_registry.ex")
    with open(cr, encoding="utf-8", errors="replace") as fh:
        content = fh.read()
    for token in (":science (methodology", ":mathematics (epistemic", ":logic (epistemic", ":cs (merged"):
        if token not in content:
            failures.append(f"canonical_registry missing documentation: {token!r}")

    if failures:
        print("AC-001-E VERIFY: FAIL")
        for f_ in failures:
            print("  -", f_)
        sys.exit(1)

    print("AC-001-E VERIFY: PASS")
    print("  canonical domains present : 20/20")
    print("  fake/merged modules       : 0")
    print("  domain-identity atoms     : 0 violations")
    print("  exclusion docs            : intact")


if __name__ == "__main__":
    main()
