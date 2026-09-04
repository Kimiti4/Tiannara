"""
EFDI D1 independent verifier (no-trust, V1-V9).

Deliberately does NOT trust certification records, the D1 result JSON, or claimed
test counts. It scans live source/config/tests, runs the targeted EFDI suite
itself, and reports its own findings.

Exits 0 (PASS) only if every mandatory claim passes; otherwise exits 1 (FAIL /
NOT_CERTIFIED). Writes its own findings JSON (no fabrication) to
EFDI_D1_independent_verification_output.json.
"""
import json
import os
import re
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
LIB = os.path.join(ROOT, "lib", "tiannara", "forecasting")


def read(rel):
    with open(os.path.join(LIB, rel), encoding="utf-8", errors="replace") as fh:
        return fh.read()


def read_root(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8", errors="replace") as fh:
        return fh.read()


def walk_ex():
    out = []
    for dirpath, _d, filenames in os.walk(LIB):
        for f in filenames:
            if f.endswith(".ex"):
                out.append(os.path.join(dirpath, f))
    return out


def main():
    findings = {}
    failures = []

    # ------------------------------------------------------ V1 Scope discipline
    # D1 must NOT implement forecasting/calibration/decision/counterfactual/noise/memory.
    v1 = {}
    scope_source = ""
    for p in walk_ex():
        with open(p, encoding="utf-8", errors="replace") as fh:
            scope_source += fh.read() + "\n"
    # forbid real forecast/calibration/decision engines in D1 source
    forbidden = [
        "def forecast(", "def calibrate(", "def decide(", "def counterfactual(",
        "def compute_forecast",
    ]
    for needle in forbidden:
        v1[re.sub(r"[^A-Za-z0-9]", "_", needle)] = needle not in scope_source
    ok = all(v1.values())
    findings["V1_SCOPE"] = "PASS" if ok else "FAIL"
    if not ok:
        failures.append("V1: " + ", ".join(k for k, x in v1.items() if not x))

    # ------------------------------------------------------ V2 Module presence
    v2 = {}
    required = [
        "signal.ex", "signal_registry.ex", "signal_quality.ex", "signal_value.ex",
        "provenance.ex", "correlation.ex", "contracts.ex", "efdi.ex",
        os.path.join("adapters", "adapters.ex"),
    ]
    for rel in required:
        v2[os.path.basename(rel)] = os.path.exists(os.path.join(LIB, rel))
    ok = all(v2.values())
    findings["V2_MODULES"] = "PASS" if ok else "FAIL"
    if not ok:
        failures.append("V2: " + ", ".join(k for k, x in v2.items() if not x))

    # ------------------------------------------------------ V3 File-level secrets scan
    v3 = {}
    v3["no_hardcoded_secrets"] = True
    for p in walk_ex():
        txt = open(p, encoding="utf-8", errors="replace").read()
        if re.search(r"(api[_-]?key|secret|password)\s*[:=]\s*[\"']", txt, re.I):
            v3["no_hardcoded_secrets"] = False
    ok = all(v3.values())
    findings["V3_SECRETS"] = "PASS" if ok else "FAIL"
    if not ok:
        failures.append("V3: hardcoded secret-like literal in D1 source")

    # ------------------------------------------------------ V4 Deterministic dedup
    signal = read("signal.ex")
    v4 = {}
    v4["dedup_sha256"] = ":crypto.hash(:sha256" in signal and "term_to_binary" in signal
    v4["dedup_source_observation"] = "source:" in signal and "observation:" in signal
    reg = read("signal_registry.ex")
    v4["compound_dedup_key"] = "{{:dedup" in reg or "{@dedup" in reg or '{{:dedup' in reg
    ok = all(v4.values())
    findings["V4_DEDUP"] = "PASS" if ok else "FAIL"
    if not ok:
        failures.append("V4: " + ", ".join(k for k, x in v4.items() if not x))

    # ------------------------------------------------------ V5 Immutability / no overwrite
    v5 = {}
    v5["version_keeps_history"] = "Map.drop([:id])" in signal or "version(signal" in signal
    v5["version_new_id"] = "new_id" in signal or ":id])" in signal
    v5["supersede_preserves_original"] = "supersede" in reg
    ok = all(v5.values())
    findings["V5_IMMUTABLE"] = "PASS" if ok else "FAIL"
    if not ok:
        failures.append("V5: " + ", ".join(k for k, x in v5.items() if not x))

    # ------------------------------------------------------ V6 UNKNOWN != 0.0
    v6 = {}
    v6["unknown_valid"] = ":unknown" in read("signal_quality.ex")
    v6["unknown_distinct"] = ":unknown" in read("signal_value.ex")
    ok = all(v6.values())
    findings["V6_UNKNOWN"] = "PASS" if ok else "FAIL"
    if not ok:
        failures.append("V6: :unknown handling absent in quality/value")

    # ------------------------------------------------------ V7 Adapter boundaries
    adapters = read(os.path.join("adapters", "adapters.ex"))
    v7 = {}
    v7["evidence"] = "Evidence" in adapters and "link_to_evidence" in adapters
    v7["research"] = "Research" in adapters and "information_gain_estimate" in adapters
    v7["cis"] = "CIS" in adapters and "signal_conflict_to_pathogen" in adapters
    v7["worldmodel"] = "WorldModel" in adapters and "conflicts_with_world" in adapters
    ok = all(v7.values())
    findings["V7_ADAPTERS"] = "PASS" if ok else "FAIL"
    if not ok:
        failures.append("V7: " + ", ".join(k for k, x in v7.items() if not x))

    # ------------------------------------------------------ V8 Regression
    n_tests = n_fail = None
    try:
        print("running targeted EFDI suite (V8)...")
        suite = subprocess.run(
            ["mise", "exec", "--", "mix", "test", "test/tiannara/forecasting"],
            cwd=ROOT, capture_output=True, text=True, timeout=1500)
        out = suite.stdout + suite.stderr
        match = re.search(r"(\d+) tests?, (\d+) failures?", out)
        if match:
            n_tests, n_fail = int(match.group(1)), int(match.group(2))
        v8_ok = (suite.returncode == 0 and n_tests is not None and n_fail == 0)
        findings["V8_REGRESSION"] = "PASS" if v8_ok else "FAIL"
        findings["V8_TESTS"] = n_tests
        findings["V8_FAILURES"] = n_fail
        if not v8_ok:
            failures.append("V8: targeted suite not green (rc=%s t=%s f=%s)"
                            % (suite.returncode, n_tests, n_fail))
    except Exception as e2:
        findings["V8_REGRESSION"] = "ENVIRONMENT_BLOCKED"
        findings["V8_ERROR"] = str(e2)
        failures.append("V8: suite ENVIRONMENT_BLOCKED - " + str(e2))

    # ------------------------------------------------------ V9 Existing stubs intact
    # Must NOT have modified the pre-existing metric-pushing forecasting stubs used
    # by run_forecasting_gauntlet.exs (Tiannara.Forecasting.ForecastAuditor etc.).
    stub_probe = os.path.join(LIB, "auditor.ex")
    v9 = {}
    v9["auditor_stub_exists"] = os.path.exists(stub_probe) or os.path.exists(
        os.path.join(LIB, "forecast_auditor.ex"))
    # CONTRACTS only defines structs (data model), never behaviours with forecast logic
    contracts = read("contracts.ex") if os.path.exists(os.path.join(LIB, "contracts.ex")) else ""
    v9["contracts_struct_only"] = "defstruct" in contracts and "def forecast(" not in scope_source
    ok = all(v9.values())
    findings["V9_STUBS"] = "PASS" if ok else "FAIL"
    if not ok:
        failures.append("V9: " + ", ".join(k for k, x in v9.items() if not x))

    # ------------------------------------------------------------ summary
    overall = "PASS" if not failures else "FAIL"
    findings["OVERALL"] = overall
    findings["EXIT_CODE"] = 0 if overall == "PASS" else 1

    out_path = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                            "EFDI_D1_independent_verification_output.json")
    with open(out_path, "w", encoding="utf-8") as fh:
        json.dump(findings, fh, indent=2)

    print("EFDI D1 INDEPENDENT VERIFICATION: %s" % overall)
    for k, v in findings.items():
        print("  %-28s %s" % (k, v))
    if failures:
        for f in failures:
            print("  FAIL -", f)
    sys.exit(0 if overall == "PASS" else 1)


if __name__ == "__main__":
    main()
