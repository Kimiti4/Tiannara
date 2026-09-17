defmodule TiannaraRuntime.WorldModel.Prediction.ConfidenceEstimate do
  @moduledoc """
  Phase 17.4 — ConfidenceEstimate: multi-dimensional confidence assessment for a forecast.
  Content-addressed ID prefix: ce_
  """
  @enforce_keys [:score, :explanation]
  defstruct [
    :confidence_id, :score, :evidence_quality, :model_maturity,
    :replay_stability, :historical_perf, :explanation, :metadata
  ]

  @type t :: %__MODULE__{
    confidence_id: String.t(),
    score: float(),
    evidence_quality: float(),
    model_maturity: float(),
    replay_stability: float(),
    historical_perf: float() | nil,
    explanation: String.t(),
    metadata: map()
  }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    ce = %__MODULE__{
      confidence_id: Keyword.get(opts, :confidence_id),
      score: Keyword.get(opts, :score),
      evidence_quality: Keyword.get(opts, :evidence_quality, 0.0),
      model_maturity: Keyword.get(opts, :model_maturity, 0.0),
      replay_stability: Keyword.get(opts, :replay_stability, 0.0),
      historical_perf: Keyword.get(opts, :historical_perf),
      explanation: Keyword.get(opts, :explanation),
      metadata: Keyword.get(opts, :metadata, %{})
    }
    with {:ok, ce} <- validate(ce),
         do: {:ok, ensure_id(ce)}
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{score: s}) when not is_number(s) or s < 0.0 or s > 1.0,
    do: {:error, "ConfidenceEstimate score must be in [0.0, 1.0]"}
  def validate(%__MODULE__{evidence_quality: eq}) when eq < 0.0 or eq > 1.0,
    do: {:error, "ConfidenceEstimate evidence_quality must be in [0.0, 1.0]"}
  def validate(%__MODULE__{model_maturity: mm}) when mm < 0.0 or mm > 1.0,
    do: {:error, "ConfidenceEstimate model_maturity must be in [0.0, 1.0]"}
  def validate(%__MODULE__{replay_stability: rs}) when rs < 0.0 or rs > 1.0,
    do: {:error, "ConfidenceEstimate replay_stability must be in [0.0, 1.0]"}
  def validate(%__MODULE__{explanation: e}) when is_nil(e) or e == "",
    do: {:error, "ConfidenceEstimate explanation must not be empty"}
  def validate(%__MODULE__{historical_perf: hp}) when hp != nil and (hp < 0.0 or hp > 1.0),
    do: {:error, "ConfidenceEstimate historical_perf must be in [0.0, 1.0] when provided"}
  def validate(%__MODULE__{} = ce), do: {:ok, ce}
  def validate(_), do: {:error, "invalid ConfidenceEstimate"}

  @spec canonicalize(t()) :: map()
  def canonicalize(%__MODULE__{} = ce) do
    Map.from_struct(ce)
    |> Map.delete(:__struct__)
    |> Enum.map(fn {k, v} -> {to_string(k), canonical_value(v)} end)
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.into(%{})
  end

  defp canonical_value(v) when is_list(v), do: Enum.sort(v)
  defp canonical_value(v) when is_map(v), do: v |> Enum.sort_by(fn {k, _} -> to_string(k) end) |> Enum.into(%{})
  defp canonical_value(v), do: v

  @spec compute_id(t()) :: String.t()
  def compute_id(%__MODULE__{} = ce) do
    raw = Float.to_string(ce.score) <> ce.explanation
    "ce_" <> (:crypto.hash(:sha256, raw) |> Base.encode16(case: :lower))
  end

  defp ensure_id(%__MODULE__{confidence_id: nil} = ce), do: %{ce | confidence_id: compute_id(ce)}
  defp ensure_id(%__MODULE__{} = ce), do: ce
end
