defmodule TiannaraRuntime.WorldModel.Prediction.PredictionEngine do
  @moduledoc """
  Phase 17.4.9 — PredictionEngine: main orchestrator for the constitutional
  prediction pipeline. Delegates to ForecastGenerator, ConfidenceEngine,
  UncertaintyEngine, MathVerificationEngine, PredictionArchaeology, and
  PredictionRegistry.
  """
  @behaviour TiannaraRuntime.WorldModel.Prediction.Behaviours.PredictionBehaviour

  alias TiannaraRuntime.WorldModel.ModelRegistry
  alias TiannaraRuntime.WorldModel.Prediction.{
    Prediction, PredictionScenario, Forecast, ForecastVariable,
    ForecastGenerator, ConfidenceEngine, UncertaintyEngine,
    MathVerificationEngine, PredictionArchaeology, PredictionRegistry
  }

  @impl true
  @spec predict(String.t(), [String.t()], atom(), keyword()) ::
    {:ok, Prediction.t()} | {:error, term()}
  def predict(world_model_id, target_variable_names, horizon, opts \\ []) do
    with {:ok, world_model} <- ModelRegistry.get_latest_model(world_model_id),
         {:ok, wm} <- ensure_world_model_struct(world_model),
         fvs <- build_forecast_variables(target_variable_names, wm),
         {:ok, forecast} <- ForecastGenerator.generate(wm, fvs, horizon, opts),
         {:ok, confidence} <- ConfidenceEngine.compute(wm, forecast),
         {:ok, uncertainty} <- UncertaintyEngine.propagate(wm, forecast),
         {:ok, math_verification} <- MathVerificationEngine.verify_forecast(wm, forecast) do
      evidence_roots = Map.get(wm, :evidence_roots, [])

      prediction = %Prediction{
        world_model_id: world_model_id,
        world_model_version: Map.get(wm, :version, 1),
        model_fingerprint: Map.get(wm, :fingerprint),
        target_variables: fvs,
        horizon: horizon,
        assumptions: Keyword.get(opts, :assumptions, %{}),
        confidence: confidence,
        uncertainty: uncertainty,
        forecast: forecast,
        evidence_roots: evidence_roots,
        math_verification: math_verification,
        metadata: Keyword.get(opts, :metadata, %{})
      }

      {:ok, pred} = Prediction.new(
        world_model_id: prediction.world_model_id,
        world_model_version: prediction.world_model_version,
        model_fingerprint: prediction.model_fingerprint,
        target_variables: prediction.target_variables,
        horizon: prediction.horizon,
        assumptions: prediction.assumptions,
        confidence: prediction.confidence,
        uncertainty: prediction.uncertainty,
        forecast: prediction.forecast,
        evidence_roots: prediction.evidence_roots,
        math_verification: prediction.math_verification,
        metadata: prediction.metadata
      )

      fp = MathVerificationEngine.fingerprint(pred)
      pred_with_fp = %{pred | replay_fingerprint: fp}

      PredictionArchaeology.record_prediction(pred_with_fp)
      PredictionRegistry.store_prediction(pred_with_fp)
    end
  end

  @impl true
  @spec predict_scenario(String.t(), [String.t()], atom(), keyword(), map()) ::
    {:ok, PredictionScenario.t()} | {:error, term()}
  def predict_scenario(world_model_id, target_variable_names, horizon, opts, intervention) do
    with {:ok, world_model} <- ModelRegistry.get_latest_model(world_model_id),
         {:ok, wm} <- ensure_world_model_struct(world_model),
         modified_wm <- apply_intervention(wm, intervention),
         fvs <- build_forecast_variables(target_variable_names, modified_wm),
         {:ok, forecast} <- ForecastGenerator.generate(modified_wm, fvs, horizon, opts) do
      scenario = %PredictionScenario{
        name: Keyword.get(opts, :scenario_name, "scenario_#{horizon}"),
        assumptions: Keyword.get(opts, :assumptions, %{}),
        intervention: intervention,
        forecast: forecast,
        metadata: Keyword.get(opts, :metadata, %{})
      }

      {:ok, ensure_scenario_id(scenario)}
    end
  end

  @spec get_prediction(String.t()) :: {:ok, Prediction.t()} | {:error, :not_found}
  def get_prediction(prediction_id) do
    PredictionRegistry.get_prediction(prediction_id)
  end

  @spec replay_prediction(String.t()) :: {:ok, %{verified: boolean(), mismatches: [String.t()]}}
  def replay_prediction(prediction_id) do
    with {:ok, original} <- PredictionRegistry.get_prediction(prediction_id) do
      fp = MathVerificationEngine.fingerprint(original)
      verified = fp == original.replay_fingerprint

      PredictionArchaeology.record_replay(
        prediction_id,
        original.replay_fingerprint,
        fp,
        verified
      )

      {:ok, %{verified: verified, mismatches: if(verified, do: [], else: ["fingerprint_mismatch"]), fingerprint: fp}}
    end
  end

  defp build_forecast_variables(variable_names, %{variables: vars}) do
    Enum.map(variable_names, fn name ->
      case Enum.find(vars, fn v -> v.name == name or v.variable_id == name end) do
        nil -> %ForecastVariable{name: name}
        v -> %ForecastVariable{name: v.name, type: map_var_type(v.type)}
      end
    end)
  end

  defp build_forecast_variables(variable_names, _), do:
    Enum.map(variable_names, &%ForecastVariable{name: &1})

  defp map_var_type(:continuous), do: :continuous
  defp map_var_type(:discrete), do: :continuous
  defp map_var_type(:categorical), do: :categorical
  defp map_var_type(_), do: :continuous

  defp apply_intervention(wm, intervention) do
    case intervention do
      %{target_variable: target, set_value: {:fix, value}} ->
        current_state = Map.get(wm, :state_space, %{})
        new_defaults = Map.put(Map.get(current_state, :default_initial, %{}), target, value)
        new_state = Map.put(current_state, :default_initial, new_defaults)
        Map.put(wm, :state_space, new_state)
      _ ->
        wm
    end
  end

  defp ensure_world_model_struct(%_{} = wm), do: {:ok, wm}
  defp ensure_world_model_struct(wm) when is_map(wm) do
    struct(TiannaraRuntime.WorldModel.Ontology.WorldModel, wm)
    |> then(fn s ->
      if s.name && s.domain && s.state_space do
        {:ok, s}
      else
        {:error, "incomplete world model struct"}
      end
    end)
  end

  defp ensure_scenario_id(%PredictionScenario{scenario_id: nil} = s), do: %{s | scenario_id: PredictionScenario.compute_id(s)}
  defp ensure_scenario_id(%PredictionScenario{} = s), do: s
end
