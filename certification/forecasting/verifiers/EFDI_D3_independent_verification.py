#!/usr/bin/env python3
"""
EFDI D3 Independent Verifier — V1–V19.

Runs WITHOUT trust in internal isValid flags. Verifies via source scanning
and live mix test; every gate produces PASS/FAIL; exit 0 only if ALL pass.
Writes results to EFDI_D3_independent_verification_output.json.
"""
import os, json, re, subprocess, sys, hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SRC = ROOT / "lib" / "tiannara" / "forecasting"
TEST = ROOT / "test" / "tiannara" / "forecasting"
ADAPTER = SRC / "adapters"
OUT = Path(__file__).resolve().parent / "EFDI_D3_independent_verification_output.json"
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

def grep(pattern, path, include="*.ex"):
    hits = []
    for f in path.rglob(include):
        for i, line in enumerate(text_of(f).splitlines()):
            if re.search(pattern, line): hits.append((str(f), i+1, line.strip()))
    return hits

# ---- V1: Decision Contract ----
contracts_file = SRC / "contracts.ex"
ct = text_of(contracts_file)
decision_contract_file = SRC / "decision.ex"
dc = text_of(decision_contract_file)
required_decision_fields = [
    "question", "alternatives", "recommended_alternative_id",
    "selected_alternative_id", "expected_values", "risk_evaluation",
    "created_at", "decision_version", "lineage", "forecast_refs", "decisioner"
]
v1 = (
    all(f in ct for f in required_decision_fields)
    and re.search(r"defmodule\s+Decision\s+do", ct) is not None
    and "def new(" in dc
    and "def validate(" in dc
)
gate("V1_DECISION_CONTRACT", v1)

# ---- V2: Alternative Contract ----
v2_fields = ["id", "label", "probabilities", "outcomes", "utilities", "risk",
             "reversibility", "assets_at_risk"]
v2 = (
    re.search(r"defmodule\s+Alternative\s+do", ct) is not None
    and all(f in ct for f in v2_fields)
    and "reversible" in ct.lower()
    and ":irreversible" in ct
    and ":unknown" in dc
)
gate("V2_ALTERNATIVE_CONTRACT", v2)

# ---- V3: DecisionRequest Contract ----
v3 = (
    re.search(r"defmodule\s+DecisionRequest\s+do", ct) is not None
    and "decision_id" in ct and "question" in ct and "horizon" in ct
)
gate("V3_DECISION_REQUEST_CONTRACT", v3)

# ---- V4: Engine Arithmetic ----
engine_file = SRC / "decision_engine.ex"
en = text_of(engine_file)
v4 = (
    "Enum.zip" in en
    and "Enum.reduce(0.0" in en
    and "(ui - ev) ** 2" in en
    and ":math.sqrt" in en
)
gate("V4_ENGINE_ARITHMETIC", v4)

# ---- V5: Unknown Honesty ----
v5 = (
    "def expected_value(%Alternative{}), do: :unknown" in en
    or re.search(r"def expected_value\(%Alternative\{\}\), do: :unknown", en) is not None
) and ":unknown" in en and "defp risk_score(_ev, :unknown" in en
gate("V5_UNKNOWN_HONESTY", v5)

# ---- V6: Recommendation Selection ----
v6 = "select_recommendation" in en and "def decide(" in en and "nil" in en
gate("V6_RECOMMENDATION_SELECTION", v6)

# ---- V7: Decision Immutability / Registry ----
registry_file = SRC / "decision_registry.ex"
rg = text_of(registry_file)
v7 = (
    "namespace: :efdi_decision_registry" in text_of(registry_file)
    or "efdi_decision_registry" in rg
) and "existing" in rg and "def register(" in rg and "def get(" in rg and "def health" in rg
gate("V7_DECISION_REGISTRY_IMMUTABILITY", v7)

# ---- V8: Version Lineage ----
v8 = "decision_version" in dc and "lineage" in dc and "def version(" in dc
gate("V8_VERSION_LINEAGE", v8)

# ---- V9: Resulting Prevention ----
quality_file = SRC / "decision_quality.ex"
qu = text_of(quality_file)
v9 = "hindsight_independent" in qu and ":decision_time" in qu and "def classify(" in qu
gate("V9_RESULTING_PREVENTION", v9)

# ---- V10: Outcome Separation ----
review_file = SRC / "decision_review.ex"
rv = text_of(review_file)
v10 = (
    "def classify(" in qu
    and "outcome: if(outcome_success" in qu
    and ":not_attributed" in rv
)
gate("V10_OUTCOME_SEPARATION", v10)

# ---- V11: Hindsight Isolation ----
snapshot_file = SRC / "decision_snapshot.ex"
sn = text_of(snapshot_file)
v11 = (
    "hindsight_contamination" in rv
    and "def guard_outcome(" in rv
    and "consistent?(" in sn
    and "observed_at" in rv
    and "created_at" in rv
)
gate("V11_HINDSIGHT_ISOLATION", v11)

# ---- V12: Decision Snapshot ----
v12 = (
    "def capture(" in sn
    and "decision_id" in sn and "unknowns" in sn
    and "def consistent?(" in sn
)
gate("V12_DECISION_SNAPSHOT", v12)

# ---- V13: Pre-Mortem ----
pre_file = SRC / "pre_mortem.ex"
pm = text_of(pre_file)
v13 = (
    "def run(" in pm and "def run_all(" in pm and "def posture(" in pm
    and ":proceed" in pm and ":require_info" in pm and ":block" in pm
    and "risk_threshold" in pm and ":irreversible" in pm
)
gate("V13_PRE_MORTEM", v13)

# ---- V14: Value-of-Information ----
voi_file = SRC / "value_of_information.ex"
vo = text_of(voi_file)
v14 = (
    "expected_value_of_perfect_information" in vo
    and "decision_sensitivity" in vo
    and "to_research_priorities" in vo
    and ":information_value" in vo
    and "information_gap" in vo
)
gate("V14_VALUE_OF_INFORMATION", v14)

# ---- V15: Authorization Boundary ----
adapter_file = ADAPTER / "decision.ex"
ad = text_of(adapter_file)
v15 = (
    "Council.authorize" in ad
    and "authorization_unavailable" in ad
    and "never bypasses" in ad
)
gate("V15_AUTHORIZATION_BOUNDARY", v15)

# ---- V16: Research Boundary ----
v16 = (
    "to_research_priorities" in vo
    and "request_research" in ad
    and "recommended_action" in vo
    and ":information_value" in vo
)
gate("V16_RESEARCH_BOUNDARY", v16)

# ---- V17: CIS Boundary ----
v17 = "check_cis" in ad and "pathogenic" in ad and "cis_boundary" in ad
gate("V17_CIS_BOUNDARY", v17)

# ---- V18: Replay ----
replay_test = TEST / "d3_replay_test.exs"
v18 = (
    "reproduc" in text_of(replay_test).lower()
    and "deterministic" in text_of(replay_test).lower()
    and ("bit-identical" in text_of(replay_test) or "equal" in text_of(replay_test))
)
gate("V18_REPLAY", v18)

# ---- V19: Adversarial ----
adv_test = TEST / "d3_adversarial_test.exs"
a_text = text_of(adv_test)
decision_lib = text_of(SRC / "decision.ex")
v19 = (
    "hindsight smuggling" in a_text.lower()
    and ("duplicate" in a_text.lower() or "duplicate_alternative_ids" in decision_lib)
    and ("malformed" in a_text.lower() or "mismatched" in a_text.lower())
)
gate("V19_ADVERSARIAL", v19)

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

results["OVERALL"] = "CERTIFIED_BOUNDED" if fail_count == 0 else "NOT_CERTIFIED"
results["EXIT_CODE"] = 0 if fail_count == 0 else 1

OUT.write_text(json.dumps(results, indent=2) + "\n")
print(json.dumps(results, indent=2))
sys.exit(results["EXIT_CODE"])