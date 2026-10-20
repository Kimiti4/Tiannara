defmodule TiannaraRuntime.WorldModel.Pipeline.ReplayPipelineTest do
  use ExUnit.Case, async: false

  alias TiannaraRuntime.WorldModel.Pipeline.ReplayPipeline
  alias TiannaraRuntime.WorldModel.ModelRegistry
  alias TiannaraRuntime.WorldModel.Ontology.{WorldModel, StateSpace}

  setup do
    ModelRegistry.reset_table()
    :ok
  end

  describe "replay_model/2" do
    test "fetches stored model" do
      {:ok, ss} = StateSpace.new(dimensions: 0, variable_order: [])
      {:ok, model} = WorldModel.new(name: "Test", domain: :physics, state_space: ss)
      {:ok, stored} = ModelRegistry.store_model(model)

      {:ok, fetched} = ReplayPipeline.replay_model(stored.model_id, stored.version)
      assert fetched.name == "Test"
      assert fetched.version == stored.version
    end

    test "returns error for missing model" do
      assert {:error, :not_found} = ReplayPipeline.replay_model("nonexistent", 1)
    end
  end

  describe "replay_pipeline/1" do
    test "returns model in pipeline results" do
      {:ok, ss} = StateSpace.new(dimensions: 0, variable_order: [])
      {:ok, model} = WorldModel.new(name: "Test", domain: :physics, state_space: ss)
      {:ok, stored} = ModelRegistry.store_model(model)

      {:ok, results} = ReplayPipeline.replay_pipeline(stored.model_id)
      assert length(results) == 1
      assert hd(results).stage == :replay_model
    end
  end
end
