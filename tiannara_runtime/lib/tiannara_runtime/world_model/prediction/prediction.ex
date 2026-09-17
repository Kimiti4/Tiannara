defmodule TiannaraRuntime.WorldModel.Prediction.Prediction do
  @moduledoc """
  Phase 17.4 — Prediction: a forecast produced by a world model describing expected future variable values.
  Content-addressed ID prefix: pr_
  """
  alias TiannaraRuntime.WorldModel.Prediction.Forecast
  alias TiannaraRuntime.WorldModel.Prediction.ConfidenceEstimate
  alias TiannaraRuntime.WorldModel.Prediction.UncertaintyDistribution
  alias TiannaraRuntime.WorldModel.Prediction.ForecastVariable
  @enforce_keys [:world_model_id, :target_variables, :horizon, :forecast]
  defstruct [
    :prediction_id, :world_model_id, :world_model_version,
    :model_fingerprint, :target_variables, :horizon, :assumptions,
    :confidence, :uncertainty, :forecast, :replay_fingerprint,
    :evidence_roots, :math_verification, :archaeology_root, :metadata,
    :created_at
  ]

  @type t :: %__MODULE__{
    prediction_id: String.t(),
    world_model_id: String.t(),
    world_model_version: non_neg_integer() | nil,
    model_fingerprint: String.t() | nil,
    target_variables: [ForecastVariable.t()],
    horizon: atom(),
    assumptions: map(),
    confidence: ConfidenceEstimate.t() | nil,
    uncertainty: UncertaintyDistribution.t() | nil,
    forecast: Forecast.t(),
    replay_fingerprint: String.t() | nil,
    evidence_roots: [String.t()],
    math_verification: map() | nil,
    archaeology_root: String.t() | nil,
    metadata: map(),
    created_at: String.t()
  }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    p = %__MODULE__{
      prediction_id: Keyword.get(opts, :prediction_id),
      world_model_id: Keyword.get(opts, :world_model_id),
      world_model_version: Keyword.get(opts, :world_model_version),
      model_fingerprint: Keyword.get(opts, :model_fingerprint),
      target_variables: Keyword.get(opts, :target_variables, []),
      horizon: Keyword.get(opts, :horizon),
      assumptions: Keyword.get(opts, :assumptions, %{}),
      confidence: Keyword.get(opts, :confidence),
      uncertainty: Keyword.get(opts, :uncertainty),
      forecast: Keyword.get(opts, :forecast),
      replay_fingerprint: Keyword.get(opts, :replay_fingerprint),
      evidence_roots: Keyword.get(opts, :evidence_roots, []),
      math_verification: Keyword.get(opts, :math_verification),
      archaeology_root: Keyword.get(opts, :archaeology_root),
      metadata: Keyword.get(opts, :metadata, %{}),
      created_at: Keyword.get(opts, :created_at, DateTime.utc_now() |> DateTime.to_iso8601())
    }
    with {:ok, p} <- validate(p),
         do: {:ok, ensure_id(p)}
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{world_model_id: wm}) when is_nil(wm) or wm == "",
    do: {:error, "Prediction world_model_id must not be empty"}
  def validate(%__MODULE__{target_variables: tv}) when not is_list(tv) or tv == [],
    do: {:error, "Prediction target_variables must be a non-empty list"}
  def validate(%__MODULE__{horizon: h}) when h not in ~w(immediate short_term medium_term long_term civilization)a,
    do: {:error, "Prediction horizon must be one of: immediate, short_term, medium_term, long_term, civilization"}
  def validate(%__MODULE__{forecast: f}) when is_nil(f),
    do: {:error, "Prediction forecast must not be nil"}
  def validate(%__MODULE__{confidence: c} = p) when c != nil do
    case c do
      %ConfidenceEstimate{} -> {:ok, p}
      _ -> {:error, "Prediction confidence must be a ConfidenceEstimate struct when provided"}
    end
  end
  def validate(%__MODULE__{} = p), do: {:ok, p}
  def validate(_), do: {:error, "invalid Prediction"}

  @spec canonicalize(t()) :: map()
  def canonicalize(%__MODULE__{} = p) do
    Map.from_struct(p)
    |> Map.delete(:__struct__)
    |> Enum.map(fn {k, v} -> {to_string(k), canonical_value(v)} end)
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.into(%{})
  end

  defp canonical_value(%Forecast{} = f), do: Forecast.canonicalize(f)
  defp canonical_value(%ConfidenceEstimate{} = c), do: ConfidenceEstimate.canonicalize(c)
  defp canonical_value(v) when is_list(v), do: Enum.sort(v)
  defp canonical_value(v) when is_map(v), do: v |> Enum.sort_by(fn {k, _} -> to_string(k) end) |> Enum.into(%{})
  defp canonical_value(v), do: v

  @spec compute_id(t()) :: String.t()
  def compute_id(%__MODULE__{} = p) do
    raw = p.world_model_id <> Atom.to_string(p.horizon) <> inspect(p.target_variables)
    "pr_" <> (:crypto.hash(:sha256, raw) |> Base.encode16(case: :lower))
  end

  defp ensure_id(%__MODULE__{prediction_id: nil} = p), do: %{p | prediction_id: compute_id(p)}
  defp ensure_id(%__MODULE__{} = p), do: p
end
