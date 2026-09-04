defmodule Tiannara.Forecasting.SignalQuality do
  @moduledoc """
  Multi-dimensional evaluation of signal quality.

  Quality is NEVER collapsed into a single magic score alone: the raw dimensions
  remain available. Each dimension is scored 0..1 or `:unknown` when evidence is
  insufficient. `:unknown` is distinct from "measured and low".

  Dimensions (per EFDI D1 Signal Quality contract):

    - reliability    — source reliability + any assessed reliability
    - recency        — exponential time-decay of freshness
    - completeness   — ratio of populated key fields
    - measurement    — quality of the measurement-uncertainty mode
    - independence   — independence from correlated signals (scored, not the
                       correlation itself)
    - persistence    — how consistently the signal persists over time
    - validity       — contextual/regime validity

  All functions are pure and deterministic (same inputs → same outputs). No state.
  """

  alias Tiannara.Forecasting.Signal

  defstruct [
    :signal_id,
    :reliability,
    :recency,
    :completeness,
    :measurement,
    :independence,
    :persistence,
    :validity,
    :aggregate_score,
    :dimensions_assessed,
    :dimensions_unknown,
    :assessed_at
  ]

  @type t :: %__MODULE__{}

  @default_config %{
    reliability: 0.30,
    recency: 0.15,
    completeness: 0.10,
    measurement: 0.10,
    independence: 0.15,
    persistence: 0.10,
    validity: 0.10,
    recency_half_life_hours: 24.0
  }

  @doc "Evaluates a signal's quality. `now` defaults to `DateTime.utc_now/0`."
  @spec evaluate(Signal.t(), DateTime.t() | nil) :: t()
  def evaluate(%Signal{} = signal, now \\ nil) do
    at = now || DateTime.utc_now()
    cfg = config()

    reliability = evaluate_reliability(signal)
    recency = evaluate_recency(signal, at, cfg)
    completeness = evaluate_completeness(signal)
    measurement = evaluate_measurement(signal)
    independence = evaluate_independence(signal)
    persistence = evaluate_persistence(signal)
    validity = evaluate_validity(signal)

    dimensions = [
      reliability,
      recency,
      completeness,
      measurement,
      independence,
      persistence,
      validity
    ]

    weights =
      [cfg.reliability, cfg.recency, cfg.completeness, cfg.measurement,
       cfg.independence, cfg.persistence, cfg.validity]

    assessed = count_assessed(dimensions)
    unknown = count_unknown(dimensions)

    aggregate =
      if assessed == 0 do
        :unknown
      else
        total_weight = dimensions |> Enum.zip(weights) |> Enum.reduce(0.0, fn
          ({:unknown, _}, acc) -> acc
          ({score, w}, acc) -> acc + (score * w)
        end)
        |> safe_div(ensure_weight_sum(weights))

        clamp01(total_weight)
      end

    %__MODULE__{
      signal_id: signal.id,
      reliability: reliability,
      recency: recency,
      completeness: completeness,
      measurement: measurement,
      independence: independence,
      persistence: persistence,
      validity: validity,
      aggregate_score: aggregate,
      dimensions_assessed: assessed,
      dimensions_unknown: unknown,
      assessed_at: at
    }
  end

  @doc "Source reliability, 0..1, or `:unknown` if no reliability is available."
  @spec evaluate_reliability(Signal.t()) :: float() | :unknown
  def evaluate_reliability(%Signal{source_reliability: sr} = s) do
    cond do
      is_number(sr) and sr >= 0 and sr <= 1 ->
        # blend source reliability with any assessed per-signal reliability
        case s.reliability do
          r when is_number(r) and r >= 0 and r <= 1 -> (sr + r) / 2.0
          _ -> sr
        end

      is_number(s.reliability) and s.reliability >= 0 and s.reliability <= 1 ->
        s.reliability

      is_number(sr) ->
        clamp01(sr)

      true ->
        :unknown
    end
  end

  @doc "Recency via exponential decay; `:unknown` if timestamp is invalid."
  @spec evaluate_recency(Signal.t(), DateTime.t(), map()) :: float() | :unknown
  def evaluate_recency(%Signal{timestamp: ts}, now, cfg) when is_struct(ts, DateTime) do
    half_life_s = (cfg.recency_half_life_hours || 24.0) * 3600.0
    age_s = max(DateTime.diff(now, ts), 0)
    scale = :math.pow(0.5, age_s / half_life_s)
    clamp01(scale)
  end

  def evaluate_recency(_signal, _now, _cfg), do: :unknown

  @doc "Completeness = populated key fields / total key fields, 0..1."
  @spec evaluate_completeness(Signal.t()) :: float()
  def evaluate_completeness(%Signal{} = s) do
    keys = [
      :source, :observation, :observation_ref, :observation_type,
      :timestamp, :provenance, :domain, :context
    ]

    populated = Enum.count(keys, fn k -> not is_nil(Map.get(s, k)) end)
    populated / length(keys)
  end

  @doc "Measurements uncertainty mode quality; `:unknown` if no measurement metadata."
  @spec evaluate_measurement(Signal.t()) :: float() | :unknown
  def evaluate_measurement(%Signal{measurement_uncertainty: mu}) when is_map(mu) do
    case mu[:type] do
      :exact -> 1.0
      :bounded -> 0.8
      :approximate -> 0.6
      :estimated -> 0.4
      :unknown -> 0.2
      _ -> 0.5
    end
  end

  def evaluate_measurement(_signal), do: :unknown

  @doc "Independence as recorded on the signal; `:unknown` if not assessed."
  @spec evaluate_independence(Signal.t()) :: float() | :unknown
  def evaluate_independence(%Signal{independence: i}) when is_number(i) and i >= 0 and i <= 1,
    do: i

  def evaluate_independence(_signal), do: :unknown

  @doc "Persistence as recorded on the signal; `:unknown` if not assessed."
  @spec evaluate_persistence(Signal.t()) :: float() | :unknown
  def evaluate_persistence(%Signal{persistence: p}) when is_number(p) and p >= 0 and p <= 1,
    do: p

  def evaluate_persistence(_signal), do: :unknown

  @doc "Contextual/regime validity: 0 if expired, else 1 or `:unknown`."
  @spec evaluate_validity(Signal.t()) :: float() | :unknown
  def evaluate_validity(%Signal{} = s) do
    if Signal.expired?(s, DateTime.utc_now()) do
      0.0
    else
      if is_nil(s.expires_at) do
        1.0
      else
        1.0
      end
    end
  end

  # ------------------------------------------------------------------
  # Helpers
  # ------------------------------------------------------------------

  defp config do
    stored = Application.get_env(:tiannara, :efdi_quality_weights, %{})
    Map.merge(@default_config, Map.new(stored))
  end

  defp count_assessed(dims), do: Enum.count(dims, fn d -> d != :unknown end)
  defp count_unknown(dims), do: Enum.count(dims, fn d -> d == :unknown end)

  defp ensure_weight_sum(weights) do
    s = Enum.sum(weights)
    if s == 0, do: 1.0, else: s
  end

  defp safe_div(_v, d) when d == 0 or d == 0.0, do: 0.0
  defp safe_div(v, d), do: v / d

  defp clamp01(x) when x < 0, do: 0.0
  defp clamp01(x) when x > 1, do: 1.0
  defp clamp01(x), do: x
end
