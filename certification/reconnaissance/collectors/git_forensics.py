"""
TIA_FORENSIC_RECON_ENGINE — git_forensics collector.

Move 0. Verifies the T0 identity (T0-INTEGRITY-001) and captures the
three-way classification seed: T0_TRACKED, T0_EXCLUDED, CURRENT_TRACKED,
CURRENT_UNTRACKED.

READ-ONLY. No git write operations. The orchestrator handles worktree
creation; this collector runs in whichever directory the orchestrator
passes (source repo for the T0 integrity check; worktree for the tree hash).
"""
from __future__ import annotations

import json
import os
from typing import Any, Dict, List

from . import _common as C


def _run_git(repo: str, *args: str) -> str:
    # M0-CLOSE-01: all git invocations go through the Move-0 allowlist gate.
    _, out, _ = C.run_git(repo, *args)
    return out


def collect(repo: str) -> Dict[str, Any]:
    """Return the git_forensics evidence bundle. The orchestrator validates
    T0-INTEGRITY-001 from this bundle.

    The bundle is deterministic: no timestamps, no run_id, no volatile
    metadata. The bundle itself is the canonical T0 identity witness."""
    # 1. T0 identity checks (T0-INTEGRITY-001).
    # NOTE: `git rev-parse T0` returns the annotated TAG OBJECT's own hash
    # (not the commit it points to). To dereference to the commit, we use
    # `T0^{commit}`. This is the contract: "tag T0 resolves to commit 9753a6d".
    head_sha = _run_git(repo, "rev-parse", "HEAD").strip()
    t0_tag_sha = _run_git(repo, "rev-parse", f"{C.T0_TAG}^{{commit}}").strip()
    t0_baseline_sha = _run_git(repo, "rev-parse", C.T0_BASELINE_BRANCH).strip()
    origin_main_sha = _run_git(repo, "rev-parse", "origin/main").strip()
    t0_tree_sha = _run_git(repo, "rev-parse", f"{C.T0_TAG}^{{tree}}").strip()

    identity_checks = {
        "tag_T0_resolves_to_commit": (t0_tag_sha == C.T0_COMMIT, t0_tag_sha),
        "t0_baseline_resolves_to_commit": (t0_baseline_sha == C.T0_COMMIT, t0_baseline_sha),
        "origin_main_resolves_to_commit": (origin_main_sha == C.T0_COMMIT, origin_main_sha),
        "source_repo_HEAD_equals_T0": (head_sha == C.T0_COMMIT, head_sha),
        "t0_tree_hash_reproducible": (t0_tree_sha == C.T0_TREE, t0_tree_sha),
    }
    all_identity_ok = all(ok for ok, _ in identity_checks.values())
    t0_integrity_ok = all_identity_ok

    # 2. T0 commit metadata (deterministic, from git cat-file).
    commit_meta_text = _run_git(repo, "cat-file", "commit", C.T0_COMMIT)
    commit_meta: Dict[str, Any] = {}
    if commit_meta_text:
        lines = commit_meta_text.split("\n")
        # First line is "tree <sha>"; second is "parent <sha>"; third is "author ..."
        for ln in lines[:6]:
            if " " in ln:
                k, v = ln.split(" ", 1)
                if k in {"tree", "parent", "author", "committer"}:
                    commit_meta[k] = v
        commit_meta["size_bytes"] = len(commit_meta_text.encode("utf-8"))

    # 3. T0 commit message (deterministic).
    t0_commit_message = _run_git(repo, "log", "-1", "--format=%B", C.T0_TAG).strip()

    # 4. T0_TRACKED file list (deterministic, sorted).
    t0_tracked_text = _run_git(repo, "ls-tree", "-r", "--name-only", C.T0_TAG)
    t0_tracked = sorted([ln.strip() for ln in t0_tracked_text.splitlines() if ln.strip()])

    # 5. Branch listing (deterministic).
    branches_text = _run_git(repo, "for-each-ref", "--format=%(refname:short) %(objectname:short)", "refs/heads/", "refs/remotes/", "refs/tags/")
    refs: List[Dict[str, str]] = []
    for ln in branches_text.splitlines():
        if " " in ln:
            name, sha = ln.split(" ", 1)
            refs.append({"ref": name, "sha": sha})

    # 6. T0_INTEGRITY-001 verdict.
    integrity = {
        "test_id": "T0-INTEGRITY-001",
        "verdict": "PASS" if t0_integrity_ok else "FAIL",
        "expected_t0_commit": C.T0_COMMIT,
        "expected_t0_tree": C.T0_TREE,
        "checks": {k: {"pass": ok, "actual": actual} for k, (ok, actual) in identity_checks.items()},
        "on_failure_policy": "STOP_AND_RECORD_CONDITION_AS_EVIDENCE",
    }

    return {
        "schema_version": "1.0.0",
        "evidence_kind": "git_forensics",
        "produced_by": {
            "collector": "git_forensics",
            "contract_version": C.CONTRACT_VERSION,
        },
        "produced_at_t0": C.T0_COMMIT,
        "integrity": integrity,
        "commit_meta": commit_meta,
        "t0_commit_message": t0_commit_message,
        "t0_tracked_count": len(t0_tracked),
        "t0_tracked_sample_first_10": t0_tracked[:10],
        "t0_tracked_sample_last_10": t0_tracked[-10:],
        "refs": refs,
        "all_identity_ok": all_identity_ok,
    }
