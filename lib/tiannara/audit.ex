defmodule Tiannara.Audit do
  @moduledoc """
  Tiannara System Integrity Audit
  
  This module provides the complete audit system for validating the unified architecture.
  The audit is designed to detect silent architectural divergence - the biggest risk
  after unification of Core, World Model, Domain Cortex, AEO, Runtime, CIS, OED, and GRCC.
  
  Usage:
  ```elixir
  # Run complete audit
  Tiannara.Audit.run_complete_audit()
  
  # Run specific tier
  Tiannara.Audit.run_tier("Tier 1")
  ```
  """

  alias Tiannara.Audit.Tier0
  alias Tiannara.Audit.Tier1
  alias Tiannara.Audit.Tier2
  alias Tiannara.Audit.Tier3
  alias Tiannara.Audit.Discovery
  alias Tiannara.Audit.Evolution
  alias Tiannara.Audit.Tier1.ArchitecturalInvariants
  alias Tiannara.Audit.Tier2.WorldModelIntegrity
  alias Tiannara.Audit.Tier3.CoreIntegration
  alias Tiannara.Audit.Tier4.DomainCortex
  alias Tiannara.Audit.Tier5_8.SystemTests
  alias Tiannara.Audit.Tier9.EndToEnd
  alias Tiannara.Audit.FinalScorecard

  @doc "Run the complete system integrity audit"
  def run_complete_audit do
    try do
      IO.puts("🚀 Starting Tiannara System Integrity Audit")
      IO.puts("📅 #{DateTime.utc_now()}")
      IO.puts("=" <> String.duplicate("=", 70))
      
      # Run the complete audit through the scorecard system
      scorecard = FinalScorecard.run_complete_audit()
      
      IO.puts("\n" <> String.duplicate("=", 70))
      IO.puts("🎯 AUDIT COMPLETE")
      IO.puts(String.duplicate("=", 70))
      
      if scorecard.overall_passed do
        IO.puts("✅ SYSTEM INTEGRITY VERIFIED")
        IO.puts("✅ Ready for advanced feature integration")
      else
        IO.puts("❌ SYSTEM INTEGRITY COMPROMISED")
        IO.puts("❌ Remediation required before proceeding")
      end
      
      scorecard
    rescue
      error ->
        IO.puts("❌ AUDIT FAILED: #{inspect(error)}")
        IO.puts("🔧 Check system components and try again")
        {:error, error}
    end
  end

  @doc "Run a specific audit tier"
  def run_tier(tier_name) when is_binary(tier_name) do
    IO.puts("🔍 Running #{tier_name} Audit")
    IO.puts("=" <> String.duplicate("=", 50))
    
    case String.downcase(tier_name) do
      "tier 0" -> Tier0.run_all()
      "foundational" -> Tier0.run_all()
      "tier 1 emergence" -> Tier1.run_all()
      "tier 2 governance" -> Tier2.run_all()
      "tier 3 epistemic" -> Tier3.run_all()
      "tier 4 discovery" -> Discovery.run_all()
      "tier 5 evolution" -> Evolution.run_all()
      "reality check" -> Discovery.run_all()
      "tier 1" -> ArchitecturalInvariants.run_all_tests()
      "tier 2" -> WorldModelIntegrity.run_all_tests()
      "tier 3" -> CoreIntegration.run_all_tests()
      "tier 4" -> DomainCortex.run_all_tests()
      "tier 5" -> SystemTests.run_all_tests()
      "tier 6" -> SystemTests.run_all_tests()
      "tier 7" -> SystemTests.run_all_tests()
      "tier 8" -> SystemTests.run_all_tests()
      "tier 9" -> EndToEnd.run_all_tests()
      "architectural invariants" -> ArchitecturalInvariants.run_all_tests()
      "world model integrity" -> WorldModelIntegrity.run_all_tests()
      "core integration" -> CoreIntegration.run_all_tests()
      "domain cortex" -> DomainCortex.run_all_tests()
      "system tests" -> SystemTests.run_all_tests()
      "end to end" -> EndToEnd.run_all_tests()
      _ ->
        IO.puts("❌ Unknown tier: #{tier_name}")
        IO.puts("Available tiers: Tier 1, Tier 2, Tier 3, Tier 4, Tier 5-8, Tier 9")
        {:error, :unknown_tier}
    end
  end

  @doc "Run quick diagnostics (fast subset of tests)"
  def run_quick_diagnostics do
    IO.puts("⚡ Running Quick Diagnostics")
    IO.puts("=" <> String.duplicate("=", 40))
    
    results = %{
      core_sovereignty: ArchitecturalInvariants.test_ai_001_core_sovereignty(),
      world_model_authority: ArchitecturalInvariants.test_ai_002_world_model_authority(),
      entity_consistency: WorldModelIntegrity.test_wm_001_entity_consistency(),
      goal_to_intent: CoreIntegration.test_core_001_goal_to_intent(),
      domain_team: DomainCortex.test_dc_001_domain_team_assembly(),
      intent_translation: SystemTests.test_aeo_001_intent_translation(),
      runtime_sub: SystemTests.test_aeo_002_runtime_submission()
    }
    
    passed = Enum.count(results, fn {_, result} -> result == :pass end)
    total = map_size(results)
    
    IO.puts("\n📊 Quick Diagnostics: #{passed}/#{total} passed")
    
    if passed == total do
      IO.puts("✅ System appears healthy")
    else
      IO.puts("⚠️  Some issues detected - run full audit for details")
    end
    
    results
  end

  @doc "Get audit status and summary"
  def get_audit_status do
    %{
      timestamp: DateTime.utc_now(),
      system: "Tiannara Unified Architecture",
      tiers: [
        {"Tier 0: Foundational (REA)", 10},
        {"Tier 1: Emergence Audits", 4},
        {"Tier 2: Governance Audits", 4},
        {"Tier 3: Epistemic Audits", 3},
        {"Tier 4: Reality Correspondence", 4},
        {"Tier 1 (Legacy): Architectural Invariants", 4},
        {"Tier 2: World Model Integrity", 5},
        {"Tier 3: Core Integration", 3},
        {"Tier 4: Domain Cortex", 3},
        {"Tier 5-8: System Tests", 12},
        {"Tier 9: End-to-End", 3}
      ],
      total_tests: 30,
      pass_targets: %{
        "Tier 0: Foundational (REA)" => 100,
        "Tier 1: Emergence Audits" => 100,
        "Tier 2: Governance Audits" => 100,
        "Tier 3: Epistemic Audits" => 100,
        "Tier 4: Reality Correspondence" => 80,
        "Tier 5: Evolutionary Effectiveness" => 70,
        "Tier 1 (Legacy): Architectural Invariants" => 100
      },
      audit_priorities: [
        "Detect silent architectural divergence",
        "Verify World Model as single source of truth",
        "Ensure Core sovereignty over intent generation",
        "Validate domain separation of concerns",
        "Test end-to-end system integration"
      ]
    }
  end

  @doc "Generate audit report template"
  def generate_report_template do
    """
    # Tiannara System Integrity Audit Template

    ## Audit Overview
    - **Date**: [Audit Date]
    - **System**: Tiannara Unified Architecture
    - **Auditor**: [Your Name/Team]
    - **Purpose**: Verify architectural integrity after unification

    ## Test Categories

    ### Tier 0: Foundational (REA)
    - [ ] L1 Architectural Understanding
    - [ ] L2 Invariant Preservation
    - [ ] L3 Experiment Classification
    - [ ] L4 World Model Accuracy
    - [ ] L5 Experiment Memory
    - [ ] L6 Simulation Accuracy
    - [ ] L7 Specialist Agent Ecology
    - [ ] L8 GHL (Generativity Half-Life)
    - [ ] L9 Silent Failure Detection
    - [ ] L10 Self-Improvement Loop

    ### Tier 1: Emergence Audits
    - [ ] T1-A Architecture Model Fidelity
    - [ ] T1-B Prediction Calibration (Brier Score)
    - [ ] T1-D Knowledge Graph Consistency
    - [ ] T1-E Specialist Drift (Diversity)

    ### Tier 2: Governance Audits
    - [ ] T2-A Constitutional Resilience (Adversarial)
    - [ ] T2-B Approval Gate Integrity
    - [ ] T2-C Silent Failure Stress Test
    - [ ] T2-E False Emergence Audit

    ### Tier 3: Epistemic Audits
    - [ ] T3-A Epistemic Rigor (Counterarguments)
    - [ ] T3-B Assumption Exposure
    - [ ] T3-C Evidence Weighting (Quantified)

    ### Tier 4: Reality Correspondence (Discovery)
    - [ ] T4-A Hidden Coupling Discovery
    - [ ] T4-B Metric Gaming Detection
    - [ ] T4-C Measurement Skepticism (Lying Instruments)
    - [ ] T4-D Shadow Research Benchmark

    ### Tier 5: Evolutionary Effectiveness
    - [ ] T5-A Architectural Fitness (Prediction/GHL Trend)
    - [ ] T5-B Improvement Yield Rate
    - [ ] T5-C Research Efficiency
    - [ ] T5-D Novel Discovery Rate
    - [ ] T5-E Discovery-to-Value Ratio (DVR)

    ### Tier 1 (Legacy): Architectural Invariants
    - [ ] AI-001 Core Sovereignty (Only Core generates intent)
    - [ ] AI-002 World Model Authority (Single source of truth)
    - [ ] AI-003 Runtime Ownership (Runtime owns entropy, pressure, constraints)
    - [ ] AI-004 Domain Ownership (Domains never mutate core identity)

    ### Tier 2: World Model Integrity
    - [ ] WM-001 Entity Consistency (User, Goal, Lineage, Project)
    - [ ] WM-002 Belief Revision (Contradictory beliefs increase uncertainty)
    - [ ] WM-003 Temporal Integrity (Timeline ordering preserved)
    - [ ] WM-004 Prediction Feedback (Belief confidence decreases)
    - [ ] WM-005 Causal Consistency (Counterfactual propagation)

    ### Tier 3: Core Integration
    - [ ] CORE-001 Goal → Intent (Goal System → Intent Graph → AEO)
    - [ ] CORE-002 Meta-Cognition Uses World Model (Uncertainty increases Logic/Causal)
    - [ ] CORE-003 Identity Persistence (Lineage preserved over 100 cycles)

    ### Tier 4: Domain Cortex
    - [ ] DC-001 Domain Team Assembly (Trading strategy selects correct domains)
    - [ ] DC-002 Domain Diversity (Prediction 80% triggers CIS warning)
    - [ ] DC-003 Domain Collaboration (RE, Logic, Causal, Ethics work together)

    ### Tier 5-8: System Tests
    - [ ] AEO-001 Intent Translation (Deterministic Goal → Execution Graph)
    - [ ] AEO-002 Runtime Submission (submit_to_runtime() only)
    - [ ] AEO-003 Feedback Loop (Success updates World Model and goals)
    - [ ] CIS-001 Monoculture Detection (Prediction 80% warning)
    - [ ] CIS-002 Constraint Behavior (Core decides despite CIS warnings)
    - [ ] CIS-003 Collapse Simulation (Entropy 0.15 → recommendations)
    - [ ] OED-001 Constitution Check (Invalid plan rejected)
    - [ ] OED-002 Adversarial Challenge (ACM → alternative ontology)
    - [ ] OED-003 Validation Pipeline (ACM → OAVL → UMSC → approval)
    - [ ] RT-001 Runtime Cannot Create Intent (Runtime.create_goal() fails)
    - [ ] RT-002 Runtime Uses World Model (Updates through RuntimeAPI)
    - [ ] RT-003 Pressure Loop (GRCC → CIS → GRCC stability)

    ### Tier 9: End-to-End
    - [ ] E2E-001 Trading Strategy (Complete pipeline verification)
    - [ ] E2E-002 Malware Analysis (Multi-domain collaboration)
    - [ ] E2E-003 Long Horizon (10,000 cycles stability metrics)

    ## Pass Targets
    | Area | Pass Target |
    |------|-------------|
    | Foundational (REA) | 100% |
    | Emergence Audits | 100% |
    | Governance Audits | 100% |
    | Epistemic Audits | 100% |
    | Reality Correspondence | >80% |
    | Evolutionary Effectiveness | >70% |
    | Architectural Invariants | 100% |

    ## Readiness Assessment
    - **REA-1 (Low Risk)**: FULLY AUTONOMOUS
    - **REA-2 (Architectural)**: GRADUATED TRUST (Phase A: Shadow + Approval)
    - **REA-3 (Critical)**: HUMAN-IN-THE-LOOP REQUIRED
    | World Model Integrity | 100% |
    | Core Integration | 100% |
    | Domain Cortex | >95% |
    | AEO | 100% |
    | CIS | 100% |
    | OED | 100% |
    | Runtime | >95% |
    | End-to-End | 100% |

    ## Critical Success Factors
    1. **Silent Architectural Divergence Detection** - Biggest risk after unification
    2. **World Model Authority** - Must be single source of truth
    3. **Core Sovereignty** - Only Core generates intent
    4. **Temporal Integrity** - Timeline ordering preserved
    5. **Domain Separation** - Clear ownership boundaries

    ## Remediation Steps
    1. Fix all failing tests
    2. Re-run audit to verify fixes
    3. Ensure 100% pass rate for critical tiers
    4. Only proceed to advanced features after audit passes

    ---
    *Template for Tiannara System Integrity Audit*
    """
  end
end
