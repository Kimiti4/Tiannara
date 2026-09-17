"""
TIA_FORENSIC_RECON_ENGINE — Move-0 certification procedure.

M0-CLOSE-03 + M0-CLOSE-04 binding. This script is NOT part of the evidence
collection; it VERIFIES the collection and binds the results.

What it does (in order):
  1. Runs the orchestrator TWICE (run A, run B), capturing the 7 artifacts
     after each run into temp directories OUTSIDE the repository.
  2. Canonicalizes both runs (strips volatile run metadata via the same
     canonicalizer the RI-011 test uses) and compares byte-for-byte.
     Mismatch -> FAIL, STOP, no certification artifact.
  3. Runs the 20-test pytest suite (python -B) and captures pass/fail/errors.
  4. Computes sha256 of the test-suite file (test_recon_integrity.py).
  5. Writes T0_RI_CERTIFICATION.json into certification/reconnaissance/
     binding: T0 identity + two-run determinism result + pytest result +
     test-suite hash.

USAGE
-----
    python CERTIFY_MOVE0.py

EXIT CODES
----------
    0   certified (two runs identical AND pytest 20/20)
    1   not certified (mismatch or pytest failure); T0_RI_CERTIFICATION.json
        is still written with verdict FAIL so the failure is evidence.

READ-ONLY with respect to T0: the script never modifies tracked files,
never commits, never pushes. It writes exactly one file:
certification/reconnaissance/T0_RI_CERTIFICATION.json (untracked, POST_T0).
"""
from __future__ import annotations

import datetime as _dt
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile

# M0-CLOSE-05: no bytecode caches.
sys.dont_write_bytecode = True

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from collectors import _common as C  # noqa: E402

ARTIFACTS = [
    "T0_BASELINE.json",
    "T0_GIT.json",
    "T0_FILES.jsonl",
    "T0_HASHES.jsonl",
    "T0_ENVIRONMENT.json",
    "T0_RUNTIMES.json",
    "T0_INTEGRITY.json",
]
REPO_ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))


def _now_iso() -> str:
    return _dt.datetime.now(_dt.timezone.utc).isoformat()


def _sha256_file(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def _sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def _run_orchestrator() -> tuple:
    """Run the orchestrator as a subprocess. Returns (exit_code, stdout_tail)."""
    proc = subprocess.run(
        [sys.executable, os.path.join(HERE, "TIA_RECON_ORCHESTRATOR.py")],
        cwd=REPO_ROOT,
        capture_output=True, text=True, encoding="utf-8", errors="replace",
    )
    tail = "\n".join((proc.stdout or "").splitlines()[-8:])
    return proc.returncode, tail


def _snapshot_artifacts(dest_dir: str) -> dict:
    """Copy the 7 artifacts into dest_dir and return {name: sha256}."""
    os.makedirs(dest_dir, exist_ok=True)
    out = {}
    for name in ARTIFACTS:
        src = os.path.join(HERE, name)
        dst = os.path.join(dest_dir, name)
        shutil.copy2(src, dst)
        out[name] = _sha256_file(dst)
    return out


def _canonical_form(path: str) -> str:
    """Canonicalize an artifact for RI-011 comparison: parse, strip volatile
    keys via the shared canonicalizer, re-serialize deterministically."""
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()
    if path.endswith(".jsonl"):
        rows = [json.loads(l) for l in text.splitlines() if l.strip()]
        canon = C.canonicalize_for_ri011(rows)
        return "\n".join(json.dumps(r, ensure_ascii=False, sort_keys=True) for r in canon)
    obj = json.loads(text)
    canon = C.canonicalize_for_ri011(obj)
    return json.dumps(canon, ensure_ascii=False, sort_keys=True, indent=2)


def _run_pytest() -> dict:
    """Run the 20-test suite with -B (no bytecode). Returns result dict."""
    proc = subprocess.run(
        [sys.executable, "-B", "-m", "unittest",
         "certification.reconnaissance.tests.test_recon_integrity", "-v"],
        cwd=REPO_ROOT,
        capture_output=True, text=True, encoding="utf-8", errors="replace",
    )
    combined = (proc.stdout or "") + "\n" + (proc.stderr or "")
    # Parse unittest summary lines: "Ran 20 tests", "OK" / "FAILED (failures=N, errors=M)"
    ran = passed = failed = errors = None
    import re as _re
    m = _re.search(r"^Ran (\d+) tests?", combined, _re.MULTILINE)
    if m:
        ran = int(m.group(1))
    if _re.search(r"^OK$", combined, _re.MULTILINE):
        failed, errors = 0, 0
        passed = ran
    else:
        mf = _re.search(r"FAILED \(failures=(\d+)(?:, errors=(\d+))?\)", combined)
        if mf:
            failed = int(mf.group(1))
            errors = int(mf.group(2)) if mf.group(2) else 0
            passed = (ran or 0) - failed - errors
    return {
        "exit_code": proc.returncode,
        "ran": ran,
        "passed": passed,
        "failed": failed,
        "errors": errors,
        "output_tail": "\n".join(combined.splitlines()[-6:]),
    }


def main() -> int:
    started = _now_iso()
    print("CERTIFY_MOVE0: two-run determinism + pytest binding")
    print(f"  T0: {C.T0_COMMIT}")

    tmp = tempfile.mkdtemp(prefix="tia_certify_")
    run_a_dir = os.path.join(tmp, "run_a")
    run_b_dir = os.path.join(tmp, "run_b")
    try:
        # ---- Run A ----
        print("  [1/4] orchestrator run A...")
        code_a, tail_a = _run_orchestrator()
        if code_a != 0:
            print(f"  FAIL: orchestrator run A exited {code_a}\n{tail_a}")
            return _write_cert(started, None, None, None, "orchestrator_run_A_failed")
        snap_a = _snapshot_artifacts(run_a_dir)

        # ---- Run B ----
        print("  [2/4] orchestrator run B...")
        code_b, tail_b = _run_orchestrator()
        if code_b != 0:
            print(f"  FAIL: orchestrator run B exited {code_b}\n{tail_b}")
            return _write_cert(started, snap_a, None, None, "orchestrator_run_B_failed")
        snap_b = _snapshot_artifacts(run_b_dir)

        # ---- Canonical comparison ----
        print("  [3/4] canonical comparison (volatile metadata excluded)...")
        per_file = {}
        all_identical = True
        for name in ARTIFACTS:
            ca = _canonical_form(os.path.join(run_a_dir, name))
            cb = _canonical_form(os.path.join(run_b_dir, name))
            identical = _sha256_text(ca) == _sha256_text(cb)
            per_file[name] = {
                "run_a_sha256": snap_a[name],
                "run_b_sha256": snap_b[name],
                "canonical_identical": identical,
            }
            if not identical:
                all_identical = False
        print(f"        canonical identical: {all_identical}")

        # ---- Pytest ----
        print("  [4/4] pytest 20-test suite...")
        pytest_res = _run_pytest()
        print(f"        ran={pytest_res['ran']} passed={pytest_res['passed']} "
              f"failed={pytest_res['failed']} errors={pytest_res['errors']}")
        test_suite_path = os.path.join(
            HERE, "tests", "test_recon_integrity.py")
        with open(test_suite_path, "rb") as f:
            suite_sha = hashlib.sha256(f.read()).hexdigest()

        certified = (
            all_identical
            and pytest_res["passed"] == 20
            and (pytest_res["failed"] or 0) == 0
            and (pytest_res["errors"] or 0) == 0
        )
        return _write_cert(
            started, snap_a, snap_b,
            {
                "per_file": per_file,
                "all_canonical_identical": all_identical,
                "pytest": pytest_res,
                "test_suite_path": "certification/reconnaissance/tests/test_recon_integrity.py",
                "test_suite_sha256": suite_sha,
            },
            None if certified else "determinism_or_pytest_failed",
            certified=certified,
        )
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def _write_cert(started, snap_a, snap_b, evidence, reason, certified=False):
    finished = _now_iso()
    doc = {
        "schema_version": "1.0.0",
        "produced_by": {"procedure": "CERTIFY_MOVE0.py", "contract_version": C.CONTRACT_VERSION},
        "produced_at_t0": C.T0_COMMIT,
        "certification_kind": "MOVE0_RI_BINDING",
        "started_at": started,
        "finished_at": finished,
        "t0_commit": C.T0_COMMIT,
        "t0_tree": C.T0_TREE,
        "verdict": "CERTIFIED" if certified else "NOT_CERTIFIED",
        "verdict_reason": reason,
        "run_a_artifact_shas": snap_a,
        "run_b_artifact_shas": snap_b,
        "evidence": evidence,
        "binding": (
            "This artifact binds: T0 identity + two-run canonical determinism "
            "result + pytest result + test-suite hash. It is written AFTER "
            "pytest executes, so unlike the orchestrator's T0_INTEGRITY.json "
            "(ri_status NOT_RUN by construction), this document reports the "
            "observed pytest outcome."
        ),
    }
    out_path = os.path.join(HERE, "T0_RI_CERTIFICATION.json")
    tmp = out_path + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="\n") as f:
        json.dump(doc, f, ensure_ascii=False, indent=2)
        f.write("\n")
    os.replace(tmp, out_path)
    print(f"  wrote {out_path}: verdict={doc['verdict']}")
    return 0 if certified else 1


if __name__ == "__main__":
    sys.exit(main())
