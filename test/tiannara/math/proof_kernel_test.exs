defmodule Tiannara.Math.ProofKernelTest do
  use ExUnit.Case, async: true
  alias Tiannara.Math.ProofKernel

  test "checks conjunction introduction and elimination" do
    p = {:atom, :P}
    q = {:atom, :Q}
    c = {:and, p, q}

    assert {:ok, result} =
      ProofKernel.check([p, q], c, [
        %{id: 1, rule: :assumption, proposition: p},
        %{id: 2, rule: :assumption, proposition: q},
        %{id: 3, rule: :and_intro, refs: [1, 2], proposition: c}
      ])

    assert result.status == :proven_under_assumptions
    assert result.checked_steps == 3
    assert result.external_reality_claim == :not_established
  end

  test "checks modus ponens" do
    p = {:atom, :P}
    q = {:atom, :Q}
    implication = {:imp, p, q}

    assert {:ok, _} =
      ProofKernel.check([implication, p], q, [
        %{id: 1, rule: :assumption, proposition: implication},
        %{id: 2, rule: :assumption, proposition: p},
        %{id: 3, rule: :imp_elim, refs: [1, 2], proposition: q}
      ])
  end

  test "refuses an invalid conclusion" do
    p = {:atom, :P}
    q = {:atom, :Q}

    assert {:error, :conclusion_not_derived} =
      ProofKernel.check([p], q, [
        %{id: 1, rule: :assumption, proposition: p}
      ])
  end

  test "refuses unsound implication introduction" do
    p = {:atom, :P}
    q = {:atom, :Q}

    assert {:error, {:invalid_step, 2, :unsupported_or_malformed_rule}} =
      ProofKernel.check([p], {:imp, p, q}, [
        %{id: 1, rule: :assumption, proposition: p},
        %{id: 2, rule: :imp_intro, refs: [1, 1], proposition: {:imp, p, p}}
      ])
  end

  test "reflexivity checks exact equality" do
    term = {:const, {:atom, :x}}

    assert {:ok, _} =
      ProofKernel.check([], {:eq, term, term}, [
        %{id: 1, rule: :reflexivity, proposition: {:eq, term, term}}
      ])

    other = {:const, {:atom, :y}}

    assert {:error, {:invalid_step, 1, :reflexivity_requires_identical_terms}} =
      ProofKernel.check([], {:eq, term, other}, [
        %{id: 1, rule: :reflexivity, proposition: {:eq, term, other}}
      ])
  end
end
