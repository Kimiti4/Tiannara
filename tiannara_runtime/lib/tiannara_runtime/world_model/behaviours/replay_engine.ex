defmodule TiannaraRuntime.WorldModel.Behaviours.ReplayEngine do
  @moduledoc """
  Phase 17 — ReplayEngine behaviour.

  Defines the contract for deterministic replay of world model construction,
  predictions, interventions, and counterfactuals. Every operation must be
  reproducible from immutable artifacts alone, without trusting the runtime
  that originally produced the artifact.
  """

  @doc "Reconstruct a model from its evidence roots and builder configuration."
  @callback replay_model(model_id :: String.t(), version :: non_neg_integer()) ::
              {:ok, TiannaraRuntime.WorldModel.Ontology.WorldModel.t()}
              | {:error, String.t()}

  @doc "Reconstruct a prediction from its model, input state, and prediction config."
  @callback replay_prediction(prediction_id :: String.t()) ::
              {:ok, TiannaraRuntime.WorldModel.Ontology.Prediction.t()}
              | {:error, String.t()}

  @doc "Reconstruct an intervention result from its model and intervention spec."
  @callback replay_intervention(intervention_id :: String.t()) ::
              {:ok, TiannaraRuntime.WorldModel.Ontology.CounterfactualModel.t()}
              | {:error, String.t()}

  @doc "Reconstruct a counterfactual from its base model and intervention."
  @callback replay_counterfactual(counterfactual_id :: String.t()) ::
              {:ok, TiannaraRuntime.WorldModel.Ontology.CounterfactualModel.t()}
              | {:error, String.t()}

  @doc "Reconstruct the evolution of a model across versions."
  @callback replay_evolution(
              model_id :: String.t(),
              from_version :: non_neg_integer(),
              to_version :: non_neg_integer()
            ) ::
              {:ok, [map()]}
              | {:error, String.t()}

  @doc "Reconstruct the full pipeline execution for a model."
  @callback replay_pipeline(model_id :: String.t()) ::
              {:ok, [map()]}
              | {:error, String.t()}
end
