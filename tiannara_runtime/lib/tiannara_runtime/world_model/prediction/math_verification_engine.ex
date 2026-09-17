defmodule TiannaraRuntime.WorldModel.Prediction.MathVerificationEngine do
  @moduledoc """
  Phase 17.4.8 — MathVerificationEngine: integrates prediction system with
  the Mathematics Subsystem's FormalVerificationEngine to verify mathematical
  consistency of forecasts.
  """
  alias TiannaraRuntime.WorldModel.Ontology.WorldModel
  alias TiannaraRuntime.WorldModel.Prediction.{Prediction, Forecast}

  @spec verify_forecast(WorldModel.t(), Forecast.t()) :: {:ok, String.t()} | {:error, String.t()}
  def verify_forecast(%WorldModel{model_id: model_id}, %Forecast{} = forecast) do
    target_id = forecast.forecast_id || model_id

    case TiannaraRuntime.Mathematics.FormalVerificationEngine.verify(
      target_id,
      "world_model_component",
      :structural,
      [:consistency, :stability],
      forecast: Forecast.canonicalize(forecast)
    ) do
      {:ok, result} ->
        hash = compute_verification_hash(forecast, result)
        {:ok, hash}
      {:error, reason} ->
        {:error, "Math verification failed: #{reason}"}
    end
  end

  @spec verify_prediction(Prediction.t()) :: {:ok, String.t()} | {:error, String.t()}
  def verify_prediction(%Prediction{forecast: forecast, world_model_id: wm_id} = prediction) do
    wm = build_minimal_model(wm_id, prediction)
    verify_forecast(wm, forecast)
  end

  @spec fingerprint(Prediction.t()) :: String.t()
  def fingerprint(%Prediction{} = prediction) do
    excluded = ~w(prediction_id archaeology_root created_at metadata replay_fingerprint)a

    canonical =
      prediction
      |> Map.from_struct()
      |> Map.drop(excluded)
      |> canonicalize_map()
      |> Jason.encode!()

    "fp_" <> (:crypto.hash(:sha256, canonical) |> Base.encode16(case: :lower))
  end

  @spec verify_fingerprint(Prediction.t(), String.t()) :: boolean()
  def verify_fingerprint(%Prediction{} = prediction, expected_fingerprint) do
    fingerprint(prediction) == expected_fingerprint
  end

  defp compute_verification_hash(%Forecast{} = forecast, _result) do
    raw = Forecast.canonicalize(forecast) |> Jason.encode!()
    "mv_" <> (:crypto.hash(:sha256, raw) |> Base.encode16(case: :lower))
  end

  defp build_minimal_model(wm_id, %Prediction{world_model_version: version}) do
    %WorldModel{
      model_id: wm_id,
      version: version || 1,
      name: "verification_model",
      domain: :mathematics,
      state_space: %{dimensions: 0, variable_order: []}
    }
  end

  defp canonicalize_map(%{__struct__: _} = struct) do
    struct
    |> Map.from_struct()
    |> Map.delete(:__struct__)
    |> Enum.map(fn {k, v} -> {to_string(k), canonicalize_value(v)} end)
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.into(%{})
  end

  defp canonicalize_map(map) when is_map(map) do
    map
    |> Enum.map(fn {k, v} -> {to_string(k), canonicalize_value(v)} end)
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.into(%{})
  end

  defp canonicalize_value(v) when is_map(v), do: canonicalize_map(v)
  defp canonicalize_value(v) when is_list(v), do: Enum.map(v, &canonicalize_value/1)
  defp canonicalize_value(v) when is_tuple(v), do: v |> Tuple.to_list() |> canonicalize_value()
  defp canonicalize_value(v) when is_atom(v), do: Atom.to_string(v)
  defp canonicalize_value(v), do: v
end
