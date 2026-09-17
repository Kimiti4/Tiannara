defmodule TiannaraRuntime.WorldModel.Prediction.ForecastVariable do
  @moduledoc """
  Phase 17.4 — ForecastVariable: a typed variable projected forward in a forecast.
  Content-addressed ID prefix: fv_
  """
  @enforce_keys [:name]
  defstruct [:variable_id, :name, :type, :domain, :metadata]

  @type t :: %__MODULE__{
    variable_id: String.t(),
    name: String.t(),
    type: atom(),
    domain: list() | map() | nil,
    metadata: map()
  }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    fv = %__MODULE__{
      variable_id: Keyword.get(opts, :variable_id),
      name: Keyword.get(opts, :name),
      type: Keyword.get(opts, :type, :continuous),
      domain: Keyword.get(opts, :domain),
      metadata: Keyword.get(opts, :metadata, %{})
    }
    with {:ok, fv} <- validate(fv),
         do: {:ok, ensure_id(fv)}
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{name: n}) when is_nil(n) or n == "",
    do: {:error, "ForecastVariable name must not be empty"}
  def validate(%__MODULE__{type: t}) when t not in ~w(continuous categorical)a,
    do: {:error, "ForecastVariable type must be one of: continuous, categorical"}
  def validate(%__MODULE__{type: :continuous, domain: d}) when d != nil and not is_map(d),
    do: {:error, "ForecastVariable domain for continuous type must be a map or nil"}
  def validate(%__MODULE__{type: :categorical, domain: d}) when d != nil and not is_list(d),
    do: {:error, "ForecastVariable domain for categorical type must be a list or nil"}
  def validate(%__MODULE__{} = fv), do: {:ok, fv}
  def validate(_), do: {:error, "invalid ForecastVariable"}

  @spec canonicalize(t()) :: map()
  def canonicalize(%__MODULE__{} = fv) do
    Map.from_struct(fv)
    |> Map.delete(:__struct__)
    |> Enum.map(fn {k, v} -> {to_string(k), canonical_value(v)} end)
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.into(%{})
  end

  defp canonical_value(v) when is_list(v), do: Enum.sort(v)
  defp canonical_value(v) when is_map(v), do: v |> Enum.sort_by(fn {k, _} -> to_string(k) end) |> Enum.into(%{})
  defp canonical_value(v), do: v

  @spec compute_id(t()) :: String.t()
  def compute_id(%__MODULE__{} = fv) do
    raw = fv.name <> Atom.to_string(fv.type)
    "fv_" <> (:crypto.hash(:sha256, raw) |> Base.encode16(case: :lower))
  end

  defp ensure_id(%__MODULE__{variable_id: nil} = fv), do: %{fv | variable_id: compute_id(fv)}
  defp ensure_id(%__MODULE__{} = fv), do: fv
end
