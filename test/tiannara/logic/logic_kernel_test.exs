defmodule Tiannara.Logic.LogicKernelTest do
  use ExUnit.Case, async: true

  alias Tiannara.Logic.{Contradiction, Invariant, Rule, Transition, Complementarity}

  @moduletag :logic_kernel

  describe "validate/2 kernel existence (L-AT-1 surface)" do
    test "the six kernel functions exist with the authorized signatures" do
      for mod <- [Contradiction, Invariant, Rule, Transition, Complementarity] do
        assert {:module, ^mod} = Code.ensure_loaded(mod)
      end

      assert function_exported?(Contradiction, :detect, 2)
      assert function_exported?(Contradiction, :from_refutations, 1)
      assert function_exported?(Invariant, :check, 2)
      assert function_exported?(Rule, :evaluate, 2)
      assert function_exported?(Transition, :valid?, 3)
      assert function_exported?(Complementarity, :holds?, 2)
    end
  end

  describe "Contradiction.detect/2 symmetry (L-AT-2)" do
    test "detect is symmetric on a golden corpus" do
      golden = [
        {%{subject: :x, value: 10}, %{subject: :x, value: 20}, :contradiction},
        {%{subject: :x, value: 10}, %{subject: :x, value: 10}, :consistent},
        {%{subject: :x, value: "a"}, %{subject: :x, value: "b"}, :contradiction},
        {%{subject: :x, value: 1}, %{subject: :y, value: 1}, :unknown},
        {%{subject: nil, value: 1}, %{subject: :x, value: 1}, :unknown},
        {%{value: 1}, %{value: 2}, :unknown},
        {:not_a_claim, :other, :unknown}
      ]

      for {a, b, expected} <- golden do
        assert Contradiction.detect(a, b) == expected
        assert Contradiction.detect(b, a) == expected
      end
    end

    test "detect never fabricates :contradiction for structurally non-comparable claims" do
      assert Contradiction.detect(%{value: 1}, %{value: 2}) == :unknown
      assert Contradiction.detect(%{subject: :x}, %{subject: :x}) == :unknown
      assert Contradiction.detect(10, 20) == :unknown
    end
  end

  describe "Contradiction.from_refutations/1" do
    test "keeps only contradictions that detect/2 confirms" do
      refutations = [
        %{claim_a: %{subject: :x, value: 10}, claim_b: %{subject: :x, value: 20}},
        %{claim_a: %{subject: :x, value: 10}, claim_b: %{subject: :x, value: 10}},
        {%{subject: :y, value: 1}, %{subject: :z, value: 2}},
        :not_a_refutation,
        %{claim_a: %{subject: :w, value: 1}}
      ]

      contradictions = Contradiction.from_refutations(refutations)

      assert length(contradictions) == 1
      assert hd(contradictions).type == :direct_contradiction
      assert hd(contradictions).subject == :x
      assert hd(contradictions).claim_a.value == 10
      assert hd(contradictions).claim_b.value == 20
    end
  end

  describe "Invariant.check/2 collect-all semantics (L-AT-5 kernel)" do
    test "accepts a constitutional arity-0 probe (Tiannara.Constitution.Invariant shape)" do
      probe = fn -> :ok end
      assert Invariant.check(probe, %{}) == :ok
      assert Invariant.check(fn -> {:error, :violated} end, %{}) == {:violation, :violated}
      assert Invariant.check(%{check: probe}, %{}) == :ok
      assert Invariant.check(%{predicate: probe}, %{}) == :ok
    end
    test "single passing invariant returns :ok" do
      invariant = fn snapshot -> snapshot.ok == true end
      assert Invariant.check(invariant, %{ok: true}) == :ok
      assert Invariant.check(%{check: invariant}, %{ok: true}) == :ok
      assert Invariant.check(%{predicate: invariant}, %{ok: true}) == :ok
    end

    test "single failing invariant returns structured {:violation, detail}" do
      assert Invariant.check(fn _ -> false end, %{}) == {:violation, :assertion_failed}
      assert Invariant.check(fn _ -> {:violation, :out_of_bounds} end, %{}) ==
               {:violation, :out_of_bounds}

      assert Invariant.check(fn _ -> {:error, :probe_raised} end, %{}) ==
               {:violation, :probe_raised}
    end

    test "check_all collects every violation, never first-fail" do
      invariants = [
        fn _ -> :ok end,
        fn _ -> {:violation, :a} end,
        fn _ -> {:violation, :b} end
      ]

      assert {:violations, details} = Invariant.check_all(invariants, %{})
      assert Enum.sort(details) == Enum.sort([:a, :b])
    end

    test "check_all returns :ok when nothing fails" do
      assert Invariant.check_all([fn _ -> true end, fn _ -> :ok end], %{}) == :ok
    end
  end

  describe "Rule.evaluate/2" do
    test "single fun predicate" do
      assert Rule.evaluate(%{fun: fn f -> f.x > 0 end}, %{x: 5}) == :pass
      assert Rule.evaluate(%{fun: fn f -> f.x > 0 end}, %{x: -1}) == :fail
    end

    test "conjunction of conditions" do
      rule = %{conditions: [fn f -> f.x > 0 end, fn f -> f.y > 0 end]}
      assert Rule.evaluate(rule, %{x: 1, y: 2}) == :pass
      assert Rule.evaluate(rule, %{x: 1, y: -1}) == :fail
    end

    test "missing required facts are :undetermined, never pass/fail" do
      rule = %{requires: [:x, :y], conditions: [fn f -> f.x > 0 end, fn f -> f.y > 0 end]}
      assert Rule.evaluate(rule, %{x: 1}) == :undetermined
      assert Rule.evaluate(rule, %{x: 1, y: 2}) == :pass
    end

    test "predicate expressing :undetermined is preserved" do
      rule = %{fun: fn %{subject: :x} -> :undetermined; _ -> :pass end}
      assert Rule.evaluate(rule, %{subject: :x}) == :undetermined
      assert Rule.evaluate(rule, %{subject: :y}) == :pass
    end

    test "unsupported rules are :undetermined" do
      assert Rule.evaluate(:nonsense, %{}) == :undetermined
    end
  end

  describe "Transition.valid?/3" do
    test "single-edge map form" do
      t = %{from: :detected, allowed: [:investigating, :dismissed]}
      assert Transition.valid?(t, :detected, :investigating)
      assert Transition.valid?(t, :detected, :dismissed)
      refute Transition.valid?(t, :detected, :resolved)
      refute Transition.valid?(t, :detected, :detected)
    end

    test "equality map form" do
      t = %{from: :a, to: :b}
      assert Transition.valid?(t, :a, :b)
      refute Transition.valid?(t, :a, :a)
    end

    test "transition-table map form" do
      table = %{detected: [:investigating, :dismissed], investigating: [:dismissed]}
      assert Transition.valid?(table, :detected, :investigating)
      refute Transition.valid?(table, :detected, :resolved)
      refute Transition.valid?(table, :unknown, :anything)
    end

    test "rejects garbage input" do
      refute Transition.valid?(nil, :a, :b)
      refute Transition.valid?(:nope, :a, :b)
    end
  end

  describe "L-AT-3: constitutional registry probe resolves via the kernel-backed Audit" do
    test ":no_contradiction_silently_discarded probe passes (registry.ex:118 no longer raises)" do
      invariant =
        Tiannara.Constitution.Registry.default_invariants()
        |> Enum.find(&(&1.id == :no_contradiction_silently_discarded))

      assert invariant != nil
      assert invariant.probe.() == :ok
    end

    test "Audit.find_contradictions/1 routes claim edges through the kernel and detects value conflicts" do
      alias Tiannara.Graph.{InMemory, Audit}

      g = InMemory.new()
      g = InMemory.add_node(g, :s1, %{})
      g = InMemory.add_node(g, :s2, %{})
      g = InMemory.add_node(g, :x, %{})
      {:ok, g} = InMemory.add_edge(g, :c1, :s1, :x, :claims, %{quantity: :x, value: 1})
      {:ok, g} = InMemory.add_edge(g, :c2, :s2, :x, :claims, %{quantity: :x, value: 2})

      [c] = Audit.find_contradictions(g)
      assert c.type == :contradiction
      assert c.subject == :x
      assert c.claim_a.value == 1
      assert c.claim_b.value == 2
    end

    test "Audit.find_contradictions/1 returns empty for consistent claims" do
      alias Tiannara.Graph.{InMemory, Audit}

      g = InMemory.new()
      g = InMemory.add_node(g, :s1, %{})
      g = InMemory.add_node(g, :x, %{})
      {:ok, g} = InMemory.add_edge(g, :c1, :s1, :x, :claims, %{quantity: :x, value: 5})

      assert Audit.find_contradictions(g) == []
    end
  end

  describe "Complementarity.holds?/2" do
    test "complementary claims in a consistent context" do
      assert Complementarity.holds?(
               {%{subject: :temperature, value: 20}, %{subject: :pressure, value: 1}},
               %{pressure: 1}
             )
    end

    test "falsified claim is not complementary" do
      refute Complementarity.holds?(
               {%{subject: :temperature, value: 20}, %{subject: :pressure, value: 1}},
               %{temperature: 100}
             )
    end

    test "contradicting pair is not complementary" do
      refute Complementarity.holds?(
               {%{subject: :x, value: 1}, %{subject: :x, value: 2}},
               %{}
             )
    end

    test "map-form pair" do
      assert Complementarity.holds?(
               %{a: %{subject: :x, value: 1}, b: %{subject: :y, value: 2}},
               %{}
             )
    end

    test "garbage returns false" do
      refute Complementarity.holds?(:nope, %{})
    end
  end
end