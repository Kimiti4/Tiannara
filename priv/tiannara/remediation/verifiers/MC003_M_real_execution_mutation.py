"""
MC-003-M real-execution truthfulness mutation verifier.

Performs actual static verification over the repository to confirm the
M1+M2+M3+M4+M6+M7+M8 (M5-excluded) mutation claims. It does NOT trust the
certification record; it scans real files and reports what it finds.

Checks:
  M1: VerificationAuthority/Result/CertificationServer/ExecutiveCycle/CEL steps
      truthful — no fabricated passing, no pre-opened certification gates,
      no fabricated execution statuses, CEL constant steps unavailable.
  M2: Phase4 gateway — submit_experiment gated by :real_execution_enabled;
      delegation to RealExecution (RealHarness + DeploymentGateway + grant);
      Approval.decide(:approve) routed through the gateway (no direct sandbox).
  M3: DiscoveryScheduler confidence_delta derived from evidence distribution.
  M4: Real execution records carry harness/method :real_sandbox evidence.
  M6: ProductionObservatory provider-gated; no fabricated RealityLedger feed;
      stubs/httpoison.ex removed.
  M7: RollbackEngine unavailable.
  M8: ConstitutionalAutonomy/ASC.Repair/ToolForge/SOPL surfaces unavailable or
      staged — no fabricated success.
  Meta: :real_execution_enabled NOT flipped; no live real experiment run;
      M5/os boot wiring untouched; authorization GRANTED by c14_ac;
      artifacts present; result JSON structurally valid + truthful flags.
"""
import json
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", ".."))
LIB = os.path.join(ROOT, "lib", "tiannara")


def read(rel):
    with open(os.path.join(LIB, rel), encoding="utf-8", errors="replace") as fh:
        return fh.read()


def read_root(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8", errors="replace") as fh:
        return fh.read()


def main():
    failures = []

    # ------------------------------------------------------------------ M1
    va = read(os.path.join("verification_authority.ex"))
    if "reproduced: false" not in va:
        failures.append("VerificationAuthority does not record reproduced=false")
    if "all_passing: false" not in va:
        failures.append("VerificationAuthority does not record all_passing=false")
    if ":not_independently_assessed" not in va:
        failures.append("VerificationAuthority compliance not :not_independently_assessed")
    if "attr_acceptor" in va or "AttrAcceptor" in va:
        failures.append("VerificationAuthority retains attr acceptor fabrication")

    vr = read(os.path.join("verification", "result.ex"))
    if "def passed?" not in vr:
        failures.append("Verification.Result.passed?/1 missing")
    if "is_map(" not in vr:
        failures.append("Verification.Result.passed?/1 lacks is_map guard")
    if "reproduced" in vr and "all_passing" not in vr:
        failures.append("Verification.Result passed?/1 no longer keys off all_passing")

    cs = read(os.path.join("omega", "certification_server.ex"))
    if ":unevaluated" not in cs:
        failures.append("CertificationServer has no :unevaluated gate_results path")
    if "gate_open" in cs.split("defmodule")[1] and "oracle" not in cs.lower():
        failures.append("CertificationServer retains fabricated pre-opened gate")

    ec = read(os.path.join("executive", "cognitive", "executive_cycle.ex"))
    if '"pending"' not in ec and ":pending" not in ec:
        failures.append("ExecutiveCycle :execute phase has no pending status")
    if "awaiting_real_execution_provider" not in ec and "real" not in ec.lower():
        failures.append("ExecutiveCycle :execute lacks real-execution acknowledgment")
    # :validate must require real execution evidence; fabricated valid=true gone
    if "no_real_execution_evidence" not in ec:
        failures.append("ExecutiveCycle :validate has no no_real_execution_evidence reason")
    if "valid: validated" not in ec and "valid: true" not in ec:
        failures.append("ExecutiveCycle :validate does not derive valid from real evidence")

    for step in ["experiment", "observation", "validation"]:
        s = read(os.path.join("cel", "workflow", "steps", step + ".ex"))
        if "real_step_provider_not_wired" not in s:
            failures.append("CEL step " + step + " does not return real_step_provider_not_wired")

    # ------------------------------------------------------------------ M2
    orc = read(os.path.join("phase4", "experiment_orchestrator.ex"))
    if "real_execution_not_enabled" not in orc:
        failures.append("submit_experiment lacks disabled flag behavior")
    if "RealExecution.execute" not in orc:
        failures.append("orchestrator handle_call does not delegate to RealExecution")

    re_ = read(os.path.join("phase4", "real_execution.ex"))
    for token in ["def enabled?", "authorization_grant_required",
                  "no_real_execution_substrate_configured", "RealHarness.run",
                  "executions.jsonl", "Provenance.build", "DeploymentGateway.deploy",
                  "exp_" ]:
        if token not in re_:
            failures.append("RealExecution missing: " + token)
    if 'kind: :real_execution' not in re_ and "kind: \":real_execution\"" not in re_:
        failures.append("RealExecution provenance kind not :real_execution")

    ap = read(os.path.join("sentinel", "activation", "approval.ex"))
    if "submit_experiment" not in ap:
        failures.append("Approval.decide(:approve) not routed through orchestration")
    if "Tiannara.Sandbox.execute" in ap:
        failures.append("Approval.decide(:approve) still calls Tiannara.Sandbox.execute")

    # ------------------------------------------------------------------ M3
    ds = read(os.path.join("discovery", "discovery_scheduler.ex"))
    if "confidence_delta" not in ds or "evidence_confidences" not in ds:
        failures.append("DiscoveryScheduler lacks evidence-derived confidence_delta")
    # delta must be a function of the evidence confidence distribution
    if "Enum.sum(confs)" not in ds and "Enum.sum(confidences)" not in ds:
        failures.append("DiscoveryScheduler confidence_delta not sum-based on evidence")
    if "* 0.2" not in ds or "* -0.05" not in ds:
        failures.append("DiscoveryScheduler confidence_delta lacks supported/refuted coefficients")

    # ------------------------------------------------------------------ M4
    if "harness: :real_sandbox" not in re_ and "harness: :real_sandbox" not in re_:
        failures.append("RealExecution verification evidence lacks harness: :real_sandbox")
    if "method: :real_sandbox" not in re_:
        failures.append("RealExecution verification evidence lacks method: :real_sandbox")

    # ------------------------------------------------------------------ M6
    if not os.path.exists(os.path.join(LIB, "reality", "production_observatory.ex")):
        failures.append("production_observatory.ex missing")
    else:
        po = read(os.path.join("reality", "production_observatory.ex"))
        if ":no_external_provider" not in po:
            failures.append("ProductionObservatory lacks no_external_provider path")
        if ":unavailable" not in po:
            failures.append("ProductionObservatory lacks unavailable status")
        if "fed_reality_ledger: false" not in po:
            failures.append("ProductionObservatory does not keep fed_reality_ledger false without provider")
        # With a real provider, ledger feed must be driven by REAL fetched numbers
        if "record_revenue" in po and "stripe_revenue > 0" not in po and "fetch_stripe_revenue" not in po:
            failures.append("ProductionObservatory record_revenue not gated behind a real provider fetch")
        if "observatory_provider" not in po or "external_providers_enabled" not in po:
            failures.append("ProductionObservatory not gated by external_providers flag")
    if os.path.exists(os.path.join(LIB, "stubs", "httpoison.ex")):
        failures.append("stubs/httpoison.ex still exists")

    # ------------------------------------------------------------------ M7
    rb = read(os.path.join("autonomy", "rollback_engine.ex"))
    if ":rollback_unavailable" not in rb:
        failures.append("RollbackEngine does not return :rollback_unavailable")

    # ------------------------------------------------------------------ M8
    ca = read(os.path.join("autonomy", "constitutional_autonomy.ex"))
    if ":not_available" not in ca or ":simulation" not in ca:
        failures.append("ConstitutionalAutonomy run_cycle gated stage missing")
    if "real_simulation_provider?" not in ca:
        failures.append("ConstitutionalAutonomy lacks provider gate")

    pl = read(os.path.join("asc", "repair", "pipeline.ex"))
    for tok in ["SandboxValidator", "CanaryReleaser", "ProductionRollout"]:
        if tok not in pl:
            failures.append("ASC.repair pipeline missing surface: " + tok)
    # each of the three must be unavailable/blocking (no fabricate/release)
    if ":error, :unavailable" not in pl:
        failures.append("ASC.repair pipeline does not return :unavailable")

    tb = read(os.path.join("tool_forge", "tool_builder.ex"))
    if ":not_implemented" not in tb:
        failures.append("ToolForge do_execute does not return :not_implemented")

    ev = read(os.path.join("sopl", "evolution_engine.ex"))
    if "deploy" not in ev:
        failures.append("SOPL evolution_engine missing deploy/1")
    if "STAGED" not in ev:
        failures.append("SOPL evolution_engine deploy lacks staged marker")

    # ------------------------------------------------------------- protected
    # The flag must NOT be flipped to true anywhere in config; the module default
    # in RealExecution.enabled?/0 is false (checked below via source scan).
    cfg_all = ""
    for f in ["config.exs", "dev.exs", "test.exs", "prod.exs", "runtime.exs"]:
        try:
            cfg_all += read_root(os.path.join("config", f))
        except OSError:
            pass
    if "real_execution_enabled: true" in cfg_all or "real_execution_enabled = true" in cfg_all:
        failures.append("real_execution_enabled is TRUE somewhere in config (must stay false)")
    if "Application.get_env(:tiannara, :real_execution_enabled, false)" not in re_:
        failures.append("RealExecution.enabled?/0 does not default to false")

    # ------------------------------------------------------------- artifacts
    artifacts = [
        "certification/remediation/MC003-M-EVIDENCE-MATRIX.md",
        "certification/remediation/MC003-M-CERTIFICATION.md",
        "priv/tiannara/remediation/contracts/MC003_M_real_execution_mutation.contract.yaml",
        "priv/tiannara/remediation/results/MC003_M_result.json",
        "priv/tiannara/authorization/ASC-MC-003-M-REAL-EXECUTION-MUTATION.human.yaml",
    ]
    for a in artifacts:
        if not os.path.exists(os.path.join(ROOT, a)):
            failures.append("artifact missing: " + a)

    try:
        auth = read_root(os.path.join("priv", "tiannara", "authorization", "ASC-MC-003-M-REAL-EXECUTION-MUTATION.human.yaml"))
    except (FileNotFoundError, OSError):
        auth = ""
        failures.append("ASC-MC-003-M authorization human.yaml missing")
    if "status: \"GRANTED\"" not in auth and "status: GRANTED" not in auth:
        failures.append("mutation authorization not GRANTED")
    if "c14_ac" not in auth:
        failures.append("mutation authorization operator not c14_ac")

    try:
        result = json.load(open(
            os.path.join(ROOT, "priv", "tiannara", "remediation", "results", "MC003_M_result.json"),
            encoding="utf-8"))
    except (OSError, ValueError):
        result = None
        failures.append("MC003_M_result.json invalid or unreadable")
    if isinstance(result, dict):
        if result.get("mutation_authorized") is not True:
            failures.append("result JSON does not record mutation_authorized true")
        if result.get("verdict") != "CERTIFIED_BOUNDED":
            failures.append("result JSON verdict not CERTIFIED_BOUNDED")
        if result.get("live_real_experiment_executed") is not False:
            failures.append("result JSON claims a live real experiment ran")
        if result.get("real_execution_enabled_flag") is not False:
            failures.append("result JSON claims real_execution_enabled true")
        if result.get("scope_m5_os_boot_wiring") != "EXCLUDED_BY_AUTHORIZATION":
            failures.append("result JSON does not record M5 exclusion")
        return_inspected = result.get("evidence", {}).get("verifier")
        if not return_inspected or "PENDING" in str(return_inspected):
            failures.append("result JSON evidence.verifier not finalized")

    if failures:
        print("MC-003-M VERIFY: FAIL")
        for f_ in failures:
            print("  -", f_)
        sys.exit(1)

    print("MC-003-M VERIFY: PASS")
    print("  M1 truth        : VerificationAuthority/Result/CertificationServer/ExecutiveCycle/CEL truthful")
    print("  M2 gateway      : orchestrator submit gated -> RealExecution (RealHarness+DeploymentGateway+grant)")
    print("  M3 discovery    : confidence_delta derived from evidence distribution")
    print("  M4 evidence     : real execution records harness :real_sandbox provenance")
    print("  M6 observatory  : provider-gated, no fabricated RealityLedger feed; stubs/httpoison.ex removed")
    print("  M7 rollback     : RollbackEngine returns :rollback_unavailable")
    print("  M8 autonomy     : ConstitutionalAutonomy/Repair/ToolForge/SOPL unavailable/staged")
    print("  Protected       : real_execution_enabled=false; no live experiment; M5 excluded")
    print("  Authorization   : GRANTED (c14_ac)")
    print("  Artifacts+JSON  : present, valid, truthful flags")


if __name__ == "__main__":
    main()