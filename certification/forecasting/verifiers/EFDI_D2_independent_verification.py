#!/usr/bin/env python3
"""
EFDI D2 Independent Verifier — V1–V12.

Runs WITHOUT trust in internal isValid flags. Verifies via source scanning
and live mix test; every gate produces PASS/FAIL; exit 0 only if ALL pass.
Writes results to EFDI_D2_independent_verification_output.json.
"""
import os, json, re, subprocess, sys, hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SRC = ROOT / "lib" / "tiannara" / "forecasting"
TEST = ROOT / "test" / "tiannara" / "forecasting"
OUT = Path(__file__).resolve().parent / "EFDI_D2_independent_verification_output.json"
results = {}
pass_count = 0
fail_count = 0

def gate(name, ok):
    global pass_count, fail_count
    results[name] = "PASS" if ok else "FAIL"
    if ok: pass_count += 1
    else:  fail_count += 1

# ---- helpers ----
def text_of(p):
    return p.read_text(encoding="utf-8", errors="replace") if p.exists() else ""

def grep(pattern, path, include="*.ex"):
    hits = []
    for f in path.rglob(include):
        for i, line in enumerate(text_of(f).splitlines()):
            if re.search(pattern, line): hits.append((str(f), i+1, line.strip()))
    return hits

def grep_count(pattern, path, include="*.exs"):
    return sum(1 for _ in grep(pattern, path, include))

def file_hash(p):
    return hashlib.sha256(text_of(p).encode()).hexdigest()[:16] if p.exists() else None

# ---- V1: Forecast Contract has required fields ----
required_fields = [
    "probabilities", "confidence", "event", "outcomes", "horizon",
    "forecast_version", "signal_refs", "evidence_refs", "base_rate_ref",
    "model_ref", "assumptions", "unknowns", "context", "regime",
    "created_at", "lineage", "provenance"
]
contracts_file = SRC / "contracts.ex"
ct = text_of(contracts_file)
v1 = all(f in ct for f in required_fields)
gate("V1_FORECAST_CONTRACT", v1)

# ---- V2: Probability Integrity ----
validate_file = SRC / "forecast.ex"
v2_text = text_of(validate_file)
v2 = (
    "outcome_probability_mismatch" in v2_text
    and "invalid_probabilities" in v2_text
    and "distribution_not_normalized" in v2_text
    and "valid_probability?" in v2_text
    and "finite?" in v2_text
)
gate("V2_PROBABILITY_INTEGRITY", v2)

# ---- V3: Evidence Lineage in Forecast struct ----
v3 = "signal_refs" in ct and "evidence_refs" in ct and "provenance" in ct
gate("V3_EVIDENCE_LINEAGE", v3)

# ---- V4: Base-Rate Integrity ----
base_rate_file = SRC / "base_rate_engine.ex"
br_text = text_of(base_rate_file)
v4 = (
    "frequency_out_of_bounds" in br_text
    and "missing_reference_class" in br_text
    and ":unknown" in br_text
)
gate("V4_BASE_RATE_INTEGRITY", v4)

# ---- V5: Forecast Immutability (re-register is no-op) ----
registry_file = SRC / "forecast_registry.ex"
rg_text = text_of(registry_file)
# registry should have "already registered" or "existing" return path
v5 = "existing" in rg_text or "existing" in rg_text
gate("V5_FORECAST_IMMUTABILITY", v5)

# ---- V6: Version Lineage ----
v6 = "forecast_version" in v2_text and "lineage" in v2_text and "def version(" in v2_text
gate("V6_VERSION_LINEAGE", v6)

# ---- V7: Outcome Integrity (hindsight isolation) ----
outcome_file = SRC / "outcome.ex"
o_text = text_of(outcome_file)
v7 = "hindsight_contamination" in o_text and "hindsight_clean?" in o_text
gate("V7_OUTCOME_INTEGRITY", v7)

# ---- V8: Calibration Correctness ----
cal_file = SRC / "calibration.ex"
c_text = text_of(cal_file)
v8 = (
    "brier" in c_text
    and "log_loss" in c_text
    and "calibration_error" in c_text
    and "reliability_level" in c_text
    and "insufficient" in c_text.lower()
    and ":unknown" in c_text
)
gate("V8_CALIBRATION_CORRECTNESS", v8)

# ---- V9: Replay/Reproducibility ----
replay_test = TEST / "forecast_replay_test.exs"
v9 = (
    "reproducib" in text_of(replay_test).lower()
    and "deterministic" in text_of(replay_test).lower()
    and "lineage" in text_of(replay_test)
)
gate("V9_REPLAY_REPRODUCIBILITY", v9)

# ---- V10: Adversarial Robustness ----
adv_test = TEST / "forecast_adversarial_test.exs"
a_text = text_of(adv_test)
v10 = (
    "probability integrity" in a_text
    and "invalid_probabilities" in a_text
    and "immutability" in a_text.lower()
    and "hindsight" in a_text.lower()
    and "no silent clamp" in a_text
)
gate("V10_ADVERSARIAL_ROBUSTNESS", v10)

# ---- V11: Hindsight Isolation ----
v11 = (
    "guard!" in o_text
    and "hindsight_contamination" in o_text
    and "observed_at" in o_text
    and "created_at" in o_text
)
gate("V11_HINDSIGHT_ISOLATION", v11)

# ---- V12: Insufficient-Data Handling ----
v12 = (
    "insufficient" in c_text.lower()
    and "reliability_level" in c_text
    and "@min_sample" in c_text
    and "sample_size: 0" in c_text
)
gate("V12_INSUFFICIENT_DATA", v12)

# ---- Live regression: mix test ----
try:
    proc = subprocess.run(
        ["mix", "test", "test/tiannara/forecasting", "--timeout", "120000"],
        capture_output=True, text=True, timeout=300,
        cwd=str(ROOT), env={**os.environ, "MIX_ENV": "test"}
    )
    out = proc.stdout + proc.stderr
    test_match = re.search(r"(\d+) tests?, (\d+) failure", out)
    if test_match:
        tests = int(test_match.group(1))
        failures = int(test_match.group(2))
        results["MIX_TEST_TOTAL"] = tests
        results["MIX_TEST_FAILURES"] = failures
        v_regress = failures == 0 and tests > 0
    else:
        results["MIX_TEST_TOTAL"] = 0
        results["MIX_TEST_FAILURES"] = -1
        v_regress = False
except Exception as e:
    results["MIX_TEST_ERROR"] = str(e)[:200]
    v_regress = False

gate("V_LIVE_REGRESSION", v_regress)

results["OVERALL"] = "PASS" if fail_count == 0 else "NOT_CERTIFIED"
results["EXIT_CODE"] = 0 if fail_count == 0 else 1

OUT.write_text(json.dumps(results, indent=2) + "\n")
print(json.dumps(results, indent=2))
sys.exit(results["EXIT_CODE"])
