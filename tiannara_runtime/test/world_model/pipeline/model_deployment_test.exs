defmodule TiannaraRuntime.WorldModel.Pipeline.ModelDeploymentTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.WorldModel.Pipeline.ModelDeployment
  alias TiannaraRuntime.WorldModel.Ontology.{WorldModel, StateSpace}

  describe "deploy_model/1" do
    test "returns deployed" do
      {:ok, ss} = StateSpace.new(dimensions: 0, variable_order: [])
      {:ok, model} = WorldModel.new(name: "Test", domain: :physics, state_space: ss)
      assert {:ok, :deployed} = ModelDeployment.deploy_model(model)
    end
  end
end
