defmodule TiannaraRuntime.WorldModel.Counterfactual.BranchGenerator do
  @moduledoc """
  Phase 17.5.3 — BranchGenerator: generates deterministic alternative world
  branches from interventions on certified world models.
  """
  alias TiannaraRuntime.WorldModel.Ontology.WorldModel
  alias TiannaraRuntime.WorldModel.Counterfactual.{Intervention, DivergencePoint, BranchNode}

  @spec generate(WorldModel.t(), Intervention.t(), keyword()) ::
    {:ok, BranchNode.t(), DivergencePoint.t()} | {:error, String.t()}
  def generate(%WorldModel{state_space: ss} = world_model, intervention, opts \\ []) do
    divergence_step = Keyword.get(opts, :divergence_step, 0)
    state = Map.get(ss, :default_initial, %{})

    intervention =
      if is_nil(intervention.intervention_id) do
        %{intervention | intervention_id: Intervention.compute_id(intervention)}
      else
        intervention
      end

    with {:ok, dp} <- DivergencePoint.new(
           parent_model_id: world_model.model_id,
           step: divergence_step,
           state: state,
           intervention: intervention,
           description:
             "Divergence at step #{divergence_step} via #{intervention.type}:#{intervention.target}"
         ),
         {:ok, bn} <- BranchNode.new(
           divergence: dp,
           depth: 0,
           metadata: %{model_id: world_model.model_id, intervention_id: intervention.intervention_id}
         ) do
      {:ok, bn, dp}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec generate_nested(WorldModel.t(), [Intervention.t()]) ::
    {:ok, [BranchNode.t()]} | {:error, String.t()}
  def generate_nested(%WorldModel{} = world_model, interventions) do
    {branches, _last_dp} =
      Enum.reduce(interventions, {[], nil}, fn intervention, {acc, _prev_dp} ->
        case generate(world_model, intervention) do
          {:ok, bn, dp} -> {[bn | acc], dp}
          {:error, _} = err -> throw(err)
        end
      end)

    {:ok, Enum.reverse(branches)}
  rescue
    e -> e
  end
end
