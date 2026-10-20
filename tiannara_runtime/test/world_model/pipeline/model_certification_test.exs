defmodule TiannaraRuntime.WorldModel.Pipeline.ModelCertificationTest do
  use ExUnit.Case, async: false

  alias TiannaraRuntime.WorldModel.Pipeline.ModelCertification
  alias TiannaraRuntime.WorldModel.ModelRegistry
  alias TiannaraRuntime.WorldModel.Ontology.{WorldModel, StateSpace}

  setup do
    ModelRegistry.reset_table()
    :ok
  end

  describe "certify_model/1" do
    test "issues certificate and transitions to operational" do
      {:ok, ss} = StateSpace.new(dimensions: 0, variable_order: [])
      {:ok, model} = WorldModel.new(name: "Test", domain: :physics, state_space: ss)
      {:ok, stored} = ModelRegistry.store_model(model)
      ModelRegistry.transition_status(stored.model_id, stored.version, :validated)

      {:ok, cert} = ModelCertification.certify_model(stored)
      assert cert.overall_status == :pass
      assert cert.model_id == stored.model_id
      assert length(cert.checks) == 6

      {:ok, fetched} = ModelRegistry.get_latest_model(stored.model_id)
      assert fetched.status == :operational
    end
  end
end
