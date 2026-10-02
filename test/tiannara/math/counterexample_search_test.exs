defmodule Tiannara.Math.CounterexampleSearchTest do
  use ExUnit.Case, async: true
  alias Tiannara.Math.CounterexampleSearch

  test "finds a concrete counterexample" do
    assert {:ok, result} =
      CounterexampleSearch.exhaustive(0..10 |> Enum.to_list(), fn x -> x < 5 end)

    assert result.status == :counterexample_found
    assert result.witness == 5
    assert result.tested_cases == 6
    assert result.global_proof == false
  end

  test "reports bounded non-falsification without claiming proof" do
    assert {:ok, result} =
      CounterexampleSearch.exhaustive([0, 1, 2, 3], fn x -> x * x >= 0 end)

    assert result.status == :no_counterexample_in_domain
    assert result.tested_cases == 4
    assert result.global_proof == false
    assert result.certification_eligible == false
  end

  test "rejects duplicate domain elements" do
    assert {:error, :duplicate_domain_element} =
      CounterexampleSearch.exhaustive([1, 1, 2], fn _ -> true end)
  end

  test "rejects non-boolean conjecture results" do
    assert {:error, :conjecture_must_return_boolean} =
      CounterexampleSearch.exhaustive([1], fn _ -> :unknown end)
  end

  test "bounds exhaustive search" do
    domain = Enum.to_list(1..1_000_001)
    assert {:error, :domain_too_large} =
      CounterexampleSearch.exhaustive(domain, fn _ -> true end)
  end
end
