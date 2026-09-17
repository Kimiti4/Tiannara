defmodule TiannaraRuntime.WorldModel.Ontology.TimeSeriesPoint do
  @moduledoc """
  Phase 17 — TimeSeriesPoint: a single observation at a point in time.
  """
  @enforce_keys [:t, :values]
  defstruct [:t, :values, :uncertainty]

  @type t :: %__MODULE__{
          t: non_neg_integer() | float() | String.t(),
          values: map(),
          uncertainty: map() | nil
        }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    tsp = %__MODULE__{
      t: Keyword.get(opts, :t),
      values: Keyword.get(opts, :values, %{}),
      uncertainty: Keyword.get(opts, :uncertainty)
    }
    validate(tsp)
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{t: t}) when is_nil(t),
    do: {:error, "TimeSeriesPoint t must not be nil"}
  def validate(%__MODULE__{values: v}) when not is_map(v) or v == %{},
    do: {:error, "TimeSeriesPoint values must be a non-empty map"}
  def validate(%__MODULE__{} = tsp), do: {:ok, tsp}
  def validate(_), do: {:error, "invalid TimeSeriesPoint"}
end

defmodule TiannaraRuntime.WorldModel.Ontology.Prediction do
  @moduledoc """
  Phase 17 — Prediction: the output of running a world model forward in time.
  """
  @enforce_keys [:prediction_id, :model_id, :model_version, :input_state, :output_variables]
  defstruct [
    :prediction_id,
    :model_id,
    :model_version,
    :input_state,
    :output_variables,
    :time_horizon,
    :forecast,
    :confidence_intervals,
    :extrapolation,
    :fingerprint,
    :created_at
  ]

  @type t :: %__MODULE__{
          prediction_id: String.t(),
          model_id: String.t(),
          model_version: non_neg_integer(),
          input_state: map(),
          output_variables: [String.t()],
          time_horizon: non_neg_integer() | String.t() | nil,
          forecast: [TiannaraRuntime.WorldModel.Ontology.TimeSeriesPoint.t()],
          confidence_intervals: [TiannaraRuntime.WorldModel.Ontology.Interval.t()],
          extrapolation: boolean(),
          fingerprint: String.t() | nil,
          created_at: String.t()
        }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()

    p = %__MODULE__{
      prediction_id: Keyword.get(opts, :prediction_id, generate_id()),
      model_id: Keyword.get(opts, :model_id),
      model_version: Keyword.get(opts, :model_version, 1),
      input_state: Keyword.get(opts, :input_state, %{}),
      output_variables: Keyword.get(opts, :output_variables, []),
      time_horizon: Keyword.get(opts, :time_horizon),
      forecast: Keyword.get(opts, :forecast, []),
      confidence_intervals: Keyword.get(opts, :confidence_intervals, []),
      extrapolation: Keyword.get(opts, :extrapolation, false),
      fingerprint: Keyword.get(opts, :fingerprint),
      created_at: Keyword.get(opts, :created_at, now)
    }
    validate(p)
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{model_id: mid}) when is_nil(mid) or mid == "",
    do: {:error, "Prediction model_id must not be empty"}
  def validate(%__MODULE__{output_variables: ov}) when not is_list(ov) or ov == [],
    do: {:error, "Prediction output_variables must be a non-empty list"}
  def validate(%__MODULE__{} = p), do: {:ok, p}
  def validate(_), do: {:error, "invalid Prediction"}

  defp generate_id, do: "pred_" <> (:crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower))
end
