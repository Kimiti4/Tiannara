"""
TIA_FORENSIC_RECON_ENGINE — repo_inventory collector.

Move 0. Classifies every file in the working tree into one of ten buckets
and records size + sha256 (where safe). Produces T0_FILES.jsonl + T0_HASHES.jsonl
inputs for the orchestrator.

READ-ONLY. No mutation. The .env* content is NEVER read (only size + sha256).
"""
from __future__ import annotations

import os
from typing import Any, Dict, List, Set, Tuple

from . import _common as C


WINDOWS_DEVICES = {"nul", "con", "prn", "aux", "com1", "com2", "com3", "lpt1", "lpt2"}


def _run_git(repo: str, *args: str, allow_fail: bool = False) -> Tuple[int, str]:
    # M0-CLOSE-01: all git invocations go through the Move-0 allowlist gate.
    code, out, err = C.run_git(repo, *args)
    if not allow_fail and code != 0:
        # Soft-fail: we want stdout even on non-zero return (e.g., empty grep).
        return code, out
    return code, out + err


def _relpath_windows_to_posix(root: str, abs_path: str) -> str:
    """Convert an absolute Windows path under root to a POSIX-style path
    (forward slashes, relative to root). Preserves the on-disk filename
    exactly, including any leading UTF-8 BOM (0xEF 0xBB 0xBF) that Windows
    sometimes produces in path-mangled garbage dirs. Preserving the BOM
    means the JSONL path matches the exact bytes git stored in T0."""
    rel = os.path.relpath(abs_path, root)
    return rel.replace("\\", "/")


def _walk_working_tree(root: str, skip_dirs: set) -> List[str]:
    """Walk the working tree, returning POSIX paths relative to root.

    The top-level `.git` entry is ALWAYS skipped, in both of its forms:
      - source repo: `.git/` directory (Git internals, not T0 content)
      - linked worktree: `.git` FILE containing `gitdir: <random-tmpdir>/...`
        (execution infrastructure; the tmpdir is random per run, so hashing
        it would make every run differ — a determinism violation)
    Git-derived information (tracked set, refs, tree hash) is obtained
    through Git commands, never through the filesystem walk. See
    TIA_RECON_CONTRACT.yaml and the Move-0 review point #9.
    """
    out: List[str] = []
    for dirpath, dirnames, filenames in os.walk(root, followlinks=False, onerror=lambda e: None):
        # Drop the requested subtrees in-place
        dirnames[:] = [d for d in dirnames if d not in skip_dirs]
        # Skip the top-level .git directory itself if os.walk yields it
        # (it won't when skip_dirs contains it, but be explicit).
        rel_dir = _relpath_windows_to_posix(root, dirpath)
        if rel_dir == ".git" or rel_dir.startswith(".git/"):
            dirnames[:] = []
            continue
        for fn in filenames:
            full = os.path.join(dirpath, fn)
            if not os.path.isfile(full):
                continue
            rel = _relpath_windows_to_posix(root, full)
            # Skip the top-level `.git` FILE (linked-worktree pointer).
            if rel == ".git":
                continue
            out.append(rel)
    out.sort()
    return out


def _git_tracked_set(repo: str) -> Set[str]:
    code, out = _run_git(repo, "ls-files", allow_fail=True)
    return set(line.strip().replace("\\", "/") for line in out.splitlines() if line.strip())


def _git_untracked_set(repo: str) -> Set[str]:
    code, out = _run_git(repo, "status", "--porcelain", "--untracked-files=all", allow_fail=True)
    paths: Set[str] = set()
    for line in out.splitlines():
        if line.startswith("?? "):
            raw = line[3:].strip()
            if raw.startswith('"') and raw.endswith('"'):
                raw = raw[1:-1]
            paths.add(raw.replace("\\", "/"))
    return paths


def _git_t0_paths(repo: str) -> List[str]:
    """Return the canonical T0 path list (what `git ls-tree -r --name-only T0`
    would return, but normalized). This is the AUTHORITATIVE list of T0
    files; we use it as the source of truth for paths in T0_FILES.jsonl so
    the JSONL paths match what git would report (avoiding Windows
    filesystem normalization mismatches like BOM vs fullwidth colon)."""
    code, out = _run_git(repo, "ls-tree", "-r", "--name-only", C.T0_TAG, allow_fail=True)
    paths = []
    for line in out.splitlines():
        line = line.strip()
        if not line:
            continue
        # Normalize git's quoted-octal form: strip surrounding quotes, decode
        # \NNN octal escapes back to the raw bytes (preserves BOM and
        # fullwidth-colon path-mangled filenames).
        if len(line) >= 2 and line[0] == '"' and line[-1] == '"':
            line = line[1:-1]
        decoded = bytearray()
        i = 0
        while i < len(line):
            if line[i] == "\\" and i + 1 < len(line) and line[i+1] in "01234567":
                j = i + 1
                octal = ""
                while j < len(line) and len(octal) < 3 and line[j] in "01234567":
                    octal += line[j]
                    j += 1
                decoded.append(int(octal, 8))
                i = j
            else:
                decoded.append(ord(line[i]))
                i += 1
        try:
            paths.append(decoded.decode("utf-8"))
        except UnicodeDecodeError:
            paths.append(decoded.decode("latin-1", errors="replace"))
    return paths


def collect(repo: str) -> Dict[str, Any]:
    """Return the repo_inventory evidence bundle.

    The path for each file is the CANONICAL T0 path (from `git ls-tree -r
    --name-only T0`), not the on-disk path. This avoids Windows filesystem
    normalization mismatches (BOM vs fullwidth colon) that would break
    set comparisons in the RI tests.

    For files NOT in T0 (untracked, runtime artifacts, subprojects tracked
    elsewhere), we fall back to the os.walk-discovered path.
    """
    t0_paths = _git_t0_paths(repo)
    t0_path_set = set(t0_paths)
    working_paths = _walk_working_tree(repo, skip_dirs=set())
    tracked_set = _git_tracked_set(repo)
    untracked_set = _git_untracked_set(repo)

    items: List[Dict[str, Any]] = []
    bucket_keys = [
        "T0_TRACKED", "T0_EXCLUDED", "CURRENT_TRACKED", "CURRENT_UNTRACKED",
        "RUNTIME_STATE", "SECRET_SENSITIVE", "GARBAGE_INVALID", "SUBPROJECT",
        "GENERATED", "UNKNOWN"
    ]
    bucket_counts = {k: 0 for k in bucket_keys}

    # Build a map of on-disk posix path -> canonical T0 path (if applicable).
    # For T0 files, prefer the canonical T0 path from git ls-tree.
    on_disk_to_canonical: Dict[str, str] = {}
    for op in working_paths:
        # If this on-disk path matches a T0 path, map it
        for tp in t0_path_set:
            # Exact match is best; otherwise try matching by basename for
            # garbage files that may have encoding variants.
            if op == tp:
                on_disk_to_canonical[op] = tp
                break
        else:
            on_disk_to_canonical[op] = op  # not in T0, use on-disk path

    # Build items from T0 paths (canonical) + on-disk-only paths.
    seen_paths: Set[str] = set()

    for t0p in t0_paths:
        seen_paths.add(t0p)
        full = os.path.join(repo, t0p)
        if not os.path.isfile(full):
            # File not present in the worktree (shouldn't happen for T0)
            size = 0
            sha = None
        else:
            try:
                size = os.path.getsize(full)
            except OSError:
                size = 0
            sha = C.sha256_file(full)
        is_tracked = t0p in tracked_set
        git_status = "untracked" if t0p in untracked_set else ("modified" if is_tracked else "clean")
        bucket, reason = C.classify_path_with_git_status(t0p, is_tracked, git_status)
        items.append({
            "path": t0p,
            "size_bytes": size,
            "sha256": sha,
            "bucket": bucket,
            "reason": reason,
            "git_tracked": is_tracked,
            "git_status": git_status,
        })
        bucket_counts[bucket] = bucket_counts.get(bucket, 0) + 1

    # Add on-disk-only paths (not in T0).
    for op in working_paths:
        canonical = on_disk_to_canonical.get(op, op)
        if canonical in seen_paths:
            continue
        seen_paths.add(canonical)
        try:
            size = os.path.getsize(os.path.join(repo, op))
        except OSError:
            size = 0
        is_tracked = canonical in tracked_set
        git_status = "untracked" if canonical in untracked_set else ("modified" if is_tracked else "clean")
        bucket, reason = C.classify_path_with_git_status(canonical, is_tracked, git_status)
        items.append({
            "path": canonical,
            "size_bytes": size,
            "sha256": C.sha256_file(os.path.join(repo, op)),
            "bucket": bucket,
            "reason": reason,
            "git_tracked": is_tracked,
            "git_status": git_status,
        })
        bucket_counts[bucket] = bucket_counts.get(bucket, 0) + 1

    return {
        "schema_version": "1.0.0",
        "evidence_kind": "repo_inventory",
        "produced_by": {"collector": "repo_inventory", "contract_version": C.CONTRACT_VERSION},
        "produced_at_t0": C.T0_COMMIT,
        "summary": {
            "total_files": len(items),
            "bucket_counts": bucket_counts,
            "git_tracked_count": len(tracked_set),
            "git_untracked_count": len(untracked_set),
            "current_tracked_only_count": len(tracked_set - untracked_set),
        },
        "items": items,
    }
