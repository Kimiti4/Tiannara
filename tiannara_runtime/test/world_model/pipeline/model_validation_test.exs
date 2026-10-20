defmodule TiannaraRuntime.WorldModel.Pipeline.ModelValidationTest do
  use ExUnit.Case, async: false

  alias TiannaraRuntime.WorldModel.Pipeline.ModelValidation
  alias TiannaraRuntime.WorldModel.ModelRegistry
  alias TiannaraRuntime.WorldModel.Ontology.{WorldModel, StateSpace}

  setup do
    ModelRegistry.reset_table()
    :ok
  end

  describe "validate_model/2" do
    test "returns metrics and transitions status" do
      {:ok, ss} = StateSpace.new(dimensions: 0, variable_order: [])
      {:ok, model} = WorldModel.new(name: "Test", domain: :physics, state_space: ss)
      {:ok, stored} = ModelRegistry.store_model(model)

      {:ok, metrics} = ModelValidation.validate_model(stored, %{})
      assert length(metrics) == 3

      {:ok, fetched} = ModelRegistry.get_latest_model(stored.model_id)
      assert fetched.status == :validated
    end
  end
end
