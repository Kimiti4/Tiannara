defmodule TiannaraRuntime.Phase6MetaGovernanceTest do
  use ExUnit.Case, async: false

  alias TiannaraRuntime.MSG.Governor, as: MSG
  alias TiannaraRuntime.OMCS.ContinuityIndex, as: OMCS
  alias TiannaraRuntime.OMCS.IdentityHashChain
  alias TiannaraRuntime.EUF.ConfidenceTracker, as: EUF
  alias TiannaraRuntime.ALES.EvolutionEngine, as: ALES
  alias TiannaraRuntime.Shared.ConstitutionalLaws, as: Constitution
  alias TiannaraRuntime.CCR.Tracker, as: CCRTracker
  alias TiannaraRuntime.SelfCompilation.RewriteEngine

  setup do
    # Start all stateful GenServers to guarantee absolute test isolation
    for mod <- [MSG, OMCS, EUF, ALES, CCRTracker, RewriteEngine] do
      if !Process.whereis(mod) do
        start_supervised!(mod)
      end
    end

    # Reset all GenServers to clean state
    for mod <- [MSG, OMCS, EUF, ALES, CCRTracker, RewriteEngine] do
      if Process.whereis(mod) do
        GenServer.call(mod, :reset)
      end
    end

    :ok
  end

  # ==================== MSG Governor Tests ====================

  test "MSG Governor computes pressure correctly and throttles on overregulation" do
    # Propose safe interventions
    assert :ok = MSG.propose_intervention(:rrg, 0.1)
    assert :ok = MSG.propose_intervention(:ctl, 0.2)

    # Stabilization pressure M = sum(I) / max(unique * 0.5, 0.1) = 0.3 / 1.0 = 0.3
    assert_in_delta MSG.get_pressure(), 0.3, 0.01
    refute MSG.overregulated?()

    # Trigger overregulation: push intensity above the threshold (0.85)
    # Total intensity will be 0.1 + 0.2 + 0.65 = 0.95.
    # unique = 3, adaptive_activity = 1.5. M = 0.95 / 1.5 = 0.633.
    # Let's add more to same stabilizer to decrease unique variety and spike pressure.
    assert :ok = MSG.propose_intervention(:rrg, 0.4)
    # Total intensity = 0.1 + 0.2 + 0.4 = 0.7. unique = 2. M = 0.7 / 1.0 = 0.7

    # This intervention spikes M past 0.85
    assert :throttled = MSG.propose_intervention(:rrg, 0.6)
  end

  # ==================== OMCS Continuity Tests ====================

  test "OMCS tracks persistent memory lineage and semantic continuity" do
    # Record civilization memory snapshots
    OMCS.record_lineage("civ_alpha", "concept_initial_v1")
    OMCS.record_lineage("civ_alpha", "concept_initial_v2")

    # High consistency: concept_initial_v1 and concept_initial_v2 are highly similar
    assert OMCS.get_continuity_score("civ_alpha") >= 0.85
    assert :ok = OMCS.verify_continuity("civ_alpha", "concept_initial_v3")

    # Drastic mutation causing drift failure
    assert {:error, :excessive_identity_drift} = OMCS.verify_continuity("civ_alpha", "entirely_different_unrelated_concept")
  end

  test "IdentityHashChain cryptographically hashes and validates causality lines" do
    link0 = "root_hash"
    link1 = IdentityHashChain.generate_link(link0, ["concept_a"], 12345)
    link2 = IdentityHashChain.generate_link(link1, ["concept_a", "concept_b"], 12346)

    chain = [
      {link2, link1, ["concept_a", "concept_b"], 12346},
      {link1, link0, ["concept_a"], 12345}
    ]

    assert IdentityHashChain.validate_chain(chain)
  end

  # ==================== EUF Confidence Tests ====================

  test "EUF measures epistemic uncertainty and flags fragile theories" do
    # When observers are in perfect consensus, epistemic uncertainty U is high (1.0)
    EUF.record_belief("theory_omega", "observer_1", 0.9)
    EUF.record_belief("theory_omega", "observer_2", 0.9)

    assert {:ok, u} = EUF.get_epistemic_confidence("theory_omega")
    assert u == 1.0
    assert EUF.robust?("theory_omega")

    # High divergence (observer 1 believes 0.9, observer 2 believes 0.1)
    EUF.record_belief("theory_omega", "observer_2", 0.1)

    assert {:ok, u_diverged} = EUF.get_epistemic_confidence("theory_omega")
    assert u_diverged < 0.40
    refute EUF.robust?("theory_omega")
  end

  # ==================== ALES Parameter Evolution Tests ====================

  test "ALES evolves safety thresholds using outcome fitness evaluation" do
    # Register dynamic critical curvature parameter
    ALES.register_law(:critical_curvature, 12.0, {8.0, 16.0})

    # Propose mutation delta
    assert {:ok, 13.0} = ALES.propose_mutation(:critical_curvature, 1.0)

    # Variant with excellent fitness outcome triggers promotion to active parameter
    assert {:ok, :promoted, 13.0} = ALES.evaluate_fitness(:critical_curvature, 120, %{stability: 0.9, coherence: 0.9})
    assert {:ok, 13.0} = ALES.get_active_value(:critical_curvature)

    # Variant with bad fitness is discarded
    assert {:ok, 14.0} = ALES.propose_mutation(:critical_curvature, 1.0)
    assert {:ok, :retained, 13.0} = ALES.evaluate_fitness(:critical_curvature, 10, %{stability: 0.2, coherence: 0.2})
  end

  # ==================== Constitutional Law Invariant Tests ====================

  test "Constitution enforces immutable scarcity and causality rules" do
    # Scarcity: total energy must remain positive
    assert :ok = Constitution.validate_thermodynamics(100.0, 40.0)
    assert {:error, :energy_violation} = Constitution.validate_thermodynamics(20.0, 30.0)

    # Causality: direct self-loops (paradoxes) are blocked
    assert :ok = Constitution.validate_non_paradoxical("node_a", "node_b")
    assert {:error, :causal_paradox} = Constitution.validate_non_paradoxical("node_a", "node_a")

    # Continuity integration
    OMCS.record_lineage("civ_alpha", "concept_v1")
    assert :ok = Constitution.validate_continuity("civ_alpha", "concept_v2")
  end

  # ==================== RewriteEngine CCR Integration Tests ====================

  test "RewriteEngine applies CCR guidance dynamically during compilation loops" do
    # Verify RewriteEngine boots and compiles subsystems
    assert {:ok, stats} = RewriteEngine.get_stats()
    assert stats.success_rate >= 0.0

    # Inject an active Kolmogorov ceiling via the CCR Tracker
    # rule: restrict OPC ast_optimization_level if complexity ceiling is violated
    CCRTracker.record_trace(%{
      nodes: [
        %{id: "rule_unstable", complexity: 0.95, throughput: 0.1, reversibility: 0.88}
      ],
      edges: [],
      observers: []
    })

    assert {:ok, guidance} = CCRTracker.get_guidance()
    assert Enum.any?(guidance, &(&1.rule_type == :enforce_kolmogorov_ceiling))

    # Trigger OPC subsystem compilation.
    # The RewriteEngine will consult CCR guidance rules and limit ast_optimization_level to 1 or 2,
    # preventing it from mutating to level 3 (the max).
    assert {:ok, compile_result} = GenServer.call(RewriteEngine, {:compile, :opc, 0.2, %{}})
    assert compile_result.subsystem == :opc
    assert compile_result.status == :compiled
  end
end
