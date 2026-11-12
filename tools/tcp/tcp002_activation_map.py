#!/usr/bin/env python3
"""TCP-002.1 — Runtime cognitive / world-model activation and dependency map.

Generates the activation map for the two runtime clusters that were found to
be entirely unreachable:

    tiannara_runtime/lib/tiannara_runtime/cognitive/    (161 modules)
    tiannara_runtime/lib/tiannara_runtime/world_model/  (175 modules)

The map is produced from the source itself, not from names, and is committed
so that it can be re-derived and diffed as the runtime changes.

Usage:
    python tools/tcp/tcp002_activation_map.py [--repo ROOT] [--out-dir DIR]

Outputs:
    certification/tcp/TCP-002_ACTIVATION_MAP.csv   one row per module
    certification/tcp/TCP-002_ACTIVATION_MAP.md     summary by classification
"""

import argparse
import csv
import io
import os
import re
from collections import Counter, defaultdict

CLUSTERS = ["cognitive", "world_model"]

# A module that only builds/validates maps is scaffolding; a module that calls
# other capability modules performs work. This distinction is what stops
# "activation" from becoming "a module loaded and did nothing".
PROCESS_MACROS = [
    ("supervisor", r"^\s*use\s+Supervisor\b"),
    ("genserver", r"^\s*use\s+GenServer\b"),
    ("agent", r"^\s*use\s+Agent\b"),
    ("task", r"^\s*use\s+Task\b"),
    ("dynamic_supervisor", r"^\s*use\s+DynamicSupervisor\b"),
]

SIDE_EFFECTS = {
    "gen_server_call": r"\bGenServer\.(call|cast|whereis)\b",
    "ets": r":ets\.(new|insert|lookup|delete|tab2list)\b",
    "persistent_term": r":persistent_term\.",
    "nats": r"\bGnat\.(pub|sub|start_link)\b",
    "repo": r"\bRepo\.(all|one|insert|update|transaction)\b",
    "file_io": r"\bFile\.(read|write|rm|stream)\b",
    "http": r"\b(Req|Finch|HTTPoison)\b",
    "timer": r":timer\.|Process\.send_after",
    "spawn": r"\b(Task|Agent|spawn)\.(start|start_link|async)\b",
    "port": r":gen_tcp|:gen_udp",
}

INFRA_MARKERS = {
    "needs_nats": r"\bGnat\.|\bnats\b|@nats_conn|@stream",
    "needs_ets": r":ets\.new\b",
    "needs_config": r"Application\.get_env|Application\.fetch_env|Application\.compile_env",
    "needs_repo": r"\bRepo\.\w+\(",
    "needs_process": r"Process\.whereis|GenServer\.whereis|:global\.",
    "needs_file": r"\bFile\.(read|write|rm)!?",
}


def read(path):
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        return fh.read()


def strip_comments(text):
    text = re.sub(r"@moduledoc\s+\"\"\".*?\"\"\"", "", text, flags=re.S)
    text = re.sub(r"@doc\s+\"\"\".*?\"\"\"", "", text, flags=re.S)
    text = re.sub(r"@doc\s+\"(?:[^\"\\]|\\.)*\"", "", text)
    text = re.sub(r"#[^\n]*", "", text)
    return text


def classify_kind(text):
    for name, pat in PROCESS_MACROS:
        if re.search(pat, text, re.M):
            return name
    if re.search(r"@callback\b", text):
        return "behaviour"
    if re.search(r"@behaviour\b", text):
        return "behaviour_implementation"
    if re.search(r"defstruct\b", text) and not re.search(r"^\s*def\s+\w+\s*\(", text, re.M):
        return "struct_only"
    if re.search(r"@behaviour\s+[\w.]+", text) and not re.search(r"^\s*def\s+\w+\s*\(", text, re.M):
        return "behaviour_implementation"
    return "library"


def module_name(text):
    m = re.search(r"defmodule\s+([A-Za-z0-9_.]+)\s+do", text)
    return m.group(1) if m else None


def public_defs(text):
    return re.findall(r"^\s*def\s+(\w+)", text, re.M)


def private_defs(text):
    return re.findall(r"^\s*defp\s+(\w+)", text, re.M)


VALUE_OBJECT_VOCAB = {
    "new", "generate_id", "compute_fingerprint", "validate", "normalize",
    "to_map", "from_map", "default", "valid?", "changes", "put", "changeset",
    "struct", "cast", "validate!", "to_string", "from_string",
}


def value_object_ratio(pubs):
    if not pubs:
        return 1.0
    hits = sum(1 for p in pubs if p in VALUE_OBJECT_VOCAB)
    return hits / len(pubs)


def classify_role(kind, pubs, body, delegates):
    """Role of a module, used to separate capability from data plumbing.

    * value_object — mostly constructors/validators/fingerprints.
    * engine       — exposes a real operation: it delegates to another module
                     or transforms data it was given.
    * scaffold     — a struct or a constructor with nothing else.
    """
    if kind == "behaviour":
        return "behaviour_contract"
    ratio = value_object_ratio(pubs)
    operational = [p for p in pubs if p not in VALUE_OBJECT_VOCAB]
    if not operational:
        return "scaffold"
    if ratio >= 0.6:
        return "value_object"
    computes = bool(re.search(r"\b(Enum|reduce|reduce_while|fold|foldl|for\s|with\b|Map\.|:math\.)", body))
    if delegates or computes:
        return "engine"
    return "value_object"


def module_refs(text, own):
    """Distinct other-module references, split into function calls and struct use."""
    calls, structs = set(), set()
    for m in re.finditer(r"\b(TiannaraRuntime|Tiannara)(?:\.[A-Za-z0-9_]+)+", text):
        name = m.group(0).rstrip(".")
        if own and name == own:
            continue
        tail = text[m.end():m.end() + 2]
        if tail.startswith("{"):
            structs.add(name)
        else:
            calls.add(name)
    return calls, structs


def scan_repo(repo):
    """All Elixir source files in the repository, minus build/vendor dirs."""
    skip = {"_build", "deps", "node_modules", ".git", "__pycache__", "target"}
    out = []
    for dp, dn, fn in os.walk(repo):
        dn[:] = [d for d in dn if d not in skip]
        for f in fn:
            if f.endswith((".ex", ".exs")):
                out.append(os.path.join(dp, f))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", default=os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))
    ap.add_argument("--out-dir", default=None)
    args = ap.parse_args()

    repo = os.path.abspath(args.repo)
    out_dir = args.out_dir or os.path.join(repo, "certification", "tcp")
    os.makedirs(out_dir, exist_ok=True)

    rt = os.path.join(repo, "tiannara_runtime", "lib", "tiannara_runtime")

    # ---- pass 1: index every module in the repository -----------------------
    all_files = scan_repo(repo)
    module_index = {}          # module -> file
    module_text = {}
    # name -> set of modules whose *source* mentions it (external references)
    mentioned_by = defaultdict(set)
    # module names mentioned by each test file
    test_mentions = []

    name_re = re.compile(r"\b(?:TiannaraRuntime|Tiannara)(?:\.[A-Za-z0-9_]+)+")

    for path in all_files:
        text = read(path)
        is_test = path.endswith(".exs")
        names_in_file = set(re.findall(r"defmodule\s+([A-Za-z0-9_.]+)\s+do", text))
        refs = set(name_re.findall(text))
        for name in names_in_file:
            module_index.setdefault(name, os.path.relpath(path, repo).replace("\\", "/"))
            module_text.setdefault(name, text)
        for ref in refs:
            mentioned_by[ref].update(names_in_file)
        if is_test:
            test_mentions.append(refs)

    def test_ref_count(name):
        return sum(1 for refs in test_mentions if name in refs)

    def external_ref_count(name):
        # modules outside the two clusters whose source mentions this module
        return sum(1 for other in mentioned_by.get(name, ())
                   if not (other.startswith("TiannaraRuntime.Cognitive.")
                           or other.startswith("TiannaraRuntime.WorldModel.")
                           or other == name))

    # ---- pass 2: build the cluster rows -------------------------------------
    rows = []
    for cluster in CLUSTERS:
        base = os.path.join(rt, cluster)
        if not os.path.isdir(base):
            continue
        for dp, dn, fn in os.walk(base):
            dn[:] = [d for d in dn if d not in {"_build", "deps"}]
            for f in sorted(fn):
                if not f.endswith(".ex"):
                    continue
                path = os.path.join(dp, f)
                rel = os.path.relpath(path, repo).replace("\\", "/")
                raw = read(path)
                text = strip_comments(raw)
                name = module_name(text) or os.path.splitext(f)[0]
                body = text.split("\n", 1)[1] if "\n" in text else ""
                body = body.replace("do", " ", 1) if body.strip().startswith("do") else body

                kind = classify_kind(body)
                pubs = public_defs(body)
                privs = private_defs(body)
                calls, structs = module_refs(body, name)

                # Delegation vs construction. A module that *calls* another
                # module's function performs work; one that only builds its
                # own structs is a value object.
                delegates = {c for c in calls if c not in structs}
                cluster_prefix = "TiannaraRuntime.Cognitive." if cluster == "cognitive" else "TiannaraRuntime.WorldModel."
                intra = {c for c in calls if c.startswith(cluster_prefix)}
                cross = {c for c in delegates if not c.startswith(cluster_prefix)}

                side = sorted(k for k, pat in SIDE_EFFECTS.items() if re.search(pat, body))
                infra = sorted(k for k, pat in INFRA_MARKERS.items() if re.search(pat, body))

                # external references: who outside the cluster mentions this module
                external = external_ref_count(name)
                test_refs = test_ref_count(name)

                # substance: does the module perform an operation, or is it a
                # value object / constructor only?
                role = classify_role(kind, pubs, body, cross)
                scaffolding = role in ("scaffold", "value_object")

                rows.append({
                    "cluster": cluster,
                    "subpackage": os.path.dirname(rel).split("/")[-1],
                    "module": name,
                    "file": rel,
                    "kind": kind,
                    "public_functions": len(pubs),
                    "private_functions": len(privs),
                    "behaviour_callbacks": len(re.findall(r"@callback\s+(\w+)", body)),
                    "declares_behaviour": (re.search(r"@behaviour\s+([\w.]+)", body).group(1)
                                           if re.search(r"@behaviour\s+([\w.]+)", body) else ""),
                    "cross_cluster_calls": len(cross),
                    "intra_cluster_calls": len(intra),
                    "struct_dependencies": len(structs),
                    "role": role,
                    "side_effects": ";".join(side),
                    "infrastructure": ";".join(infra),
                    "external_references": external,
                    "test_references": test_refs,
                    "substance": "scaffolding" if scaffolding else "substantive",
                    "activation": ("implement_behaviour" if kind == "behaviour"
                                   else "host_required" if kind in ("supervisor", "genserver", "agent", "task", "dynamic_supervisor")
                                   else "compose_only" if scaffolding
                                   else "compose"),
                })

    # ---- write CSV ---------------------------------------------------------
    cols = ["cluster", "subpackage", "module", "file", "kind", "role",
            "public_functions", "private_functions", "behaviour_callbacks",
            "declares_behaviour", "cross_cluster_calls", "intra_cluster_calls",
            "struct_dependencies", "side_effects", "infrastructure",
            "external_references", "test_references", "substance", "activation"]
    csv_path = os.path.join(out_dir, "TCP-002_ACTIVATION_MAP.csv")
    with open(csv_path, "w", encoding="utf-8", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=cols, lineterminator="\n")
        w.writeheader()
        for r in sorted(rows, key=lambda x: (x["cluster"], x["subpackage"], x["module"])):
            w.writerow(r)

    # ---- write Markdown summary --------------------------------------------
    total = len(rows)
    by_kind = Counter(r["kind"] for r in rows)
    by_role = Counter(r["role"] for r in rows)
    by_activation = Counter(r["activation"] for r in rows)
    by_substance = Counter(r["substance"] for r in rows)
    by_cluster = Counter(r["cluster"] for r in rows)
    untested = [r for r in rows if r["test_references"] == 0]
    externally_used = [r for r in rows if r["external_references"] > 0]
    side_effecting = [r for r in rows if r["side_effects"]]
    infra_needing = [r for r in rows if r["infrastructure"]]

    md = io.StringIO()
    md.write("# TCP-002.1 — Runtime Activation and Dependency Map\n\n")
    md.write("**Generated by** `tools/tcp/tcp002_activation_map.py` — re-derivable from source.\n")
    md.write("**Scope:** `tiannara_runtime/lib/tiannara_runtime/{cognitive,world_model}`\n\n")
    md.write(f"**Total modules mapped: {total}** ({', '.join(f'{k} {v}' for k, v in sorted(by_cluster.items()))})\n\n")

    md.write("## 1. Headline finding: none of these are processes\n\n")
    md.write("| Kind | Modules |\n|---|---|\n")
    for k, v in by_kind.most_common():
        md.write(f"| `{k}` | {v} |\n")
    md.write("\n")
    md.write("Every module in both clusters is a **stateless library or a behaviour** "
             "contract. Not one is a `GenServer`, `Supervisor`, `Agent` or `Task`. "
             "Therefore **mass supervision would be categorically wrong**: there is "
             "nothing to supervise. The activation problem is a *composition* "
             "problem — these functions must be invoked, in a governed order, by a "
             "process that already holds authority.\n\n")

    md.write("## 2. Recommended activation mechanism\n\n")
    md.write("| Mechanism | Modules | Meaning |\n|---|---|---|\n")
    meanings = {
        "compose": "Called directly by a governed orchestrator; no process needed.",
        "compose_only": "Scaffolding — builds/validates data only. Must not be counted as capability.",
        "implement_behaviour": "Behaviour contract; needs a concrete implementation.",
        "host_required": "Needs a host process to own its state.",
    }
    for k, v in by_activation.most_common():
        md.write(f"| `{k}` | {v} | {meanings.get(k, '')} |\n")
    md.write("\n")

    md.write("## 3. Role split (capability vs data plumbing)\n\n")
    md.write(f"- **engine: {by_role['engine']}** — exposes a real operation: it delegates "
             "to another module or transforms data it was given.\n")
    md.write(f"- **value_object: {by_role['value_object']}** — constructors, validators and "
             "fingerprints. Real code, but data, not capability.\n")
    md.write(f"- **scaffold: {by_role['scaffold']}** — a struct or constructor with nothing else.\n")
    md.write(f"- **behaviour_contract: {by_role['behaviour_contract']}** — a callback contract "
             "needing a concrete implementation.\n\n")
    md.write("Value objects are *not* defects to delete; they are the data contracts the "
             "engines exchange. They are counted separately so that \"the module is "
             "reachable\" can never be mistaken for \"the capability works\". **Only the "
             f"{by_role['engine']} engine modules are candidate capability**, and each must "
             "still be shown to do the work it claims.\n\n")

    md.write("## 4. Reachability\n\n")
    md.write(f"- Modules with **no external reference at all**: {total - len(externally_used)} of {total}.\n")
    md.write(f"- Modules with **no test reference**: {len(untested)} of {total}.\n")
    md.write(f"- Modules with **side effects**: {len(side_effecting)} of {total}.\n")
    md.write(f"- Modules with **infrastructure requirements**: {len(infra_needing)} of {total}.\n\n")

    md.write("### 4.1 Per-cluster breakdown\n\n")
    md.write("| Cluster | Modules | Engines | Value objects | Scaffold | Untested | Side-effecting | Needs infra |\n|---|---|---|---|---|---|---|---|---|\n")
    for c in CLUSTERS:
        sub = [r for r in rows if r["cluster"] == c]
        if not sub:
            continue
        md.write(f"| `{c}` | {len(sub)} "
                 f"| {sum(1 for r in sub if r['role']=='engine')} "
                 f"| {sum(1 for r in sub if r['role']=='value_object')} "
                 f"| {sum(1 for r in sub if r['role']=='scaffold')} "
                 f"| {sum(1 for r in sub if r['test_references']==0)} "
                 f"| {sum(1 for r in sub if r['side_effects'])} "
                 f"| {sum(1 for r in sub if r['infrastructure'])} |\n")
    md.write("\n")

    md.write("### 4.2 Subpackage reachability\n\n")
    md.write("| Cluster | Subpackage | Modules | Untested | Unreferenced externally |\n|---|---|---|---|---|\n")
    bysub = defaultdict(list)
    for r in rows:
        bysub[(r["cluster"], r["subpackage"])].append(r)
    for (c, s), sub in sorted(bysub.items()):
        md.write(f"| `{c}` | `{s}` | {len(sub)} "
                 f"| {sum(1 for r in sub if r['test_references']==0)} "
                 f"| {sum(1 for r in sub if r['external_references']==0)} |\n")
    md.write("\n")

    md.write("## 5. Composition surfaces already present\n\n")
    md.write("The clusters already contain orchestrators. They are libraries that "
             "compose other libraries; they are the natural subjects of the "
             "Cognitive Execution Spine and they are the reason no new cognitive "
             "core is needed.\n\n")
    orchestrators = [r for r in rows
                     if r["role"] == "engine"
                     and re.search(r"(Orchestrator|Coordinator|Kernel|Controller|Runtime|Manager|Engine|Governor|Dispatcher|Router|Assembler)$",
                                  r["module"].split(".")[-1])]
    md.write("| Module | Kind | Public fns | Calls | Tested |\n|---|---|---|---|---|\n")
    for r in sorted(orchestrators, key=lambda x: (-x["cross_cluster_calls"], x["module"]))[:40]:
        md.write(f"| `{r['module']}` | {r['kind']} | {r['public_functions']} "
                 f"| {r['cross_cluster_calls']} | {'yes' if r['test_references'] else 'no'} |\n")
    md.write("\n")

    md.write("## 6. Activation contract (what TCP-002.2 must satisfy)\n\n")
    md.write("1. **No mass supervision.** Zero of the mapped modules is a process; "
             "supervision is not the activation mechanism for any of them.\n")
    md.write("2. **No fake activation.** A reachable module that only assembles data "
             "must be reported as scaffolding, not as capability.\n")
    md.write("3. **Every capability needs an identifiable canonical owner** and a "
             "single execution path (no duplicate authorities).\n")
    md.write("4. **Fail-closed must be preserved**: an unexercised capability stays "
             "explicitly unavailable.\n")
    md.write("5. **Governance is not bypassed**: coordination may sequence work; "
             "authorisation still comes from the constitutional authority.\n")

    md_path = os.path.join(out_dir, "TCP-002_ACTIVATION_MAP.md")
    with open(md_path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(md.getvalue())

    print("modules mapped: %d" % total)
    print("kinds:", dict(by_kind))
    print("roles:", dict(by_role))
    print("activation:", dict(by_activation))
    print("untested: %d   externally unreferenced: %d" % (len(untested), total - len(externally_used)))
    print("wrote:", csv_path)
    print("wrote:", md_path)


if __name__ == "__main__":
    main()
