defmodule Tiannara.Forecasting.Forecast do
  @moduledoc """
  The D2 immutable Forecast: a probabilistic, evidence-linked claim.

  A Forecast is constructed from a `ForecastRequest` (signals + evidence +
  base rate + context) and preserved as an immutable `Contracts.Forecast`.
  Probability and confidence are distinct. `UNKNOWN` probabilities are valid.

  Lifecycle:
      Forecast.new(request) → Forecast        (version 1)
      Forecast.version(forecast, updates)     → new immutable version (v+1)
      Forecast.validate(forecast)             → {:ok, _} | {:error, reason}

  Constitutional rules:
    - probabilities live in `[0,1]`, sum ≈ 1 (normalized), or are `:unknown`.
    - versioning appends; history is never overwritten.
    - an update keeps forecast-time information, never hindsight.
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
      # probabilities is the source of truth for the distribution when present
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
      is_nil(f.question) ->
        {:error, :missing_question}

      is_nil(f.outcomes) or f.outcomes == [] ->
        {:error, :missing_outcomes}

      not probability_ok?(f) ->
        {:error, :invalid_probabilities}

      not count_matches_outcomes?(f) ->
        {:error, :outcome_probability_mismatch}

      not distribution_ok?(f) ->
        {:error, :distribution_not_normalized}

      true ->
        {:ok, f}
    end
  end

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

  # ------------------------------------------------------------------
  # Probability integrity
  # ------------------------------------------------------------------

  defp probability_ok?(%Forecast{probabilities: :unknown}), do: true
  defp probability_ok?(%Forecast{probabilities: nil}), do: true

  defp probability_ok?(%Forecast{probabilities: probs}) do
    is_list(probs) and Enum.all?(probs, &valid_probability?/1)
  end

  defp valid_probability?(p), do: is_number(p) and finite?(p) and p >= 0 and p <= 1

  defp finite?(p) when is_integer(p), do: true
  defp finite?(p) when is_float(p), do: p - p == 0.0
  defp finite?(_), do: false

  defp distribution_ok?(%Forecast{probabilities: :unknown}), do: true
  defp distribution_ok?(%Forecast{probabilities: nil}), do: true

  defp distribution_ok?(%Forecast{probabilities: probs}) do
    is_list(probs) and abs(Enum.sum(probs) - 1.0) < 1.0e-6
  end

  defp count_matches_outcomes?(%Forecast{probabilities: p, outcomes: o})
       when is_list(p) and is_list(o) and p != [] and o != [] do
    length(p) == length(o)
  end

  defp count_matches_outcomes?(_), do: true

  @spec normalize_probs(term()) :: term()
  defp normalize_probs(:unknown), do: :unknown
  defp normalize_probs(nil), do: nil
  defp normalize_probs(other) when not is_list(other), do: other

  defp normalize_probs(probs) when is_list(probs) do
    # Only normalize already-in-bounds, finite values with nonzero total.
    # All-zeros are preserved so validate/1 flags :distribution_not_normalized;
    # a crash inside Constraints.normalize_to is avoided (else-clause matches
    # integer 0 only, not float 0.0).
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