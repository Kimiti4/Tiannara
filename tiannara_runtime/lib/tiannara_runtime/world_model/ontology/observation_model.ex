defmodule TiannaraRuntime.WorldModel.Ontology.ObservationModel do
  @moduledoc """
  Phase 17 — ObservationModel: maps latent variables to observable quantities.
  """
  @enforce_keys [:mapping]
  defstruct [:mapping, :noise_distribution, :missing_data, :measurement_error]

  @type missing_data_strategy :: :ignore | :impute | :marginalize

  @type t :: %__MODULE__{
          mapping: map(),
          noise_distribution: TiannaraRuntime.WorldModel.Ontology.ProbabilityDistribution.t() | nil,
          missing_data: missing_data_strategy(),
          measurement_error: float() | nil
        }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    om = %__MODULE__{
      mapping: Keyword.get(opts, :mapping, %{}),
      noise_distribution: Keyword.get(opts, :noise_distribution),
      missing_data: Keyword.get(opts, :missing_data, :ignore),
      measurement_error: Keyword.get(opts, :measurement_error)
    }
    validate(om)
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{mapping: m}) when not is_map(m),
    do: {:error, "ObservationModel mapping must be a map"}
  def validate(%__MODULE__{missing_data: md}) when not is_nil(md) and md not in ~w(ignore impute marginalize)a,
    do: {:error, "ObservationModel missing_data must be one of: ignore, impute, marginalize"}
  def validate(%__MODULE__{} = om), do: {:ok, om}
  def validate(_), do: {:error, "invalid ObservationModel"}
end
