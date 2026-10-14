defmodule Tiannara.CivilizationFitnessLineageTest do
  use ExUnit.Case, async: false

  alias Tiannara.OMCS.Engine, as: OMCS
  alias Tiannara.REL.CivilizationFitness

  test "lineage score path uses active OMCS lineage API with honest unavailable result" do
    unique = :erlang.unique_integer([:positive])
    parent = "fit_lineage_parent_#{unique}"

    assert :ok = OMCS.register_civilization(parent)

    for i <- 1..5 do
      assert :ok = OMCS.register_civilization("#{parent}_c#{i}", parent, :spawned)
    end

    # Contract the fitness module relies on: tree with a direct children list
    assert {:ok, %{children: children}} = OMCS.get_lineage(parent)
    assert length(children) == 5

    # calculate/1 traverses the lineage path without crashing for both a
    # registered civilization and an unknown one (no lineage evidence)
    unknown = "fit_lineage_unknown_#{unique}"

    for civ <- [parent, unknown] do
      score = CivilizationFitness.calculate(civ)
      assert score >= 0.0 and score <= 1.0
    end

    # Known structural contribution: 5 children saturate the lineage factor at
    # 1.0, contributing the full 0.15 lineage weight vs 0.0 for the unknown civ
    score_parent = CivilizationFitness.calculate(parent)
    score_unknown = CivilizationFitness.calculate(unknown)
    assert score_parent > score_unknown
  end
end
