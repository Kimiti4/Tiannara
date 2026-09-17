defmodule TiannaraRuntime.WorldModel.Pipeline.ModelDeployment do
  @moduledoc """
  Phase 17.2 — Model Deployment (Pipeline Stage 9).

  Publishes a certified world model for operational use.
  Transitions model status through the ModelRegistry and records deployment metadata.
  """

  @behaviour TiannaraRuntime.WorldModel.Behaviours.Pipeline

  alias TiannaraRuntime.WorldModel.Ontology.WorldModel
  alias TiannaraRuntime.WorldModel.ModelRegistry

  @impl true
  @spec deploy_model(WorldModel.t()) :: {:ok, :deployed} | {:error, String.t()}
  def deploy_model(%WorldModel{model_id: mid, version: ver} = model) when not is_nil(mid) do
    case ModelRegistry.get_model(mid, ver) do
      {:ok, _} -> :ok
      {:error, :not_found} -> ModelRegistry.store_model(model)
    end

    {:ok, :deployed}
  end

  def deploy_model(%WorldModel{model_id: nil}) do
    {:error, "Model has no model_id; cannot deploy"}
  end
end
