defmodule TiannaraRuntime.WorldModel.Ontology.Variable do
  @moduledoc """
  Phase 17 — Variable: a typed dimension of a world model's state space.
  """
  @enforce_keys [:variable_id, :name, :type]
  defstruct [
    :variable_id,
    :name,
    :type,
    :domain,
    :unit,
    :is_endogenous,
    :observation_source,
    :description,
    :metadata
  ]

  @type var_type :: :continuous | :discrete | :categorical | :ordinal | :latent

  @type t :: %__MODULE__{
          variable_id: String.t(),
          name: String.t(),
          type: var_type(),
          domain: [term()] | {number(), number()} | nil,
          unit: String.t() | nil,
          is_endogenous: boolean(),
          observation_source: String.t() | nil,
          description: String.t() | nil,
          metadata: map()
        }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    v = %__MODULE__{
      variable_id: Keyword.get(opts, :variable_id, generate_id()),
      name: Keyword.get(opts, :name),
      type: Keyword.get(opts, :type),
      domain: Keyword.get(opts, :domain),
      unit: Keyword.get(opts, :unit),
      is_endogenous: Keyword.get(opts, :is_endogenous, true),
      observation_source: Keyword.get(opts, :observation_source),
      description: Keyword.get(opts, :description),
      metadata: Keyword.get(opts, :metadata, %{})
    }
    validate(v)
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{name: n}) when is_nil(n) or n == "",
    do: {:error, "Variable name must not be empty"}
  def validate(%__MODULE__{type: t}) when t not in ~w(continuous discrete categorical ordinal latent)a,
    do: {:error, "Variable type must be one of: continuous, discrete, categorical, ordinal, latent"}
  def validate(%__MODULE__{type: :categorical, domain: d}) when is_nil(d),
    do: {:error, "categorical variable must have a domain"}
  def validate(%__MODULE__{} = v), do: {:ok, v}
  def validate(_), do: {:error, "invalid Variable"}

  defp generate_id, do: "var_" <> (:crypto.strong_rand_bytes(12) |> Base.encode16(case: :lower))
end
