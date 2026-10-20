defmodule TiannaraRuntime.Mathematics.RewriteEngineTest do
  @moduledoc "Phase 16.X.3 — Rewrite Engine tests: create_rule, create_rule_set, apply_rules, budget, logging, replay."
  use ExUnit.Case, async: true

  alias TiannaraRuntime.Mathematics.RewriteEngine
  alias TiannaraRuntime.Mathematics.SymbolicEngine
  alias TiannaraRuntime.Mathematics.Ontology.{RewriteStep, RewriteLog}

  # ---------------------------------------------------------------------------
  # create_rule
  # ---------------------------------------------------------------------------

  describe "create_rule/3" do
    test "creates a rule with pattern and replacement" do
      assert {:ok, rule} = RewriteEngine.create_rule("?x", "?x")
      assert rule.pattern == "?x"
      assert rule.replacement == "?x"
      assert rule.guard == nil
    end

    test "creates a rule with guard" do
      assert {:ok, rule} = RewriteEngine.create_rule("?x", "?x", "true")
      assert rule.guard == "true"
    end

    test "rejects empty pattern" do
      assert {:error, _} = RewriteEngine.create_rule("", "x")
    end

    test "rejects empty replacement" do
      assert {:error, _} = RewriteEngine.create_rule("x", "")
    end
  end

  # ---------------------------------------------------------------------------
  # create_rule_set
  # ---------------------------------------------------------------------------

  describe "create_rule_set/3" do
    test "creates a ruleset with rules" do
      {:ok, r1} = RewriteEngine.create_rule("?x", "?x")
      {:ok, r2} = RewriteEngine.create_rule("?y", "?y")
      assert {:ok, rs} = RewriteEngine.create_rule_set("test", [r1, r2])
      assert rs.id == "test"
      assert length(rs.rules) == 2
    end

    test "rejects empty id" do
      {:ok, r} = RewriteEngine.create_rule("?x", "?x")
      assert {:error, _} = RewriteEngine.create_rule_set("", [r])
    end

    test "rejects empty rules list" do
      assert {:error, _} = RewriteEngine.create_rule_set("test", [])
    end
  end

  # ---------------------------------------------------------------------------
  # apply_rules (expr first, then ruleset, then opts)
  # ---------------------------------------------------------------------------

  describe "apply_rules/3" do
    test "applies matching rule to expression" do
      {:ok, rule} = RewriteEngine.create_rule("5", "10")
      {:ok, rs} = RewriteEngine.create_rule_set("test", [rule])
      {:ok, expr} = SymbolicEngine.constant(5)

      assert {:ok, result, _log} = RewriteEngine.apply_rules(expr, rs)
      assert result.type == :constant
    end

    test "exhausting budget returns {:error, _}" do
      # Self-matching rule that will cause an infinite loop
      {:ok, rule} = RewriteEngine.create_rule("_", "?x")
      {:ok, rs} = RewriteEngine.create_rule_set("loop_test", [rule])
      {:ok, expr} = SymbolicEngine.constant(1)

      assert {:error, _reason} = RewriteEngine.apply_rules(expr, rs, budget: 1)
    end

    test "no-match leaves expression and returns log" do
      {:ok, rule} = RewriteEngine.create_rule("999", "0")
      {:ok, rs} = RewriteEngine.create_rule_set("no_match", [rule])
      {:ok, expr} = SymbolicEngine.constant(1)

      assert {:ok, ^expr, steps} = RewriteEngine.apply_rules(expr, rs)
      assert is_list(steps)
      assert steps == []
    end
  end

  # ---------------------------------------------------------------------------
  # validate_log
  # ---------------------------------------------------------------------------

  describe "validate_log/1" do
    test "validates a well-formed log" do
      {:ok, expr_before} = SymbolicEngine.constant(5)
      {:ok, expr_after} = SymbolicEngine.constant(10)
      {:ok, step} = RewriteStep.new(0, "identity", expr_before, expr_after)
      {:ok, log} = RewriteLog.new([step])

      assert :ok = RewriteEngine.validate_log(log)
    end

    test "rejects log with non-sequential steps" do
      {:ok, expr_before} = SymbolicEngine.constant(5)
      {:ok, expr_after} = SymbolicEngine.constant(10)
      {:ok, s1} = RewriteStep.new(0, "r1", expr_before, expr_after)
      {:ok, s2} = RewriteStep.new(2, "r2", expr_after, expr_before)
      {:ok, log} = RewriteLog.new([s1, s2])

      assert {:error, _} = RewriteEngine.validate_log(log)
    end

    test "rejects empty log" do
      assert {:error, _} = RewriteLog.new([])
    end
  end

  # ---------------------------------------------------------------------------
  # replay_rewrites
  # ---------------------------------------------------------------------------

  describe "replay_rewrites/3" do
    test "reapplies rules to produce same result" do
      {:ok, rule} = RewriteEngine.create_rule("42", "0")
      {:ok, rs} = RewriteEngine.create_rule_set("replay", [rule])
      {:ok, expr} = SymbolicEngine.constant(42)

      assert {:ok, result, _log} = RewriteEngine.replay_rewrites(expr, rs)
      assert result.type == :constant
    end

    test "replay with non-matching rules returns original" do
      {:ok, rule} = RewriteEngine.create_rule("999", "0")
      {:ok, rs} = RewriteEngine.create_rule_set("replay_nomatch", [rule])
      {:ok, expr} = SymbolicEngine.constant(1)

      assert {:ok, ^expr, _log} = RewriteEngine.replay_rewrites(expr, rs)
    end
  end

  # ---------------------------------------------------------------------------
  # Utility
  # ---------------------------------------------------------------------------

  describe "default_budget/0" do
    test "returns positive integer" do
      assert RewriteEngine.default_budget() > 0
    end
  end

  describe "budget_remaining?/1" do
    test "returns true for positive budget" do
      assert RewriteEngine.budget_remaining?(1)
    end

    test "returns false for zero budget" do
      refute RewriteEngine.budget_remaining?(0)
    end
  end
end
