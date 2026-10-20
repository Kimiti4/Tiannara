defmodule TiannaraRuntime.WorldModel.Pipeline.ModelEvolutionTest do
  use ExUnit.Case, async: false

  alias TiannaraRuntime.WorldModel.Pipeline.ModelEvolution
  alias TiannaraRuntime.WorldModel.ModelRegistry
  alias TiannaraRuntime.WorldModel.Ontology.{WorldModel, StateSpace}

  setup do
    ModelRegistry.reset_table()
    :ok
  end

  describe "evolve_model/2" do
    test "creates new version with updated evidence roots" do
      {:ok, ss} = StateSpace.new(dimensions: 0, variable_order: [])
      {:ok, model} = WorldModel.new(name: "Test", domain: :physics, state_space: ss, evidence_roots: ["root_a"])
      {:ok, stored} = ModelRegistry.store_model(model)

      {:ok, evolved} = ModelEvolution.evolve_model(stored, %{evidence_root: "root_b"})
      assert evolved.evidence_roots == ["root_a", "root_b"]
      assert evolved.version == 2
      assert evolved.status == :draft
    end
  end
end
