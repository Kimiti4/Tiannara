defmodule Tiannara.Forecasting.Forecast do
  @moduledoc """
  The D2 immutable Forecast: a probabilistic, evidence-linked claim.

  Validation is intentionally stricter than construction. Construction can create
  a candidate record; registry acceptance requires semantic integrity.
  """

  alias Tiannara.Forecasting.Contracts.{Forecast, ForecastRequest}
  alias Tiannara.Constraints

  @type t :: Forecast.t()

  @spec new(map() | ForecastRequest.t()) :: Forecast.t()
  def new(attrs) when is_map(attrs) or is_list(attrs) do
    m = Map.new(attrs)
    now = Map.get(m, :created_at) || DateTime.utc_now()
    probs = normalize_probs(Map.get(m, :probabilities))

    %Forecast{
      id: Map.get(m, :id) || Tiannara.Executive.Types.new_id(),
      question: Map.get(m, :question),
      probability: Map.get(m, :probability),
      distribution: Map.get(m, :distribution) || probs,
      uncertainty: Map.get(m, :uncertainty),
      evidence_id: Map.get(m, :evidence_id),
      created_at: now,
      models: Map.get(m, :models, []),
      disagreement: Map.get(m, :disagreement),
      lineage: Map.get(m, :lineage, []),
      event: Map.get(m, :event),
      outcomes: Map.get(m, :outcomes),
      horizon: Map.get(m, :horizon),
      forecast_version: Map.get(m, :forecast_version, 1),
      signal_refs: Map.get(m, :signal_refs, []),
      evidence_refs: Map.get(m, :evidence_refs, []),
      base_rate_ref: Map.get(m, :base_rate_ref),
      model_ref: Map.get(m, :model_ref),
      assumptions: Map.get(m, :assumptions, []),
      unknowns: Map.get(m, :unknowns, []),
      probabilities: probs,
      confidence: Map.get(m, :confidence),
      context: Map.get(m, :context),
      regime: Map.get(m, :regime),
      provenance: Map.get(m, :provenance)
    }
  end

  @spec validate(Forecast.t()) :: {:ok, Forecast.t()} | {:error, term()}
  def validate(%Forecast{} = f) do
    cond do
      is_nil(f.question) or not is_binary(f.question) or String.trim(f.question) == "" ->
        {:error, :missing_question}

      is_nil(f.outcomes) or f.outcomes == [] ->
        {:error, :missing_outcomes}

      not unique_outcomes?(f.outcomes) ->
        {:error, :duplicate_outcomes}

      not probability_ok?(f) ->
        {:error, :invalid_probabilities}

      not count_matches_outcomes?(f) ->
        {:error, :outcome_probability_mismatch}

      not distribution_ok?(f) ->
        {:error, :distribution_not_normalized}

      not confidence_ok?(f.confidence) ->
        {:error, :invalid_confidence}

      not horizon_ok?(f.horizon) ->
        {:error, :invalid_horizon}

      not version_ok?(f.forecast_version) ->
        {:error, :invalid_forecast_version}

      not created_at_ok?(f.created_at) ->
        {:error, :invalid_created_at}

      not provenance_ok?(f.provenance) ->
        {:error, :invalid_provenance}

      not temporal_cutoff_ok?(f) ->
        {:error, :temporal_cutoff_violation}

      true ->
        {:ok, f}
    end
  end

  def validate(_), do: {:error, :forecast_record_required}

  @spec version(Forecast.t(), map() | Keyword.t()) :: Forecast.t()
  def version(%Forecast{} = f, updates) do
    u = Map.new(updates)
    previous_id = f.id

    new(f
        |> Map.from_struct()
        |> Map.drop([:id])
        |> Map.put(:created_at, DateTime.utc_now())
        |> Map.put(:forecast_version, (f.forecast_version || 1) + 1)
        |> Map.put(:lineage, [previous_id | f.lineage])
        |> Map.merge(u))
  end

  defp probability_ok?(%Forecast{probabilities: :unknown}), do: true
  defp probability_ok?(%Forecast{probabilities: nil}), do: true
  defp probability_ok?(%Forecast{probabilities: probs}) do
    is_list(probs) and probs != [] and Enum.all?(probs, &valid_probability?/1)
  end

  defp valid_probability?(p), do: is_number(p) and finite?(p) and p >= 0 and p <= 1
  defp finite?(p) when is_integer(p), do: true
  defp finite?(p) when is_float(p), do: p - p == 0.0
  defp finite?(_), do: false

  defp distribution_ok?(%Forecast{probabilities: p}) when p in [:unknown, nil], do: true
  defp distribution_ok?(%Forecast{probabilities: p}) do
    is_list(p) and abs(Enum.sum(p) - 1.0) < 1.0e-6
  end

  defp count_matches_outcomes?(%Forecast{probabilities: p, outcomes: o})
       when is_list(p) and is_list(o) and p != [] and o != [] do
    length(p) == length(o)
  end
  defp count_matches_outcomes?(_), do: true

  defp unique_outcomes?(outcomes) when is_list(outcomes), do: length(outcomes) == length(Enum.uniq(outcomes))
  defp unique_outcomes?(_), do: false

  defp confidence_ok?(nil), do: true
  defp confidence_ok?(value), do: is_number(value) and finite?(value) and value >= 0 and value <= 1

  defp horizon_ok?(nil), do: true
  defp horizon_ok?(value) when is_integer(value), do: value >= 0
  defp horizon_ok?(%DateTime{}), do: true
  defp horizon_ok?(_), do: false

  defp version_ok?(value), do: is_integer(value) and value >= 1

  defp created_at_ok?(%DateTime{}), do: true
  defp created_at_ok?(_), do: false

  defp provenance_ok?(nil), do: true
  defp provenance_ok?(map) when is_map(map) do
    case Map.get(map, :evidence_class, Map.get(map, "evidence_class")) do
      nil -> true
      value when value in [:real, :simulated, :unknown] -> true
      _ -> false
    end
  end
  defp provenance_ok?(_), do: false

  defp temporal_cutoff_ok?(%Forecast{created_at: created_at, context: context})
       when is_map(context) do
    cutoff = Map.get(context, :data_cutoff) || Map.get(context, "data_cutoff")
    case cutoff do
      nil -> true
      %DateTime{} = dt -> DateTime.compare(dt, created_at) != :gt
      _ -> false
    end
  end
  defp temporal_cutoff_ok?(_), do: true

  @spec normalize_probs(term()) :: term()
  defp normalize_probs(:unknown), do: :unknown
  defp normalize_probs(nil), do: nil
  defp normalize_probs(other) when not is_list(other), do: other

  defp normalize_probs(probs) when is_list(probs) do
    total =
      try do
        Enum.reduce(probs, 0.0, &+/2)
      rescue
        _ -> 0.0
      end

    if all_valid_probability?(probs) and total > 0.0 do
      case Constraints.normalize_probabilities(probs) do
        {:ok, normalized, _} -> normalized
        {:error, _} -> probs
      end
    else
      probs
    end
  end

  defp all_valid_probability?(probs), do: Enum.all?(probs, &valid_probability?/1)
end
