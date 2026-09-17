defmodule TiannaraRuntime.SelfCompilationTest do
  use ExUnit.Case, async: false
  alias TiannaraRuntime.SelfCompilation.{
    RewriteEngine,
    RuleExtractor,
    RuleMutator,
    SafetyValidator,
    MetaOntologyGuard
  }

  describe "RuleExtractor" do
    test "extracts RRG rules with correct structure" do
      rules = RuleExtractor.extract(:rrg)

      assert is_list(rules)
      assert length(rules) > 0

      # Check rule structure
      first_rule = hd(rules)
      assert Map.has_key?(first_rule, :type)
      assert Map.has_key?(first_rule, :value)
      assert Map.has_key?(first_rule, :description)
    end

    test "extracts rules for all subsystems" do
      for subsystem <- [:rrg, :omce, :olef, :opc] do
        rules = RuleExtractor.extract(subsystem)
        assert is_list(rules)
        assert length(rules) > 0
      end
    end

    test "RRG rules contain expected parameter types" do
      rules = RuleExtractor.extract(:rrg)
      rule_types = Enum.map(rules, & &1.type)

      assert :psi_threshold in rule_types
      assert :novelty_injection_max in rule_types
      assert :recursion_regulation_threshold in rule_types
    end

    test "OMCE rules contain compression parameters" do
      rules = RuleExtractor.extract(:omce)
      rule_types = Enum.map(rules, & &1.type)

      assert :compression_ratio_aggressive in rule_types
      assert :compression_ratio_moderate in rule_types
    end
  end

  describe "RuleMutator" do
    test "mutates RRG psi_threshold within safe bounds" do
      rules = [%{type: :psi_threshold, value: 0.3, description: "test"}]

      mutated = RuleMutator.mutate(rules, :rrg, 0.1)

      assert length(mutated) == 1
      mutated_rule = hd(mutated)

      # Should be within safe range [0.2, 0.5]
      assert mutated_rule.value >= 0.2 and mutated_rule.value <= 0.5
    end

    test "mutates OLEF diffusion_rate within bounds" do
      rules = [%{type: :diffusion_rate, value: 0.1, description: "test"}]

      mutated = RuleMutator.mutate(rules, :olef, 0.2)

      mutated_rule = hd(mutated)
      assert mutated_rule.value >= 0.05 and mutated_rule.value <= 0.2
    end

    test "applies intensity scaling to mutations" do
      rules = [%{type: :psi_threshold, value: 0.3, description: "test"}]

      # Low intensity should produce smaller changes
      mutated_low = RuleMutator.mutate(rules, :rrg, 0.01)

      # High intensity should allow larger changes
      mutated_high = RuleMutator.mutate(rules, :rrg, 0.5)

      # Both should be valid (exact values are random, but both must be in range)
      assert_in_delta 0.3, hd(mutated_low).value, 0.05
      assert_in_delta 0.3, hd(mutated_high).value, 0.15
    end

    test "handles integer parameter mutations (OPC)" do
      rules = [%{type: :ast_optimization_level, value: 2, description: "test"}]

      mutated = RuleMutator.mutate(rules, :opc, 0.3)

      mutated_rule = hd(mutated)
      assert is_integer(mutated_rule.value)
      assert mutated_rule.value >= 0 and mutated_rule.value <= 3
    end

    test "preserves rule metadata during mutation" do
      original_rule = %{
        type: :psi_threshold,
        value: 0.3,
        description: "Critical Ψ stability threshold"
      }

      mutated = RuleMutator.mutate([original_rule], :rrg, 0.1)
      mutated_rule = hd(mutated)

      assert mutated_rule.type == original_rule.type
      assert mutated_rule.description == original_rule.description
    end
  end

  describe "SafetyValidator" do
    test "validates rules within safe parameter ranges" do
      rules = [
        %{type: :psi_threshold, value: 0.35},
        %{type: :novelty_injection_max, value: 0.15}
      ]

      assert {:ok, ^rules} = SafetyValidator.validate(rules, :rrg)
    end

    test "rejects rules with out-of-range parameters" do
      rules = [
        %{type: :psi_threshold, value: 0.8}  # Too high (max 0.5)
      ]

      assert {:error, {:parameter_out_of_range, _}} =
               SafetyValidator.validate(rules, :rrg)
    end

    test "accepts all valid RRG parameters" do
      rules = [
        %{type: :psi_threshold, value: 0.3},
        %{type: :novelty_injection_max, value: 0.15},
        %{type: :recursion_regulation_threshold, value: 0.7}
      ]

      assert {:ok, _} = SafetyValidator.validate(rules, :rrg)
    end

    test "validates OMCE compression ratios" do
      rules = [
        %{type: :compression_ratio_aggressive, value: 0.4}
      ]

      assert {:ok, _} = SafetyValidator.validate(rules, :omce)
    end

    test "rejects invalid compression ratio" do
      rules = [
        %{type: :compression_ratio_aggressive, value: 0.6}  # Too high (max 0.5)
      ]

      assert {:error, {:parameter_out_of_range, _}} =
               SafetyValidator.validate(rules, :omce)
    end
  end

  describe "MetaOntologyGuard" do
    test "allows valid rule types" do
      rules = [
        %{type: :psi_threshold, value: 0.3},
        %{type: :diffusion_rate, value: 0.1}
      ]

      assert :ok = MetaOntologyGuard.check_compliance(rules, :rrg)
    end

    test "rejects disallowed rule types" do
      rules = [
        %{type: :forbidden_parameter, value: 42}
      ]

      assert {:error, {:disallowed_rule_types, [:forbidden_parameter]}} =
               MetaOntologyGuard.check_compliance(rules, :rrg)
    end

    test "allows all standard RRG rule types" do
      rules = [
        %{type: :psi_threshold, value: 0.3},
        %{type: :novelty_injection_max, value: 0.15},
        %{type: :recursion_regulation_threshold, value: 0.7}
      ]

      assert :ok = MetaOntologyGuard.check_compliance(rules, :rrg)
    end

    test "allows all standard OPC rule types" do
      rules = [
        %{type: :ast_optimization_level, value: 2},
        %{type: :shader_cache_ttl, value: 300}
      ]

      assert :ok = MetaOntologyGuard.check_compliance(rules, :opc)
    end
  end

  describe "RewriteEngine" do
    setup do
      if pid = Process.whereis(RewriteEngine) do
        Process.monitor(pid)
        Process.exit(pid, :kill)
        receive do
          {:DOWN, _, :process, ^pid, _} -> :ok
        end
      end
      :ok
    end
    test "initializes with default state" do
      {:ok, pid} = RewriteEngine.start_link([])
      state = :sys.get_state(pid)

      assert state.total_compilations == 0
      assert state.success_rate == 1.0
      assert state.compilation_history == []
    end

    test "compiles RRG subsystem successfully" do
      {:ok, pid} = RewriteEngine.start_link([])

      result = GenServer.call(pid, {:compile, :rrg, 0.1, %{}})

      assert elem(result, 0) == :ok
      compilation = elem(result, 1)

      assert compilation.subsystem == :rrg
      assert compilation.status == :compiled
      assert Map.has_key?(compilation, :version)
      assert Map.has_key?(compilation, :timestamp)
    end

    test "rejects invalid subsystem" do
      {:ok, pid} = RewriteEngine.start_link([])

      result = GenServer.call(pid, {:compile, :invalid_subsystem, 0.1, %{}})

      assert elem(result, 0) == :error
      assert {:invalid_subsystem, :invalid_subsystem} = elem(result, 1)
    end

    test "rejects intensity below minimum" do
      {:ok, pid} = RewriteEngine.start_link([])

      result = GenServer.call(pid, {:compile, :rrg, 0.001, %{}})

      assert elem(result, 0) == :error
      assert {:intensity_too_low, 0.001} = elem(result, 1)
    end

    test "rejects intensity above maximum" do
      {:ok, pid} = RewriteEngine.start_link([])

      result = GenServer.call(pid, {:compile, :rrg, 0.8, %{}})

      assert elem(result, 0) == :error
      assert {:intensity_too_high, 0.8} = elem(result, 1)
    end

    test "prevents concurrent compilations of same subsystem" do
      {:ok, pid} = RewriteEngine.start_link([])

      # First compilation should succeed
      result1 = GenServer.call(pid, {:compile, :rrg, 0.1, %{}})
      assert elem(result1, 0) == :ok

      # Second compilation of same subsystem should fail
      result2 = GenServer.call(pid, {:compile, :rrg, 0.1, %{}})
      assert elem(result2, 0) == :error
      assert {:compilation_in_progress, :rrg} = elem(result2, 1)
    end

    test "tracks compilation statistics" do
      {:ok, pid} = RewriteEngine.start_link([])

      # Perform a compilation
      GenServer.call(pid, {:compile, :rrg, 0.1, %{}})

      {:ok, stats} = GenServer.call(pid, :get_stats)

      assert stats.total_compilations == 1
      assert_in_delta 1.0, stats.success_rate, 0.01
      assert length(stats.recent_history) == 1
    end

    test "updates success rate on compilation" do
      {:ok, pid} = RewriteEngine.start_link([])

      # Successful compilation
      GenServer.call(pid, {:compile, :rrg, 0.1, %{}})

      {:ok, stats} = GenServer.call(pid, :get_stats)

      # Success rate should remain high after successful compilation
      assert_in_delta 1.0, stats.success_rate, 0.1
    end

    test "compiles all valid subsystems" do
      {:ok, pid} = RewriteEngine.start_link([])

      for subsystem <- [:rrg, :omce, :olef, :opc] do
        result = GenServer.call(pid, {:compile, subsystem, 0.1, %{}})
        assert elem(result, 0) == :ok
      end

      {:ok, stats} = GenServer.call(pid, :get_stats)
      assert stats.total_compilations == 4
    end
  end
end
