defmodule Tiannara.Forecasting.SelectionTest do
  use ExUnit.Case, async: true

  alias Tiannara.Forecasting.Selection

  test "known denominator generalizes only to observed population" do
    r = Selection.analyze(%{population_size: 100, sample_size: 10})
    assert r.denominator_status == :known
    assert r.generalization_scope == :observed_population
  end

  test "unknown denominator is rejected for generalization, never silently used" do
    r = Selection.analyze(%{population_size: :unknown, sample_size: 3})
    assert r.denominator_status == :unknown
    assert r.detection_flags == [:flagged]
    assert {:error, :denominator_unknown} = Selection.select_from(r)
  end

  test "survivorship flag is raised even when observation is nominally random" do
    population = [
      %{id: 1, admitted?: true, mechanism: :survivorship},
      %{id: 2, admitted?: true, mechanism: :survivorship},
      %{id: 3, admitted?: false, mechanism: :survivorship}
    ]
    r = Selection.analyze(population)
    assert r.selection_mechanism == :survivorship
    assert r.denominator_status == :known
  end

  test "attrition without explicit mechanism reads as selected, never full generalization" do
    population = [
      %{id: 1, admitted?: true},
      %{id: 2, admitted?: true},
      %{id: 3, admitted?: false}
    ]
    r = Selection.analyze(population)
    assert r.selection_mechanism == :selected
    assert :observed_attrition in r.detection_flags
  end
end