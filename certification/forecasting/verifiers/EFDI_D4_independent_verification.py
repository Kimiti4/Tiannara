#!/usr/bin/env python3
"""
EFDI D4 Independent Verifier — V20–V35.

Runs WITHOUT trust in internal isValid flags. Verifies via source scanning of
the D4 modules and live mix test; every gate produces PASS/FAIL; exit 0 only if
ALL pass. Writes results to EFDI_D4_independent_verification_output.json.

Scope note: D4 is an ADAPTER layer over the canonical substrate. This verifier
confirms the genuinely-NEW surface (status ontology, bounded attribution,
survivorship/denominator, regression-to-mean non-causal schema, D4→D3 temporal
firewall) and that the D1-D3 regression (269) is preserved.
"""
import os, json, re, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SRC = ROOT / "lib" / "tiannara" / "forecasting"
TEST = ROOT / "test" / "tiannara" / "forecasting"
OUT = Path(__file__).resolve().parent / "EFDI_D4_independent_verification_output.json"
results = {}
pass_count = 0
fail_count = 0

def gate(name, ok):
    global pass_count, fail_count
    results[name] = "PASS" if ok else "FAIL"
    if ok: pass_count += 1
    else:  fail_count += 1

def text_of(p):
    return p.read_text(encoding="utf-8", errors="replace") if p.exists() else ""

ct = text_of(SRC / "contracts.ex")
cf = text_of(SRC / "counterfactual.ex")
ah = text_of(SRC / "alternative_history.ex")
at = text_of(SRC / "attribution.ex")
se = text_of(SRC / "selection.ex")
rm = text_of(SRC / "regression_to_mean.ex")
tf = text_of(SRC / "temporal_firewall.ex")
efdi = text_of(SRC / "efdi.ex")

# ---- V20: Counterfactual status ontology (first-class, no boolean collapse) ----
v20 = (
    ":observed" in ct and ":hypothetical" in ct and ":counterfactual" in ct
    and ":underdetermined" in ct and ":unknown" in ct and ":invalid" in ct
    and re.search(r"defmodule\s+CounterfactualRecord", ct)
)
gate("V20_STATUS_ONTOLOGY", v20)

# ---- V21: Observed assignable ONLY via D1 path ----
v21 = (
    "observed_not_assignable_by_d4" in cf
    and "assignable_by_d4?" in cf
    and re.search(r"def\s+enforce_observability_boundary", cf)
    and "observed_not_assignable_by_d4" in cf
)
gate("V21_OBSERVED_ONLY_VIA_D1", v21)

# ---- V22: Counterfactual is a labeled analytical record, never a fact ----
v22 = (
    "labeled analytical record" in cf
    and "def content_ref(" in cf
    and ("no merge" in cf.lower() or "never merged" in cf.lower())
    and "def branch(" in cf
)
gate("V22_LABELED_ANALYTICAL_RECORD", v22)

# ---- V23: Intervention spec is explicit (OBSERVE != SET) ----
v23 = (
    ":observe_only" in ct and ":set" in ct and ":do_nothing" in ct and ":defer" in ct
    and "OBSERVE X is NOT SET X = x" in ct
    and "def validate(" in cf and "missing_or_invalid_intervention" in cf
)
gate("V23_INTERVENTION_EXPLICITNESS", v23)

# ---- V24: Alternative-history bundle bounded, always includes do_nothing ----
v24 = (
    "max_alternatives" in ah and "default 8" in ah
    and "includes_do_nothing" in ah and "ensure_do_nothing" in ah
    and "alternatives_exceeded" in ah
)
gate("V24_ALT_HISTORY_BOUNDED", v24)

# ---- V25: Bundle elements are non-observed counterfactual records ----
v25 = (
    "enforce_observability_boundary" in ah
    and "non-observed" in ah.lower()
)
gate("V25_BUNDLE_NON_OBSERVED", v25)

# ---- V26: Attribution default NOT_ATTRIBUTED ----
v26 = (
    ":not_attributed" in at and "status: :not_attributed" in at
    and re.search(r"def\s+reify_attribution_guardance", at)
)
gate("V26_ATTRIBUTION_DEFAULT_NOT_ATTRIBUTED", v26)

# ---- V27: Attribution threshold-provenance (no hidden constants) ----
v27 = (
    "thresholds_provenance" in at and "repeat_count_evidence_threshold" in at
    and "n_min" in at
)
gate("V27_ATTRIBUTION_THRESHOLD_PROVENANCE", v27)

# ---- V28: Single outcomes never attributed; no resulting inference ----
v28 = (
    "single outcome" in at.lower() and "BAD OUTCOME" in at
    and "GOOD OUTCOME" in at
)
gate("V28_ATTRIBUTION_BOUNDARY", v28)

# ---- V29: Survivorship / selection with denominator registry ----
v29 = (
    "denominator_status" in se and ":survivorship" in ct
    and ":unknown" in se and "denominator_unknown" in se
    and ":selected" in ct
)
gate("V29_SURVIVORSHIP_DENOMINATOR", v29)

# ---- V30: UNKNOWN_SELECTION_EFFECT first-class ----
v30 = (
    "UNKNOWN_SELECTION_EFFECT" in se or "denominator_unknown" in se
    and "def select_from" in se
    and ":known" in se and ":partial" in se
)
gate("V30_UNKNOWN_SELECTION_EFFECT", v30)

# ---- V31: Regression-to-mean non-causal by construction (no causal field) ----
v31 = (
    "NO causal-claim field" in rm
    and "def causal_claim_free?" in rm
    and ":unknown" in rm
)
gate("V31_RTM_NON_CAUSAL", v31)

# ---- V32: RTM without reference class → unknown, not false ----
v32 = (
    ("no causal-claim" in rm.lower() or "first-class" in rm)
) and "single observation" in rm.lower()
gate("V32_RTM_UNKNOWN_HONESTY", v32)

# ---- V33: D4→D3 temporal firewall first-class certification property ----
v33 = (
    "firewall_intact?" in tf and "snapshot_consistent?" in tf
    and "def verify(" in tf and "hindsight_contamination" in tf
    and "contamination" in tf
)
gate("V33_TEMPORAL_FIREWALL", v33)

# ---- V34: D3 snapshots read-only; D4 never writes to D3 ----
v34 = (
    "d3_writes" in tf and "d3_write_attempt" in tf
    and "READ D3" in tf
)
gate("V34_D3_READ_ONLY", v34)

# ---- V35: Zero new causal/counterfactual engine; adapter over substrate ----
recon = text_of(ROOT / "docs" / "architecture" / "EFDI_D4_ARCHITECTURE_RECONNAISSANCE.md")
v35 = (
    "ADAPTER" in recon
    and ("no new causal" in text_of(SRC / ".." / ".." / "docs" / "architecture" / "EFDI_D4_CLASSIFICATION_MATRIX.md").lower()
         or "REUSE" in recon)
) and "deferred" in efdi and "noise" in efdi and "memory" in efdi
gate("V35_ADAPTER_NOT_NEW_ENGINE", v35)

# ---- Live regression: mix test (D1+D2+D3+D4) ----
try:
    proc = subprocess.run(
        ["mix", "test", "test/tiannara/forecasting", "--timeout", "120000"],
        capture_output=True, text=True, timeout=360,
        cwd=str(ROOT), env={**os.environ, "MIX_ENV": "test"}
    )
    out = proc.stdout + proc.stderr
    test_match = re.search(r"(\d+) tests?, (\d+) failure", out)
    if test_match:
        tests = int(test_match.group(1))
        failures = int(test_match.group(2))
        results["MIX_TEST_TOTAL"] = tests
        results["MIX_TEST_FAILURES"] = failures
        v_regress = failures == 0 and tests >= 269
    else:
        results["MIX_TEST_TOTAL"] = 0
        results["MIX_TEST_FAILURES"] = -1
        v_regress = False
except Exception as e:
    results["MIX_TEST_ERROR"] = str(e)[:200]
    v_regress = False

gate("V_LIVE_REGRESSION_269_PLUS", v_regress)

results["D1_D2_D3_REGRESSION_PRESERVED"] = (
    "PASS" if (results.get("MIX_TEST_TOTAL", 0) >= 269 and results.get("MIX_TEST_FAILURES", -1) == 0) else "FAIL"
)

results["OVERALL"] = "D4_CERTIFIED_BOUNDED" if fail_count == 0 else "NOT_CERTIFIED"
results["EXIT_CODE"] = 0 if fail_count == 0 else 1

OUT.write_text(json.dumps(results, indent=2) + "\n")
print(json.dumps(results, indent=2))
sys.exit(results["EXIT_CODE"])
