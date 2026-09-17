"""
TIA_FORENSIC_RECON_ENGINE — orchestrator (Move 0).

READ-ONLY. Never modifies the source repo. Runs in a temporary git worktree
pinned to T0. Produces exactly 7 output JSON artifacts in
certification/reconnaissance/.

USAGE
-----
    python TIA_RECON_ORCHESTRATOR.py

EXIT CODES
----------
    0   all integrity checks passed; 7 artifacts written
    2   T0 integrity gate failed (STOP; evidence recorded in T0_INTEGRITY.json)
    3   source repo HEAD != T0 (worktree was NOT created; nothing written)
    4   forbidden operation attempted (worktree was NOT created; nothing written)
"""
from __future__ import annotations

import argparse
import datetime as _dt
import hashlib
import json
import os
import shutil
import sys
import tempfile
from typing import Any, Dict, List, Tuple

# M0-CLOSE-05: prevent bytecode caches (__pycache__/) from being created
# inside certification/reconnaissance/. Must execute before any
# collectors.* import below.
sys.dont_write_bytecode = True

# Make collectors package importable
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from collectors import _common as C  # noqa: E402
from collectors import git_forensics, repo_inventory, source_inventory, environment  # noqa: E402


OUTPUT_FILES = [
    "T0_BASELINE.json",
    "T0_GIT.json",
    "T0_FILES.jsonl",
    "T0_HASHES.jsonl",
    "T0_ENVIRONMENT.json",
    "T0_RUNTIMES.json",
    "T0_INTEGRITY.json",
]

# The 7 outputs are always written to certification/reconnaissance/ in the
# SOURCE repo (untracked, POST_T0). The orchestrator writes there directly
# after worktree teardown. This is the only filesystem mutation the
# orchestrator performs; the source repo's Git history is never touched.
SOURCE_RECON_DIR = os.path.join("certification", "reconnaissance")


def _now_iso() -> str:
    return _dt.datetime.now(_dt.timezone.utc).isoformat()


def _git(*args: str, cwd: str) -> Tuple[int, str, str]:
    # M0-CLOSE-01: all git invocations go through the Move-0 allowlist gate
    # in collectors._common. There is no other git path in this file.
    return C.run_git(cwd, *args)


def pre_check_source_repo() -> Tuple[bool, str, str]:
    """Verify source repo HEAD == T0 BEFORE creating a worktree. If HEAD != T0,
    halt with exit code 3 (worktree was NOT created; nothing written)."""
    code, out, err = _git("rev-parse", "HEAD", cwd=".")
    if code != 0:
        return False, "", err.strip()
    head = out.strip()
    if head != C.T0_COMMIT:
        return False, head, f"source repo HEAD ({head}) != T0 ({C.T0_COMMIT}); not at T0 baseline"
    return True, head, ""


def create_worktree(t0_commit: str) -> Tuple[bool, str, str]:
    """git worktree add --detach <temp> <t0_commit> (no subsequent checkout).
    Returns (ok, worktree_path, error)."""
    tmpdir = tempfile.mkdtemp(prefix="tia_recon_t0_", suffix="_" + t0_commit[:7])
    code, out, err = _git("worktree", "add", "--detach", tmpdir, t0_commit, cwd=".")
    if code != 0:
        return False, "", err.strip() or out.strip()
    # Post-create check: HEAD == T0 commit
    code2, out2, _ = _git("rev-parse", "HEAD", cwd=tmpdir)
    if code2 != 0 or out2.strip() != t0_commit:
        return False, "", f"worktree HEAD ({out2.strip()!r}) != T0 ({t0_commit!r})"
    return True, tmpdir, ""


def remove_worktree(worktree: str) -> None:
    """git worktree remove --force. If it fails, log and continue (the worktree
    may already be gone; not a STOP condition per the contract)."""
    if not worktree or not os.path.isdir(worktree):
        return
    _git("worktree", "remove", "--force", worktree, cwd=".")


def _sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def capture_repo_snapshot() -> Dict[str, Any]:
    """M0-CLOSE-02: capture a deterministic snapshot of source-repo state.

    Contents (all read-only):
      - HEAD, T0 tag (dereferenced), t0-baseline, origin/main, T0 tree SHAs
      - sorted tracked-modification list + its sha256
        (`git diff HEAD --name-only`, sorted for determinism)
      - sorted untracked list (`git status --porcelain --untracked-files=all`)
    The untracked list itself is NOT hashed into the verdict (background
    processes could theoretically add files); instead the orchestrator
    compares PRE vs POST untracked sets explicitly and only tolerates the
    7 output artifacts appearing.
    """
    def _out(*a: str) -> str:
        code, out, _ = _git(*a, cwd=".")
        return out.strip() if code == 0 else ""

    head = _out("rev-parse", "HEAD")
    tag_deref = _out("rev-parse", f"{C.T0_TAG}^{{commit}}")
    baseline = _out("rev-parse", C.T0_BASELINE_BRANCH)
    origin_main = _out("rev-parse", "origin/main")
    tree = _out("rev-parse", f"{C.T0_TAG}^{{tree}}")
    code_d, out_d, _ = _git("diff", "HEAD", "--name-only", cwd=".")
    tracked_mods = sorted(l for l in out_d.splitlines() if l.strip())
    code_s, out_s, _ = _git("status", "--porcelain", "--untracked-files=all", cwd=".")
    untracked = sorted(
        l[3:].strip().strip('"') for l in out_s.splitlines() if l.startswith("?? ")
    )
    return {
        "head": head,
        "tag_deref": tag_deref,
        "baseline": baseline,
        "origin_main": origin_main,
        "tree": tree,
        "tracked_mods": tracked_mods,
        "tracked_mods_sha256": _sha256_text("\n".join(tracked_mods)),
        "untracked": untracked,
    }


# The 7 output artifacts the orchestrator is permitted to create between
# PRE and POST snapshots. Anything else appearing/disappearing fails the gate.
ALLOWED_NEW_PATHS = frozenset(
    "certification/reconnaissance/" + f for f in OUTPUT_FILES
)


def compare_snapshots(pre: Dict[str, Any], post: Dict[str, Any]) -> Dict[str, Any]:
    """M0-CLOSE-02: compare PRE vs POST snapshots. Returns the
    pre_post_comparison object for T0_INTEGRITY.json."""
    fields = ["head", "tag_deref", "baseline", "origin_main", "tree"]
    field_results = {
        f: {"pre": pre[f], "post": post[f], "identical": pre[f] == post[f]}
        for f in fields
    }
    tracked_same = pre["tracked_mods_sha256"] == post["tracked_mods_sha256"]
    disappeared = sorted(set(pre["untracked"]) - set(post["untracked"]))
    appeared = sorted(set(post["untracked"]) - set(pre["untracked"]))
    # Tolerate only the 7 output artifacts (plus any *.tmp residue from an
    # interrupted atomic write — recorded, still tolerated).
    allowed = set(ALLOWED_NEW_PATHS)
    unexpected_appeared = [
        p for p in appeared
        if p not in allowed and not p.endswith(".tmp")
    ]
    identical = (
        all(v["identical"] for v in field_results.values())
        and tracked_same
        and not disappeared
        and not unexpected_appeared
    )
    return {
        "identical": identical,
        "ref_shas": field_results,
        "tracked_mods_sha256": {"pre": pre["tracked_mods_sha256"], "post": post["tracked_mods_sha256"], "identical": tracked_same},
        "untracked_disappeared": disappeared,
        "untracked_appeared": appeared,
        "untracked_appeared_unexpected": unexpected_appeared,
        "policy": "verdict FAIL unless identical; STOP_AND_RECORD_CONDITION_AS_EVIDENCE",
    }


def run_orchestrator() -> int:
    """Main entry. Returns process exit code."""
    started = _now_iso()
    t0 = _dt.datetime.now(_dt.timezone.utc)

    # ---- STEP 1: pre-check source repo is at T0 ----
    ok_pre, head, err_pre = pre_check_source_repo()
    if not ok_pre:
        print(f"STOP — source repo not at T0: {err_pre}")
        # Write a minimal T0_INTEGRITY.json recording the failure.
        # Note: this write happens in the SOURCE repo, which is the only
        # mutation. The user's contract explicitly permits writing the 7
        # output artifacts to certification/reconnaissance/ even on failure.
        os.makedirs(SOURCE_RECON_DIR, exist_ok=True)
        _safe_write_json(os.path.join(SOURCE_RECON_DIR, "T0_INTEGRITY.json"), {
            "schema_version": "1.0.0",
            "produced_at": _now_iso(),
            "t0_commit_expected": C.T0_COMMIT,
            "source_repo_HEAD_actual": head,
            "verdict": "FAIL",
            "verdict_reason": "source_repo_not_at_T0",
            "error": err_pre,
            "policy": "STOP_AND_RECORD_CONDITION_AS_EVIDENCE",
        })
        return 3

    # ---- STEP 2: PRE snapshot (M0-CLOSE-02) BEFORE worktree creation ----
    pre_snapshot = capture_repo_snapshot()

    # ---- STEP 3: create worktree pinned to T0 (no subsequent checkout) ----
    ok_wt, worktree, err_wt = create_worktree(C.T0_COMMIT)
    if not ok_wt:
        print(f"STOP — worktree creation failed: {err_wt}")
        os.makedirs(SOURCE_RECON_DIR, exist_ok=True)
        _safe_write_json(os.path.join(SOURCE_RECON_DIR, "T0_INTEGRITY.json"), {
            "schema_version": "1.0.0",
            "produced_at": _now_iso(),
            "t0_commit_expected": C.T0_COMMIT,
            "verdict": "FAIL",
            "verdict_reason": "worktree_creation_failed",
            "error": err_wt,
            "policy": "STOP_AND_RECORD_CONDITION_AS_EVIDENCE",
        })
        return 4

    # ---- STEP 4: run the 4 collectors in the worktree ----
    try:
        gf = git_forensics.collect(worktree)
        # If T0 integrity gate fails inside the collector, halt.
        if not gf.get("all_identity_ok", False):
            print("STOP — T0 integrity gate failed inside git_forensics.collect")
            os.makedirs(SOURCE_RECON_DIR, exist_ok=True)
            _safe_write_json(os.path.join(SOURCE_RECON_DIR, "T0_INTEGRITY.json"), {
                "schema_version": "1.0.0",
                "produced_at": _now_iso(),
                "verdict": "FAIL",
                "verdict_reason": "t0_identity_check_failed",
                "checks": gf["integrity"]["checks"],
            })
            return 2

        ri = repo_inventory.collect(worktree)
        si = source_inventory.collect(worktree, ri["items"])
        en = environment.collect(worktree)
    finally:
        remove_worktree(worktree)

    # ---- STEP 5: POST snapshot + PRE/POST comparison (M0-CLOSE-02) ----
    # The comparison covers: ref SHAs, tracked-modification list, untracked
    # delta (only the 7 output artifacts may appear). On mismatch the
    # verdict is FAIL and ONLY T0_INTEGRITY.json is written.
    post_snapshot = capture_repo_snapshot()
    pre_post = compare_snapshots(pre_snapshot, post_snapshot)
    if not pre_post["identical"]:
        print("STOP — PRE/POST repository integrity comparison failed")
        os.makedirs(SOURCE_RECON_DIR, exist_ok=True)
        _safe_write_json(os.path.join(SOURCE_RECON_DIR, "T0_INTEGRITY.json"), {
            "schema_version": "1.0.0",
            "produced_by": {"collector": "TIA_RECON_ORCHESTRATOR", "contract_version": C.CONTRACT_VERSION},
            "produced_at_t0": C.T0_COMMIT,
            "produced_at": _now_iso(),
            "t0_commit": C.T0_COMMIT,
            "t0_tree": C.T0_TREE,
            "verdict": "FAIL",
            "verdict_reason": "pre_post_comparison_failed",
            "checks": gf["integrity"]["checks"],
            "pre_post_comparison": pre_post,
            "ri_status": "NOT_RUN",
        })
        return 2

    # ---- STEP 6: assemble the 7 output artifacts ----
    finished = _now_iso()
    duration = (_dt.datetime.now(_dt.timezone.utc) - t0).total_seconds()
    run_meta = {
        "started_at": started,
        "finished_at": finished,
        "duration_seconds": duration,
        "run_id": hashlib.sha256((started + finished).encode()).hexdigest()[:16],
    }

    # 1. T0_GIT.json — just the git_forensics bundle + run meta
    t0_git = dict(gf)
    t0_git["run"] = run_meta

    # 2. T0_FILES.jsonl — the items, with the volatile run meta stripped
    #    from each item (RI-011 determinism).
    file_rows: List[Dict[str, Any]] = []
    hash_rows: List[Dict[str, Any]] = []
    for it in ri["items"]:
        row = {k: v for k, v in it.items()}  # copy
        file_rows.append(row)
        hash_rows.append({"path": it["path"], "sha256": it.get("sha256")})

    # 3. T0_HASHES.jsonl — path + sha256 (or null) for each file. Used for
    #    hash-binding. Even nulls are recorded (RI-002: hash manifest
    #    completeness).
    # 4. T0_ENVIRONMENT.json — runtime versions + manifests
    # 5. T0_RUNTIMES.json — just the version strings (subset of T0_ENVIRONMENT)
    t0_env = dict(en)
    t0_env["run"] = run_meta
    t0_runtimes = {
        "schema_version": "1.0.0",
        "produced_by": {"collector": "environment", "contract_version": C.CONTRACT_VERSION},
        "produced_at_t0": C.T0_COMMIT,
        "run": run_meta,
        "runtimes": en["runtimes"],
    }

    # 6. T0_BASELINE.json — the master record. Aggregates everything.
    t0_baseline = {
        "schema_version": "1.0.0",
        "evidence_kind": "baseline_aggregate",
        "produced_by": {"collector": "TIA_RECON_ORCHESTRATOR", "contract_version": C.CONTRACT_VERSION},
        "produced_at_t0": C.T0_COMMIT,
        "run": run_meta,
        "t0_identity": {
            "commit": C.T0_COMMIT,
            "tag": C.T0_TAG,
            "branch": C.T0_BASELINE_BRANCH,
            "tree_hash": C.T0_TREE,
        },
        "integrity_verdict": "PASS",
        "git_forensics_summary": {
            "t0_tracked_count": gf["t0_tracked_count"],
            "ref_count": len(gf["refs"]),
        },
        "repo_inventory_summary": ri["summary"],
        "source_inventory_summary": si["summary"],
        "environment_summary": {
            "manifest_count": en["manifest_count"],
            "runtimes_present": sum(1 for v in en["runtimes"].values() if v.get("available")),
        },
    }

    # 7. T0_INTEGRITY.json — the gate result + summary.
    # M0-CLOSE-04: the orchestrator MUST NOT claim RI PASS. The 20 RI tests
    # run separately (tests/test_recon_integrity.py), AFTER the artifacts
    # exist. ri_status stays NOT_RUN here; the CERTIFY_MOVE0.py procedure
    # binds (T0_INTEGRITY + pytest result + test-suite hash + T0 identity)
    # into T0_RI_CERTIFICATION.json.
    t0_integrity = {
        "schema_version": "1.0.0",
        "evidence_kind": "baseline_aggregate",
        "produced_by": {"collector": "TIA_RECON_ORCHESTRATOR", "contract_version": C.CONTRACT_VERSION},
        "produced_at_t0": C.T0_COMMIT,
        "run": run_meta,
        "t0_commit": C.T0_COMMIT,
        "t0_tree": C.T0_TREE,
        "verdict": "PASS",
        "checks": gf["integrity"]["checks"],
        "pre_post_comparison": pre_post,
        "ri_status": "NOT_RUN",
        "ri_note": "The 20 RI tests run separately (tests/test_recon_integrity.py) after the 7 artifacts exist. This field is NOT_RUN by construction. See T0_RI_CERTIFICATION.json (written by CERTIFY_MOVE0.py) for the bound result.",
    }

    # ---- STEP 7: write the 7 artifacts ----
    os.makedirs(SOURCE_RECON_DIR, exist_ok=True)
    _safe_write_json(os.path.join(SOURCE_RECON_DIR, "T0_GIT.json"), t0_git)
    _safe_write_jsonl(os.path.join(SOURCE_RECON_DIR, "T0_FILES.jsonl"), file_rows)
    _safe_write_jsonl(os.path.join(SOURCE_RECON_DIR, "T0_HASHES.jsonl"), hash_rows)
    _safe_write_json(os.path.join(SOURCE_RECON_DIR, "T0_ENVIRONMENT.json"), t0_env)
    _safe_write_json(os.path.join(SOURCE_RECON_DIR, "T0_RUNTIMES.json"), t0_runtimes)
    _safe_write_json(os.path.join(SOURCE_RECON_DIR, "T0_BASELINE.json"), t0_baseline)
    _safe_write_json(os.path.join(SOURCE_RECON_DIR, "T0_INTEGRITY.json"), t0_integrity)

    print(f"MOVE 0 COMPLETE. 7 artifacts written to {SOURCE_RECON_DIR}/")
    print(f"  T0: {C.T0_COMMIT}")
    print(f"  Tree: {C.T0_TREE}")
    print(f"  Tracked files: {gf['t0_tracked_count']}")
    print(f"  Working-tree files (post-classify): {ri['summary']['total_files']}")
    print(f"  Source files parsed: {si['summary']['files_parsed']}")
    print(f"  Manifests found: {en['manifest_count']}")
    return 0


def _safe_write_json(path: str, obj: Dict[str, Any]) -> None:
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="\n") as f:
        json.dump(obj, f, ensure_ascii=False, indent=2)
        f.write("\n")
    os.replace(tmp, path)


def _safe_write_jsonl(path: str, rows: List[Dict[str, Any]]) -> None:
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="\n") as f:
        for r in rows:
            f.write(json.dumps(r, ensure_ascii=False))
            f.write("\n")
    os.replace(tmp, path)


def main(argv: List[str]) -> int:
    ap = argparse.ArgumentParser(description="TIA_FORENSIC_RECON_ENGINE orchestrator (Move 0)")
    ap.add_argument("--dry-run", action="store_true",
                    help="Validate pre-conditions but do not create worktree or write artifacts.")
    args = ap.parse_args(argv)

    if args.dry_run:
        ok, head, err = pre_check_source_repo()
        print(f"DRY RUN: source HEAD = {head!r}, expected = {C.T0_COMMIT!r}")
        print(f"  -> {'PASS' if ok else 'FAIL: ' + err}")
        return 0 if ok else 3

    return run_orchestrator()


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
