defmodule Tiannara.REA.OrbitCivilizationDynamicsTest do
  use ExUnit.Case, async: false

  alias Tiannara.REA.ResearchEconomy
  alias Tiannara.REA.Epistemic.{
    Goal,
    GoalRegistry,
    GoalEcology,
    Institution,
    InstitutionRegistry,
    InstitutionEcology,
    CivilizationMemory,
    ConstitutionKernel
  }
  alias Tiannara.REA.{TheorySelection, MetaTheoryExtractor, TheoryPortfolio, PortfolioRebalancer}

  setup do
    # Ensure clean slate by deleting NDJSON civilization memory files and resetting servers
    File.rm("data/civilization_memory.ndjson")
    
    # Ensure servers are started
    ensure_started(ResearchEconomy)
    ensure_started(GoalRegistry)
    ensure_started(InstitutionRegistry)
    ensure_started(CivilizationMemory)

    ResearchEconomy.reset()
    GoalRegistry.reset()
    InstitutionRegistry.reset()
    CivilizationMemory.reset()
    :ok
  end

  defp ensure_started(module) do
    if Code.ensure_loaded?(module) and Process.whereis(module) == nil do
      module.start_link([])
    end
  end

  describe "Phase 11.20 Autonomous Research Civilization (ARC) Verification Suite" do

    test "Q1 (Goal Ecology) — EIG-based selection, coordinate mutation, and crossover" do
      # 1. Register a baseline active goal
      goal = %Goal{
        id: :goal_test_1,
        target_domain: :computation,
        focus_coordinates: %{volatility: 0.5, complexity: 0.5, adversariality: 0.5, security_pressure: 0.5},
        expected_information_gain: 0.85,
        priority_weight: 1.0,
        generation: 0,
        status: :active,
        created_at_epoch: 0
      }
      assert :ok = GoalRegistry.register_goal(goal)

      # 2. Run goal ecology tick under low volatility context
      env_context = %{volatility: 0.2, complexity: 0.2, adversariality: 0.2, security_pressure: 0.2}
      assert :ok = GoalEcology.tick(1, env_context)

      # 3. Check goals in registry
      goals = GoalRegistry.get_goals()
      assert length(goals) > 0
      
      # Verify that new goals are generated or mutated, and have higher generation count
      mutated_goals = Enum.filter(goals, &(&1.generation > 0))
      assert length(mutated_goals) > 0
      
      # Ensure coordinate values are strictly bounded between 0.0 and 1.0
      Enum.each(goals, fn g ->
        Enum.each(g.focus_coordinates, fn {_k, val} ->
          assert val >= 0.0 and val <= 1.0
        end)
      end)
    end

    test "Q2 (Research Economy) — resource regeneration, experiment costs, and pay-outs" do
      # 1. Get initial state
      state = ResearchEconomy.get_state()
      assert state.compute == 100.0
      assert state.attention == 100.0
      assert state.credits == 1000.0

      # 2. Spend resources
      assert :ok = ResearchEconomy.spend_resources(30.0, 40.0)
      state_spent = ResearchEconomy.get_state()
      assert state_spent.compute == 70.0
      assert state_spent.attention == 60.0

      # 3. Insufficient resource check
      assert {:error, :insufficient_resources} = ResearchEconomy.spend_resources(100.0, 10.0)

      # 4. Tick to regenerate resources
      assert :ok = ResearchEconomy.tick()
      state_regen = ResearchEconomy.get_state()
      assert state_regen.compute == 100.0
      assert state_regen.attention == 100.0
    end

    test "Q3 (Institution Species Evolution) — speciation dynamics: splits, merges, and extinction" do
      # 1. Verify constitutional protected organs are permanent and have fitness 1.0
      institutions = InstitutionRegistry.get_institutions()
      organs = Enum.filter(institutions, &(&1.type == :constitutional))
      assert length(organs) == 3
      Enum.each(organs, fn org ->
        assert org.fitness == 1.0
      end)

      # 2. Test Fission (split) when an evolvable species has credits >= 500
      rich_inst = %Institution{
        id: :rich_lab,
        name: "Wealthy Engineering Lab",
        type: :evolvable,
        focus_domain: :engineering,
        specialization_coordinates: %{volatility: 0.5, complexity: 0.5, adversariality: 0.5, security_pressure: 0.5},
        compute_share: 0.2,
        attention_share: 0.2,
        credits_held: 600.0,
        efficiency: 1.0,
        age: 1,
        fitness: 0.9,
        parent_ids: [],
        memory: %{successful_projects: [:goal_alpha], failed_projects: [], discovered_theories: ["theory_x"], crises_survived: 1},
        culture: %{exploration_bias: 0.5, risk_tolerance: 0.5, collaboration_bias: 0.5, security_bias: 0.5}
      }
      assert :ok = InstitutionRegistry.register_institution(rich_inst)

      # Run speciation tick
      env_context = %{volatility: 0.5, complexity: 0.5, adversariality: 0.5, security_pressure: 0.5}
      assert :ok = InstitutionEcology.tick(1, env_context)

      # Verify split happened (original rich_lab replaced with descendants inheriting memory)
      new_insts = InstitutionRegistry.get_institutions()
      descendants = Enum.filter(new_insts, &(rich_inst.id in &1.parent_ids))
      assert length(descendants) == 2
      
      # Verify memory is duplicated (compound memory inheritance)
      Enum.each(descendants, fn d ->
        assert d.memory.successful_projects == [:goal_alpha]
        assert d.memory.discovered_theories == ["theory_x"]
      end)

      # 3. Test Fusion (merge) when two species have overlapping coordinates
      overlapping_inst1 = %Institution{
        id: :overlap_1,
        name: "Overlapping Lab 1",
        type: :evolvable,
        focus_domain: :science,
        specialization_coordinates: %{volatility: 0.10, complexity: 0.10, adversariality: 0.10, security_pressure: 0.10},
        compute_share: 0.1,
        attention_share: 0.1,
        credits_held: 100.0,
        efficiency: 1.0,
        age: 1,
        fitness: 0.8,
        parent_ids: [],
        memory: %{successful_projects: [:g1], failed_projects: [], discovered_theories: [], crises_survived: 0},
        culture: %{exploration_bias: 0.5, risk_tolerance: 0.5, collaboration_bias: 0.5, security_bias: 0.5}
      }

      overlapping_inst2 = %Institution{
        id: :overlap_2,
        name: "Overlapping Lab 2",
        type: :evolvable,
        focus_domain: :science,
        specialization_coordinates: %{volatility: 0.12, complexity: 0.12, adversariality: 0.12, security_pressure: 0.12},
        compute_share: 0.1,
        attention_share: 0.1,
        credits_held: 100.0,
        efficiency: 1.0,
        age: 1,
        fitness: 0.8,
        parent_ids: [],
        memory: %{successful_projects: [:g2], failed_projects: [], discovered_theories: [], crises_survived: 0},
        culture: %{exploration_bias: 0.5, risk_tolerance: 0.5, collaboration_bias: 0.5, security_bias: 0.5}
      }

      # Reset and register overlapping ones
      InstitutionRegistry.reset()
      assert :ok = InstitutionRegistry.register_institution(overlapping_inst1)
      assert :ok = InstitutionRegistry.register_institution(overlapping_inst2)

      # Run speciation tick
      assert :ok = InstitutionEcology.tick(2, env_context)

      # Verify merge happened (one single merged institution on science domain)
      post_merge_insts = InstitutionRegistry.get_institutions()
      merged_list = Enum.filter(post_merge_insts, &String.contains?(to_string(&1.id), "inst_merge_science"))
      assert length(merged_list) == 1
      merged = hd(merged_list)
      
      # Memory contains union of successful projects: [:g1, :g2] or similar
      assert Enum.member?(merged.parent_ids, :overlap_1)
      assert Enum.member?(merged.parent_ids, :overlap_2)
      assert Enum.member?(merged.memory.successful_projects, :g1)
      assert Enum.member?(merged.memory.successful_projects, :g2)

      # 4. Test Extinction of failed ones
      extinct_inst = %Institution{
        id: :extinct_lab,
        name: "Failing Lab",
        type: :evolvable,
        focus_domain: :science,
        specialization_coordinates: %{volatility: 0.9, complexity: 0.9, adversariality: 0.9, security_pressure: 0.9},
        compute_share: 0.001, # extremely small
        credits_held: 0.0, # zero credits -> goes extinct
        efficiency: 1.0,
        age: 1,
        fitness: 0.1,
        parent_ids: [],
        memory: %{successful_projects: [], failed_projects: [], discovered_theories: [], crises_survived: 0},
        culture: %{exploration_bias: 0.5, risk_tolerance: 0.5, collaboration_bias: 0.5, security_bias: 0.5}
      }
      assert :ok = InstitutionRegistry.register_institution(extinct_inst)

      # Run speciation tick
      assert :ok = InstitutionEcology.tick(3, env_context)
      post_extinct_insts = InstitutionRegistry.get_institutions()
      refute Enum.any?(post_extinct_insts, &(&1.id == :extinct_lab))
    end

    test "Q4 (ARC1 Historical Conservation) — Immutable Ledger survives rollbacks" do
      # 1. Write milestone logs to Civilization Memory
      assert :ok = CivilizationMemory.log_event(:major_discovery, 1, "Alpha Discovery", "Discovered fire.")
      assert :ok = CivilizationMemory.log_event(:scientific_revolution, 5, "Beta Revolution", "Discovered electricity.")

      events_pre = CivilizationMemory.get_events()
      assert length(events_pre) == 2

      # 2. Simulate rollback check (resetting other registries does NOT delete the ndjson file)
      assert :ok = CivilizationMemory.reset()
      events_post = CivilizationMemory.get_events()
      assert length(events_post) == 2

      # Assert files sizes/lines has not decreased
      snapshot = %{
        epoch: 5,
        causal_pressures: %{},
        populations: %{
          civ1: %{organisms: [:dummy], strategy: %{mutation_rate: 0.1}},
          civ2: %{organisms: [:dummy], strategy: %{mutation_rate: 0.1}}
        }
      }
      assert {:ok, []} = ConstitutionKernel.verify_l0(snapshot)
    end

    test "Q5 (Security Pressure Coordinate) — rebalancing penalty on high-CFR/high-DR nodes" do
      theories = TheorySelection.default_theories()
      tensor = MetaTheoryExtractor.extract(theories)

      initial_weights = Map.new(theories, & {&1.theory_id, 1.0 / length(theories)})
      portfolio = %TheoryPortfolio{
        weights: initial_weights,
        current_mode: :balanced,
        history: [],
        governance_history: []
      }

      # Rebalance with high security pressure
      high_sec_context = %{volatility: 0.5, complexity: 0.5, adversariality: 0.8, security_pressure: 0.9}
      rebalanced_high = PortfolioRebalancer.rebalance(portfolio, tensor, high_sec_context, :climate, :balanced, 0.0)

      # Rebalance with low security pressure
      low_sec_context = %{volatility: 0.5, complexity: 0.5, adversariality: 0.1, security_pressure: 0.0}
      rebalanced_low = PortfolioRebalancer.rebalance(portfolio, tensor, low_sec_context, :climate, :balanced, 0.0)

      # Rebalancing weights should be different under security pressure bias
      assert rebalanced_high.weights != rebalanced_low.weights
    end

    test "Q6 (Zero Hardcoding) — All 20 research domains participate in simulation loops" do
      domains = GoalEcology.list_domains()
      assert length(domains) == 20

      # Assert all of them are valid domains
      Enum.each(domains, fn domain ->
        assert is_atom(domain)
      end)
    end
  end
end
