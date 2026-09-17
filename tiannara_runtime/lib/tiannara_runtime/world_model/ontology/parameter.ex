defmodule TiannaraRuntime.WorldModel.Ontology.Parameter do
  @moduledoc """
  Phase 17 — Parameter: an estimated numerical value with uncertainty distribution.
  """
  @enforce_keys [:parameter_id, :name, :value]
  defstruct [
    :parameter_id,
    :name,
    :value,
    :distribution,
    :bounds,
    :is_identifiable,
    :sensitivity,
    :estimated_from
  ]

  @type t :: %__MODULE__{
          parameter_id: String.t(),
          name: String.t(),
          value: number(),
          distribution: TiannaraRuntime.WorldModel.Ontology.ProbabilityDistribution.t() | nil,
          bounds: {number(), number()} | nil,
          is_identifiable: boolean(),
          sensitivity: float() | nil,
          estimated_from: String.t() | nil
        }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    p = %__MODULE__{
      parameter_id: Keyword.get(opts, :parameter_id, generate_id()),
      name: Keyword.get(opts, :name),
      value: Keyword.get(opts, :value),
      distribution: Keyword.get(opts, :distribution),
      bounds: Keyword.get(opts, :bounds),
      is_identifiable: Keyword.get(opts, :is_identifiable, false),
      sensitivity: Keyword.get(opts, :sensitivity),
      estimated_from: Keyword.get(opts, :estimated_from)
    }
    validate(p)
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{name: n}) when is_nil(n) or n == "",
    do: {:error, "Parameter name must not be empty"}
  def validate(%__MODULE__{value: v}) when not is_number(v),
    do: {:error, "Parameter value must be a number"}
  def validate(%__MODULE__{bounds: {l, u}}) when l > u,
    do: {:error, "Parameter bounds must have lower <= upper"}
  def validate(%__MODULE__{bounds: b}) when not is_nil(b) and not is_tuple(b),
    do: {:error, "Parameter bounds must be a {lower, upper} tuple"}
  def validate(%__MODULE__{} = p), do: {:ok, p}
  def validate(_), do: {:error, "invalid Parameter"}

  defp generate_id, do: "param_" <> (:crypto.strong_rand_bytes(12) |> Base.encode16(case: :lower))
end
