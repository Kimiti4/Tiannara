"""
TIA_FORENSIC_RECON_ENGINE — common helpers for Move 0 collectors.

READ-ONLY. No filesystem mutation. No git write. No network.
"""
from __future__ import annotations

import hashlib
import json
import os
import re
from typing import Any, Dict, List, Optional, Tuple

# ---------------------------------------------------------------------------
# Constants — bound to the T0 baseline. Update only via the orchestrator
# contract, never inline.
# ---------------------------------------------------------------------------
T0_COMMIT = "9753a6d08702064f4d00395a1bec1c4bf3887381"
T0_TREE = "06f06e5e91f33e75437a47ca901eaa7e97bb0edd"
T0_TAG = "T0"
T0_BASELINE_BRANCH = "t0-baseline"
CONTRACT_VERSION = "0.1.1"

# ---------------------------------------------------------------------------
# Bucket classification — the ten buckets, in priority order. The first match
# wins. A file that matches no rule lands in UNKNOWN (RI-009).
# ---------------------------------------------------------------------------
# Per Council policy (2026-09-03), the ONLY dirs to exclude from any T0
# inventory or push are the 11 LLM-assistant / system / garbage paths
# listed below. Everything else (subprojects, node_modules, .github, build
# outputs, etc.) that is tracked in T0 MUST be captured — T0 is the
# authoritative codebase and may contain any of those.
GARBAGE_BASENAMES = {"nul", "con", "prn", "aux", "com1", "com2", "com3", "lpt1", "lpt2", "AGENT.md"}
SECRET_BASENAMES = {".env", ".env.production", ".env.local", ".env.staging", ".env.development"}
SUBPROJECT_DIRS = set()  # per Council policy: subprojects are NOT excluded; they are
                          # captured and classified as SUBPROJECT bucket if needed.
GARBAGE_PATH_PARTS = {
    # The 11 LLM-assistant / system / garbage paths explicitly excluded by
    # Council policy (2026-09-03). The top-level `AGENT.md` file is matched
    # by its basename (handled in classify_path via GARBAGE_BASENAMES-style
    # logic, but here we also exclude it as a path component for safety).
    ".agents", ".continue", ".kilo", ".kilocode", ".kiro", ".qwen",
    "....", ".qoder", ".sixth", ".vscode",
    # Plus Git's own internal dir (never walk it):
    ".git",
    # Plus the path-mangled garbage from a known concatenation bug:
    "-p",
    "Tiannara-SaaS",
    "c:UsersuserTiannaraTiannara-MindCache-Prosthetictiannara_coremetacognition",
    "c:UsersuserTiannaraTiannara-MindCache-Prosthetictiannara_corereasoning",
    "tmp_6A0FF061F1AE1CBD28687AA5D4B250280CD3D623E3B18B9256269E5FE135CFDE",
    # NOTE: .devcontainer, .github, .hypothesis, node_modules, .pytest_cache,
    # _build, deps, dist, target, __pycache__, .bolt, .idea, .vs, .mvn,
    # .gradle are NOT in this list per Council policy. T0 may contain them
    # and they are captured. .github/workflows/, node_modules/, build outputs
    # etc. land in GENERATED or UNKNOWN depending on extension/content.
}
RUNTIME_STATE_EXTS = {".dets", ".db", ".dump", ".dat", ".sqlite", ".sqlite3"}
GENERATED_EXTS = {".beam", ".pyc", ".pyo", ".o", ".obj", ".class", ".jar", ".war"}
LARGE_FILE_BYTES = 100 * 1024 * 1024  # 100 MB

# Subproject directory basenames — per Council policy these are NOT excluded
# from the walk (they may be tracked in T0), but when classified their files
# land in the SUBPROJECT bucket so they're distinguishable from core lib/.
SUBPROJECT_BUCKET_DIRS = {
    "tiannara-desktop", "tiannara_api", "tiannara_gui", "tiannara_internal_dashboard",
    "tiannara_mobile", "tiannara_observatory", "tiannara_pros", "tiannara_runtime",
    "tiannara_saas", "tiannara_core",
}

# ---------------------------------------------------------------------------
# Path classification. Given a POSIX-style path (forward slashes), return
# the 10-bucket label and a one-line reason. Deterministic.
# ---------------------------------------------------------------------------
def classify_path(posix_path: str) -> Tuple[str, str]:
    # Normalize: strip any leading BOM / non-printable chars that Windows
    # sometimes produces in path-mangled garbage dirs.
    norm = posix_path.lstrip("\ufeff\ufffe\u200b\u200c\u200d").lstrip()
    # If the path is still empty or starts with a non-ASCII char after strip,
    # treat as garbage.
    if not norm or not all(ord(c) < 128 for c in norm):
        return "GARBAGE_INVALID", f"path contains non-ASCII characters or is empty: {posix_path!r}"
    parts = norm.split("/")
    fname = parts[-1] if parts else ""
    base = os.path.basename(fname)

    # GARBAGE — by basename or by any path component
    if base.lower() in GARBAGE_BASENAMES:
        return "GARBAGE_INVALID", f"basename is reserved OS device name or LLM-assistant: {base!r}"
    if base == "AGENT.md":
        return "GARBAGE_INVALID", f"basename {base!r} is LLM-assistant content (excluded by policy)"
    for p in parts:
        if p in GARBAGE_PATH_PARTS:
            return "GARBAGE_INVALID", f"path component {p!r} is excluded (LLM-assistant/garbage)"
        if p.startswith("c:Users"):
            return "GARBAGE_INVALID", f"path starts with {p!r} (path-mangled garbage)"

    # SECRET_SENSITIVE — by exact basename match
    if base in SECRET_BASENAMES:
        return "SECRET_SENSITIVE", f"basename {base!r} is a .env* secret (excluded by policy)"

    # Large runtime DETS in the dev_data archive
    if posix_path.startswith("dev_data_archive_20260816/") and any(p.endswith(".dets") or p.endswith(".dump") for p in [posix_path]):
        return "RUNTIME_STATE", "dev_data_archive DETS / DUMP artifact"

    # Extension-based
    ext = os.path.splitext(fname)[1].lower()
    if ext in RUNTIME_STATE_EXTS:
        return "RUNTIME_STATE", f"extension {ext!r} is runtime state"
    if ext in GENERATED_EXTS:
        return "GENERATED", f"extension {ext!r} is a build artifact"

    # UNKNOWN fallback (the orchestrator will refine with git status)
    return "UNKNOWN", "no classification rule matched"


def classify_path_with_git_status(posix_path: str, git_tracked: bool, git_status: str) -> Tuple[str, str]:
    """Refine classification with git status. T0_TRACKED / CURRENT_TRACKED / CURRENT_UNTRACKED."""
    base_bucket, reason = classify_path(posix_path)
    if base_bucket in {"GARBAGE_INVALID", "SECRET_SENSITIVE", "RUNTIME_STATE", "GENERATED"}:
        return base_bucket, reason
    if base_bucket == "UNKNOWN":
        # Maybe subproject
        parts = posix_path.split("/")
        if parts and parts[0] in SUBPROJECT_DIRS:
            return "SUBPROJECT", f"under subproject {parts[0]!r}"
        if git_tracked:
            return "T0_TRACKED", "tracked in git (T0 commit)"
        return "CURRENT_UNTRACKED", f"git_tracked={git_tracked}, git_status={git_status!r}"
    return base_bucket, reason


# ---------------------------------------------------------------------------
# SHA-256. READ-ONLY. Streams the file so we don't load huge DETS into RAM.
# ---------------------------------------------------------------------------
def sha256_file(path: str, max_bytes: int = LARGE_FILE_BYTES) -> Optional[str]:
    if not os.path.isfile(path):
        return None
    try:
        size = os.path.getsize(path)
    except OSError:
        return None
    if size > max_bytes:
        # Per contract: do not hash files >100 MB (avoid 1.8 GB DETS).
        # Record size but skip hash; the inventory collector notes "skipped".
        return None
    h = hashlib.sha256()
    try:
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(1024 * 1024), b""):
                h.update(chunk)
    except OSError:
        return None
    return h.hexdigest()


# ---------------------------------------------------------------------------
# JSON output. Volatile fields (timestamps) are written; for RI-011 the
# canonicalizer strips them before comparison.
# ---------------------------------------------------------------------------
def write_json_atomic(path: str, obj: Dict[str, Any]) -> None:
    """Write JSON atomically. Uses .tmp + replace. The .tmp is in the same
    directory so the replace is atomic on Windows (os.replace)."""
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="\n") as f:
        json.dump(obj, f, ensure_ascii=False, indent=2, sort_keys=False)
        f.write("\n")
    os.replace(tmp, path)


def write_jsonl_atomic(path: str, rows: List[Dict[str, Any]]) -> None:
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="\n") as f:
        for r in rows:
            f.write(json.dumps(r, ensure_ascii=False, sort_keys=False))
            f.write("\n")
    os.replace(tmp, path)


# ---------------------------------------------------------------------------
# RI-011 canonicalizer — strip volatile fields so two runs of the same
# input produce identical content (modulo volatile metadata).
# ---------------------------------------------------------------------------
VOLATILE_KEYS = {
    "run", "collected_at", "produced_at", "run_started_at", "run_finished_at",
    "duration_seconds", "run_id", "hostname", "user",
    "pid", "elapsed_seconds",
}


def canonicalize_for_ri011(obj: Any) -> Any:
    """Recursively strip volatile keys. Deterministic, order-preserving."""
    if isinstance(obj, dict):
        return {
            k: canonicalize_for_ri011(v)
            for k, v in obj.items()
            if k not in VOLATILE_KEYS
        }
    if isinstance(obj, list):
        return [canonicalize_for_ri011(x) for x in obj]
    return obj


# ---------------------------------------------------------------------------
# Git invocation gate — M0-CLOSE-01.
#
# This is the ONLY permitted path for invoking git anywhere in
# certification/reconnaissance/ (orchestrator, collectors, tests).
# Policy is ALLOWLIST (default-deny): any git subcommand not explicitly
# listed in _GIT_ALLOWLIST is refused BEFORE execution by raising
# ForbiddenGitOperationError.
#
# Allowed (all read-only):
#   rev-parse, ls-tree, ls-files, status, for-each-ref, log, cat-file,
#   show (with --stat/--no-patch/--format only), diff (never mutates),
#   branch --format=... / --show-current (read-only listings only),
#   worktree add --detach <dir> <sha>  (worktree metadata only; the exact
#       shape the orchestrator needs; nothing else),
#   worktree remove --force <dir>,
#   worktree list, worktree prune --dry-run (read-only).
# Everything else (commit, push, reset, checkout, merge, rebase,
# cherry-pick, revert, rm, mv, stash, clean, branch -d/-D/-m, tag -d/-f,
# fetch, pull, clone, init, remote *, config *, worktree lock/unlock/
# move/repair, etc.) is refused.
# ---------------------------------------------------------------------------
import subprocess as _subprocess


class ForbiddenGitOperationError(RuntimeError):
    """Raised when a git invocation is not on the Move-0 allowlist."""


_GIT_ALLOWLIST_SIMPLE = frozenset({
    "rev-parse", "ls-tree", "ls-files", "status", "for-each-ref",
    "log", "cat-file", "diff",
})


def _git_args_allowed(args: tuple) -> bool:
    if not args:
        return False
    sub = args[0]
    if sub in _GIT_ALLOWLIST_SIMPLE:
        return True
    if sub == "show":
        # show is read-only only with these flags; bare `git show <sha>`
        # also only reads, but we restrict to the explicit forms used.
        rest = set(args[1:])
        return bool(rest) and rest <= {"--stat", "--no-patch", "--format=%B", "--format=%H", "--format=%T"}
    if sub == "branch":
        # Read-only listings only: exactly `--format=...` or `--show-current`.
        # `git branch -d/-D/-m`, bare `git branch`, etc. are refused.
        if len(args) == 2 and args[1] == "--show-current":
            return True
        if len(args) == 2 and args[1].startswith("--format="):
            return True
        return False
    if sub == "worktree":
        # Only the two exact shapes the orchestrator needs.
        if len(args) >= 2 and args[1] == "list":
            return True
        if len(args) >= 2 and args[1] == "prune" and set(args[2:]) <= {"--dry-run"}:
            return True
        if (len(args) == 5 and args[1] == "add" and args[2] == "--detach"):
            return True
        if (len(args) == 4 and args[1] == "remove" and args[2] == "--force"):
            return True
        return False
    return False


def run_git(repo: str, *args: str) -> tuple:
    """Run `git -C <repo> <args>`, enforcing the Move-0 allowlist FIRST.

    Returns (returncode, stdout, stderr) — same shape as the helpers it
    replaces. Raises ForbiddenGitOperationError BEFORE spawning any
    process when the subcommand is not allowed.
    """
    if not _git_args_allowed(args):
        raise ForbiddenGitOperationError(
            f"refused git subcommand (not on Move-0 allowlist): git {' '.join(args)}"
        )
    proc = _subprocess.run(
        ["git", "-C", repo, *args],
        capture_output=True, text=True, encoding="utf-8", errors="replace"
    )
    return proc.returncode, proc.stdout, proc.stderr


# ---------------------------------------------------------------------------
# Output of git status --porcelain, parsed into structured form.
# ---------------------------------------------------------------------------
def parse_git_status_porcelain(text: str) -> List[Tuple[str, str, str]]:
    """Returns list of (status_code, old_path, new_path). For renames, new_path != old_path."""
    out = []
    for line in text.splitlines():
        if len(line) < 4:
            continue
        code = line[:2]
        rest = line[3:]
        # Rename: "R  old -> new"
        if " -> " in rest:
            old, new = rest.split(" -> ", 1)
            old = old.strip('"')
            new = new.strip('"')
        else:
            old = rest.strip('"')
            new = old
        out.append((code, old, new))
    return out


# ---------------------------------------------------------------------------
# A small set of regex helpers used by source_inventory (AST-light, not parser).
# ---------------------------------------------------------------------------
ELIXIR_MODULE_RE = re.compile(r"^\s*defmodule\s+([\w\.]+)\s+do\b", re.MULTILINE)
ELIXIR_DEF_RE = re.compile(r"^\s*def\s+([\w\?!]+)\s*\(", re.MULTILINE)
ELIXIR_DEFDELEGATE_RE = re.compile(r"^\s*defdelegate\s+([\w\?!]+)\s*\(", re.MULTILINE)
ELIXIR_SPEC_RE = re.compile(r"@spec\s+([^\n]+)")
PYTHON_DEF_RE = re.compile(r"^def\s+([\w]+)\s*\(", re.MULTILINE)
PYTHON_CLASS_RE = re.compile(r"^class\s+([\w]+)\s*[\(:]")
PYTHON_ASYNC_DEF_RE = re.compile(r"^async\s+def\s+([\w]+)\s*\(", re.MULTILINE)
CONTRACT_HINT_RE = re.compile(r"\b(verify_|assert_|test_|check_|assertThat)\w*", re.IGNORECASE)


def extract_elixir_signals(text: str) -> Dict[str, Any]:
    modules = ELIXIR_MODULE_RE.findall(text)
    defs = ELIXIR_DEF_RE.findall(text)
    defdelegates = ELIXIR_DEFDELEGATE_RE.findall(text)
    specs = ELIXIR_SPEC_RE.findall(text)
    contract_hints = list(set(CONTRACT_HINT_RE.findall(text)))[:20]
    return {
        "module_count": len(modules),
        "modules": modules[:50],
        "public_def_count": len(defs),
        "public_defs_sample": defs[:30],
        "defdelegate_count": len(defdelegates),
        "spec_count": len(specs),
        "specs_sample": specs[:10],
        "contract_hint_count": len(contract_hints),
        "contract_hints": contract_hints,
    }


def extract_python_signals(text: str) -> Dict[str, Any]:
    defs = PYTHON_DEF_RE.findall(text)
    async_defs = PYTHON_ASYNC_DEF_RE.findall(text)
    classes = PYTHON_CLASS_RE.findall(text)
    contract_hints = list(set(CONTRACT_HINT_RE.findall(text)))[:20]
    return {
        "function_count": len(defs),
        "functions_sample": defs[:30],
        "async_function_count": len(async_defs),
        "class_count": len(classes),
        "classes_sample": classes[:30],
        "contract_hint_count": len(contract_hints),
        "contract_hints": contract_hints,
    }
