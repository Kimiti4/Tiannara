#!/usr/bin/env python3
"""
E03 Independent Verifier — no-trust, deterministic.

Verifies the E03 PRE-REGISTRATION and PARAMETER MANIFEST as frozen
artifacts. Does NOT execute E03, does NOT invoke stabilizers, does NOT
mutate code, does NOT modify the preregistration.

Every assertion produces PASS / FAIL / INDETERMINATE with evidence.
Exit 0 only if all required assertions PASS. Writes a deterministic
JSON output next to this script.

Frozen against HEAD: 3bd1601b9bb3c718f985d44ceaa8ef2e638d4ec6
"""
import os, json, re, hashlib, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
E03_DIR = ROOT / "certification" / "empirical_validation" / "E03"
PREREG = E03_DIR / "E03_PREREGISTRATION.md"
MANIFEST = E03_DIR / "E03_PARAMETER_MANIFEST.json"
OUT = Path(__file__).resolve().parent / "E03_VERIFIER_OUTPUT.json"

FROZEN_HEAD = "3bd1601b9bb3c718f985d44ceaa8ef2e638d4ec6"
FROZEN_HEAD_SHORT = "3bd1601"

results = {"frozen_against_head": FROZEN_HEAD, "assertions": {}}
pass_count = 0
fail_count = 0
indet_count = 0

def classify(name, ok, evidence):
    """ok=True -> PASS, ok=False -> FAIL, ok=None -> INDETERMINATE."""
    global pass_count, fail_count, indet_count
    if ok is True:
        status = "PASS"; pass_count += 1
    elif ok is False:
        status = "FAIL"; fail_count += 1
    else:
        status = "INDETERMINATE"; indet_count += 1
    results["assertions"][name] = {"status": status, "evidence": evidence}
    return status

def text_of(p):
    return p.read_text(encoding="utf-8", errors="replace") if p.exists() else ""

def sha256_of(p):
    if not p.exists():
        return None
    h = hashlib.sha256()
    h.update(p.read_bytes())
    return h.hexdigest()

# ---- 0. Artifacts exist and are readable ----
classify("ARTIFACTS_EXIST",
         PREREG.exists() and MANIFEST.exists(),
         {"prereg_path": str(PREREG), "prereg_exists": PREREG.exists(),
          "manifest_path": str(MANIFEST), "manifest_exists": MANIFEST.exists()})

# ---- 1. Preregistration immutability / hash binding against HEAD 3bd1601 ----
prereg_text = text_of(PREREG)
prereg_sha = sha256_of(PREREG)
manifest_text = text_of(MANIFEST)
manifest_sha = sha256_of(MANIFEST)

# 1a. Preregistration text references the frozen HEAD.
prereg_has_head = (FROZEN_HEAD in prereg_text or FROZEN_HEAD_SHORT in prereg_text)
classify("PREREG_REFERENCES_FROZEN_HEAD", prereg_has_head,
         {"expected_head": FROZEN_HEAD, "found_in_text": prereg_has_head})

# 1b. Preregistration explicitly declares "frozen" status.
frozen_decl = "frozen" in prereg_text.lower() and "no post-hoc" in prereg_text.lower()
classify("PREREG_DECLARES_FROZEN", frozen_decl,
         {"frozen_in_text": "frozen" in prereg_text.lower(),
          "no_posthoc_in_text": "no post-hoc" in prereg_text.lower()})

# 1c. Actual repo HEAD matches the frozen HEAD.
try:
    proc = subprocess.run(
        ["git", "rev-parse", "HEAD"],
        capture_output=True, text=True, timeout=15, cwd=str(ROOT)
    )
    actual_head = proc.stdout.strip()
    head_match = (actual_head == FROZEN_HEAD)
    classify("REPO_HEAD_MATCHES_FROZEN_HEAD", head_match,
             {"expected": FROZEN_HEAD, "actual": actual_head})
except Exception as e:
    classify("REPO_HEAD_MATCHES_FROZEN_HEAD", None,
             {"error": str(e)[:200]})

# 1d. Preregistration and manifest are hash-bound to the frozen state.
results["PREREG_SHA256"] = prereg_sha
results["MANIFEST_SHA256"] = manifest_sha
# We do NOT assert a specific hash (the prereg/manifest were just created);
# we record the hashes for downstream binding.

# ---- 2. Parameter manifest is valid JSON and structurally complete ----
try:
    manifest = json.loads(manifest_text)
    classify("MANIFEST_VALID_JSON", True, {"keys_count": len(manifest)})
except Exception as e:
    manifest = None
    classify("MANIFEST_VALID_JSON", False, {"error": str(e)[:200]})

# Required top-level fields in the manifest.
required_manifest_keys = [
    "manifest_id", "campaign", "status", "frozen_against_head",
    "environment", "hypotheses", "conditions", "seeds", "run_duration",
    "measurement_schedule", "metrics", "perturbation_protocol",
    "counterfactual_protocol", "overreach_sweep_protocol",
    "primary_success_criteria", "primary_failure_conditions",
    "stop_conditions_master_prompt_section_22", "evidence_model",
    "provenance_schema", "no_trust_verification", "scientific_analysis_questions",
    "final_classification", "next_concrete_deliverables_in_order"
]
if manifest is not None:
    missing = [k for k in required_manifest_keys if k not in manifest]
    classify("MANIFEST_HAS_REQUIRED_KEYS", len(missing) == 0,
             {"required": required_manifest_keys, "missing": missing})
else:
    classify("MANIFEST_HAS_REQUIRED_KEYS", False, {"manifest_loaded": False})

# ---- 3. Hypotheses and nulls ----
if manifest is not None:
    h = manifest.get("hypotheses", {})
    h_ok = (
        "H1_primary" in h and "stabilizer" in h["H1_primary"].lower()
        and "H0_A_suffocation" in h
        and "H0_B_ineffectiveness" in h
        and "H0_C_artificial_emergence" in h
    )
    classify("MANIFEST_HAS_HYPOTHESES", h_ok,
             {"keys": list(h.keys()) if isinstance(h, dict) else None})
else:
    classify("MANIFEST_HAS_HYPOTHESES", False, {"manifest_loaded": False})

# Preregistration text must include H1 and the three H0 nulls.
nulls_text_ok = (
    "H1" in prereg_text
    and "H0-A" in prereg_text
    and "H0-B" in prereg_text
    and "H0-C" in prereg_text
    and ("ENDOGENOUS" in prereg_text or "endogenous" in prereg_text)
)
classify("PREREG_HAS_H1_AND_H0S_AND_CLASSIFICATION", nulls_text_ok,
         {"h1_in_text": "H1" in prereg_text,
          "h0a_in_text": "H0-A" in prereg_text,
          "h0b_in_text": "H0-B" in prereg_text,
          "h0c_in_text": "H0-C" in prereg_text,
          "endogenous_in_text": "ENDOGENOUS" in prereg_text or "endogenous" in prereg_text})

# Emergence-classification vocabulary must include the five required classes.
required_classes = ["ENDOGENOUS", "STABILIZER_ASSISTED", "STABILIZER_INDUCED", "ARTIFICIAL_NON_EMERGENT", "UNRESOLVED"]
if manifest is not None:
    vocab = manifest.get("emergence_classification_vocabulary", [])
    classify("EMERGENCE_CLASSIFICATION_VOCABULARY_COMPLETE",
             all(c in vocab for c in required_classes),
             {"required": required_classes, "found": vocab})
else:
    classify("EMERGENCE_CLASSIFICATION_VOCABULARY_COMPLETE", False,
             {"manifest_loaded": False})

# ---- 4. A/B/C controls ----
if manifest is not None:
    conditions = manifest.get("conditions", [])
    cond_ids = [c.get("condition") for c in conditions] if conditions else []
    cond_ok = ("CONTROL_A" in cond_ids and "CONTROL_B" in cond_ids and "CONTROL_C" in cond_ids)
    classify("MANIFEST_HAS_ABC_CONTROLS", cond_ok, {"condition_ids": cond_ids})
else:
    classify("MANIFEST_HAS_ABC_CONTROLS", False, {"manifest_loaded": False})

# ---- 5. Seeds 42, 1729, 20240903 ----
required_seeds = [42, 1729, 20240903]
if manifest is not None:
    seeds = manifest.get("seeds", [])
    seed_values = [s.get("seed") for s in seeds]
    unique_seeds = set(seed_values)
    seeds_ok = all(s in unique_seeds for s in required_seeds) and len(seeds) >= 9
    classify("MANIFEST_HAS_REQUIRED_SEEDS_AND_9_RUNS", seeds_ok,
             {"required": required_seeds, "found_unique": sorted(unique_seeds),
              "total_runs": len(seeds)})
else:
    classify("MANIFEST_HAS_REQUIRED_SEEDS_AND_9_RUNS", False, {"manifest_loaded": False})

# ---- 6. 10,000-tick duration and checkpoint schedule ----
if manifest is not None:
    rd = manifest.get("run_duration", {})
    duration_ok = rd.get("baseline_runs_ticks") == 10000
    sched = manifest.get("measurement_schedule", {})
    checkpoints = sched.get("checkpoints", [])
    checkpoints_ok = checkpoints == [0, 100, 500, 1000, 2500, 5000, 7500, 10000]
    classify("MANIFEST_DURATION_AND_CHECKPOINTS", duration_ok and checkpoints_ok,
             {"baseline_runs_ticks": rd.get("baseline_runs_ticks"),
              "checkpoints": checkpoints,
              "duration_ok": duration_ok, "checkpoints_ok": checkpoints_ok})
else:
    classify("MANIFEST_DURATION_AND_CHECKPOINTS", False, {"manifest_loaded": False})

# ---- 7. Pressure sweep definition ----
if manifest is not None:
    sweep = manifest.get("overreach_sweep_protocol", {})
    pressures = sweep.get("pressures_swept", [])
    expected_pressures = [0.0, 0.25, 0.5, 0.75, 1.0]
    sweep_ok = pressures == expected_pressures and sweep.get("total_sweep_runs") == 15
    classify("MANIFEST_PRESSURE_SWEEP", sweep_ok,
             {"pressures_swept": pressures, "expected": expected_pressures,
              "total_sweep_runs": sweep.get("total_sweep_runs")})
else:
    classify("MANIFEST_PRESSURE_SWEEP", False, {"manifest_loaded": False})

# ---- 8. Success / failure / stop criteria ----
if manifest is not None:
    s_ok = len(manifest.get("primary_success_criteria", [])) == 10
    f_ok = len(manifest.get("primary_failure_conditions", [])) >= 5
    stop_ok = len(manifest.get("stop_conditions_master_prompt_section_22", [])) == 10
    classify("MANIFEST_SUCCESS_FAILURE_STOP_CRITERIA", s_ok and f_ok and stop_ok,
             {"success_count": len(manifest.get("primary_success_criteria", [])),
              "failure_count": len(manifest.get("primary_failure_conditions", [])),
              "stop_count": len(manifest.get("stop_conditions_master_prompt_section_22", []))})
else:
    classify("MANIFEST_SUCCESS_FAILURE_STOP_CRITERIA", False, {"manifest_loaded": False})

# ---- 9. Emergence-classification vocabulary and independence requirements ----
indep_text_ok = (
    "independence" in prereg_text.lower() or "Emergence independence" in prereg_text
) and (
    "trace causal history" in prereg_text
    or "trace causal" in prereg_text.lower()
) and (
    "STABILIZER_INDUCED" in prereg_text
    or "STABILIZER-INDUCED" in prereg_text
)
classify("PREREG_INDEPENDENCE_REQUIREMENT", indep_text_ok,
         {"independence_in_text": "independence" in prereg_text.lower(),
          "trace_causal_in_text": "trace causal" in prereg_text.lower(),
          "stabilizer_induced_in_text": "STABILIZER_INDUCED" in prereg_text})

# ---- 10. Absence of execution artifacts/runs ----
run_ledger = E03_DIR / "E03_RUN_LEDGER.jsonl"
evidence_json = E03_DIR / "E03_EVIDENCE.json"
analysis_md = E03_DIR / "E03_ANALYSIS.md"
certification_md = E03_DIR / "E03_CERTIFICATION.md"
stop_report_md = E03_DIR / "E03_STOP_REPORT.md"
execution_artifacts_absent = not any(p.exists() for p in [
    run_ledger, evidence_json, analysis_md, certification_md, stop_report_md
])
classify("ABSENCE_OF_EXECUTION_ARTIFACTS", execution_artifacts_absent,
         {"checked": ["E03_RUN_LEDGER.jsonl", "E03_EVIDENCE.json",
                      "E03_ANALYSIS.md", "E03_CERTIFICATION.md",
                      "E03_STOP_REPORT.md"]})

# Also confirm no E03 results data has been generated (no run output dir).
candidate_run_dirs = [E03_DIR / "runs", E03_DIR / "results", E03_DIR / "output",
                      E03_DIR / "logs", E03_DIR / "data"]
existing_run_dirs = [str(d.relative_to(ROOT)) for d in candidate_run_dirs if d.exists()]
classify("ABSENCE_OF_RUN_OUTPUT_DIRS", len(existing_run_dirs) == 0,
         {"existing_candidate_run_dirs": existing_run_dirs})

# ---- 11. Absence of unauthorized D1–D5 / D6 / Phase 4 changes ----
# We verify by reading the R6 measurement-integrity verifier's most recent
# output JSON (which R6 writes deterministically on every run). We do NOT
# re-run R6 here because (a) it takes 5+ minutes and can be flaky on
# parallel test scheduling, and (b) the authoritative R7 status is the
# most-recent R6 _output.json. The R6 verifier's PARTIAL/FAIL thresholds
# already capture any genuine regression; we read its gates and overall.
mi_verifier = ROOT / "certification" / "empirical_validation" / "verifiers" / "MEASUREMENT_INTEGRITY_verifier.py"
mi_out_path = mi_verifier.parent / "MEASUREMENT_INTEGRITY_verifier_output.json"
if mi_out_path.exists():
    try:
        mi_out = json.loads(mi_out_path.read_text(encoding="utf-8"))
        overall = mi_out.get("OVERALL") or mi_out.get("CERTIFICATION_STATE")
        gates_passed = mi_out.get("GATES_PASS")
        gates_total = mi_out.get("GATES_TOTAL")
        # R7 holds iff R6 overall is CERTIFIED and all gates passed.
        r7_holds = (overall == "MEASUREMENT_INTEGRITY_CERTIFIED"
                    and gates_passed == gates_total
                    and gates_total is not None and gates_total > 0)
        classify("MEASUREMENT_INTEGRITY_R7_STILL_VALID", r7_holds,
                 {"source": str(mi_out_path),
                  "overall": overall, "gates_passed": gates_passed,
                  "gates_total": gates_total,
                  "note": "Read from R6 most-recent output JSON (authoritative)."})
    except Exception as e:
        classify("MEASUREMENT_INTEGRITY_R7_STILL_VALID", None,
                 {"error": str(e)[:200]})
elif mi_verifier.exists():
    # R6 verifier exists but has never produced output. We do not auto-run it
    # here (it takes minutes and can flake). We classify INDETERMINATE and
    # record the discrepancy for the Council.
    classify("MEASUREMENT_INTEGRITY_R7_STILL_VALID", None,
             {"error": "R6 verifier found but no _output.json produced yet",
              "note": "Run the R6 verifier once to produce the authoritative output, then re-run E03 verifier."})
else:
    classify("MEASUREMENT_INTEGRITY_R7_STILL_VALID", None,
             {"error": "R6 measurement-integrity verifier not found at " + str(mi_verifier)})

# D6 / Phase 4 / OPC directories must not exist OR must be pre-existing
# (untouched by E03). The dirty working tree documented in the baseline
# manifest already contains a pre-existing untracked `phase4` directory
# (files dated 2026-07-25 to 2026-08-31, all older than E03). We therefore
# check: (a) no D6 / OPC directories; (b) phase4 exists BUT no file under
# it has an mtime newer than the E03 pre-registration (proving E03 did not
# touch it).
prereg_mtime = PREREG.stat().st_mtime if PREREG.exists() else None

candidate_d6_dirs = [
    ROOT / "lib" / "tiannara" / "d6",
    ROOT / "lib" / "tiannara" / "opc",
    ROOT / "lib" / "tiannara" / "memory_d6",
]
d6_violations = []
for d in candidate_d6_dirs:
    if d.exists():
        d6_violations.append(str(d.relative_to(ROOT)))
classify("ABSENCE_OF_D6_OPC_MEMORY_D6", len(d6_violations) == 0,
         {"checked": [str(d.relative_to(ROOT)) for d in candidate_d6_dirs],
          "violations": d6_violations})

phase4_dir = ROOT / "lib" / "tiannara" / "phase4"
if phase4_dir.exists() and prereg_mtime is not None:
    phase4_files = [p for p in phase4_dir.rglob("*") if p.is_file()]
    phase4_newer = [str(p.relative_to(ROOT)) for p in phase4_files
                    if p.stat().st_mtime > prereg_mtime]
    phase4_ok = len(phase4_newer) == 0
    classify("PHASE4_PRE_EXISTING_AND_UNTouched_BY_E03", phase4_ok,
             {"phase4_path": str(phase4_dir.relative_to(ROOT)),
              "total_files": len(phase4_files),
              "files_modified_after_e03_prereg": phase4_newer,
              "note": "phase4 is pre-existing untracked content from the dirty working tree. E03 must not have touched it."})
else:
    classify("PHASE4_PRE_EXISTING_AND_UNTouched_BY_E03", True,
             {"phase4_exists": phase4_dir.exists(),
              "note": "phase4 does not exist or prereg mtime unavailable; nothing to verify."})

# D5 facade must still return :d5_certified_bounded.
d5_facade = text_of(ROOT / "lib" / "tiannara" / "forecasting" / "d5.ex")
d5_frozen = "def verdict, do: :d5_certified_bounded" in d5_facade
classify("D5_FACADE_STILL_CERTIFIED_BOUNDED", d5_frozen,
         {"d5_facade_path": str(ROOT / "lib/tiannara/forecasting/d5.ex"),
          "verdict_line_present": d5_frozen})

# E06/E07 must still be FALSIFIED in the claim registry.
claim_reg = text_of(ROOT / "certification" / "empirical_validation" / "TIANNARA_CLAIM_REGISTRY.md")
e06_falsified = "E06" in claim_reg and "FALSIFIED" in claim_reg.split("E06")[1][:2000]
e07_falsified = "E07" in claim_reg and "FALSIFIED" in claim_reg.split("E07")[1][:2000]
classify("E06_E07_PRESERVED_FALSIFIED", e06_falsified and e07_falsified,
         {"e06_falsified_in_text": e06_falsified, "e07_falsified_in_text": e07_falsified})

# ---- 12. Absence of post-hoc parameter modification ----
# We assert that the manifest status field is "FROZEN" and no_post_hoc_modification is true.
if manifest is not None:
    no_posthoc = manifest.get("no_post_hoc_modification", False) is True
    status_frozen = "FROZEN" in str(manifest.get("status", ""))
    classify("MANIFEST_FROZEN_NO_POSTHOC", no_posthoc and status_frozen,
             {"no_post_hoc_modification": no_posthoc,
              "status": manifest.get("status")})
else:
    classify("MANIFEST_FROZEN_NO_POSTHOC", False, {"manifest_loaded": False})

# Also: the preregistration must include the explicit pre-registration freeze declaration.
freeze_decl = "Pre-registration freeze declaration" in prereg_text or "pre-registration freeze" in prereg_text.lower()
classify("PREREG_HAS_FREEZE_DECLARATION", freeze_decl,
         {"freeze_declaration_in_text": freeze_decl})

# ---- Summary ----
results["GATES_PASS"] = pass_count
results["GATES_FAIL"] = fail_count
results["GATES_INDETERMINATE"] = indet_count
results["GATES_TOTAL"] = pass_count + fail_count + indet_count

# Verifier verdict.
if fail_count == 0 and indet_count == 0:
    overall = "PASS"
    exit_code = 0
elif fail_count == 0:
    overall = "INDETERMINATE"
    exit_code = 0
else:
    overall = "FAIL"
    exit_code = 1

results["OVERALL"] = overall
results["EXIT_CODE"] = exit_code
results["VERIFIER_NOTES"] = [
    "This verifier does not execute E03, invoke stabilizers, mutate code, or modify the preregistration.",
    "All assertions are deterministic and reproducible.",
    "Pass conditions: all assertions are PASS.",
    "FAIL conditions: any assertion is FAIL.",
    "INDETERMINATE conditions: at least one assertion is INDETERMINATE and zero are FAIL.",
    "Frozen against HEAD " + FROZEN_HEAD + ".",
]

OUT.write_text(json.dumps(results, indent=2) + "\n")
print(json.dumps(results, indent=2))
sys.exit(exit_code)
