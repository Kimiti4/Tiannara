defmodule TiannaraRuntime.WorldModel.Prediction.ForecastStep do
  @moduledoc """
  Phase 17.4 — ForecastStep: a single time step within a forecast with associated values.
  Content-addressed ID prefix: fs_
  """
  @enforce_keys [:step, :values]
  defstruct [:step_id, :step, :timestamp, :values, :intervention_state]

  @type t :: %__MODULE__{
    step_id: String.t(),
    step: non_neg_integer(),
    timestamp: String.t() | nil,
    values: map(),
    intervention_state: map() | nil
  }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    fs = %__MODULE__{
      step_id: Keyword.get(opts, :step_id),
      step: Keyword.get(opts, :step),
      timestamp: Keyword.get(opts, :timestamp),
      values: Keyword.get(opts, :values, %{}),
      intervention_state: Keyword.get(opts, :intervention_state)
    }
    with {:ok, fs} <- validate(fs),
         do: {:ok, ensure_id(fs)}
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{step: s}) when not is_integer(s) or s < 0,
    do: {:error, "ForecastStep step must be a non-negative integer"}
  def validate(%__MODULE__{values: v}) when is_nil(v),
    do: {:error, "ForecastStep values must not be nil"}
  def validate(%__MODULE__{values: v}) when v == %{},
    do: {:error, "ForecastStep values must not be empty"}
  def validate(%__MODULE__{values: v} = fs) when is_map(v) do
    if Enum.any?(v, fn {_, val} -> is_nil(val) end) do
      {:error, "ForecastStep values must not contain nil entries"}
    else
      {:ok, fs}
    end
  end
  def validate(%__MODULE__{} = fs), do: {:ok, fs}
  def validate(_), do: {:error, "invalid ForecastStep"}

  @spec canonicalize(t()) :: map()
  def canonicalize(%__MODULE__{} = fs) do
    Map.from_struct(fs)
    |> Map.delete(:__struct__)
    |> Enum.map(fn {k, v} -> {to_string(k), canonical_value(v)} end)
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.into(%{})
  end

  defp canonical_value(v) when is_list(v), do: Enum.sort(v)
  defp canonical_value(v) when is_map(v), do: v |> Enum.sort_by(fn {k, _} -> to_string(k) end) |> Enum.into(%{})
  defp canonical_value(v), do: v

  @spec compute_id(t()) :: String.t()
  def compute_id(%__MODULE__{} = fs) do
    raw = Integer.to_string(fs.step) <> inspect(fs.values)
    "fs_" <> (:crypto.hash(:sha256, raw) |> Base.encode16(case: :lower))
  end

  defp ensure_id(%__MODULE__{step_id: nil} = fs), do: %{fs | step_id: compute_id(fs)}
  defp ensure_id(%__MODULE__{} = fs), do: fs
end
