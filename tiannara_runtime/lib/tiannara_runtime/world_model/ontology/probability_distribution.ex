defmodule TiannaraRuntime.WorldModel.Ontology.ProbabilityDistribution do
  @moduledoc """
  Phase 17 — ProbabilityDistribution: represents uncertainty over a parameter or variable.
  """
  @enforce_keys [:type, :parameters]
  defstruct [:type, :parameters, :fingerprint]

  @type dist_type :: :normal | :uniform | :beta | :gamma | :lognormal | :categorical | :empirical

  @type t :: %__MODULE__{
          type: dist_type(),
          parameters: map(),
          fingerprint: String.t() | nil
        }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    pd = %__MODULE__{
      type: Keyword.get(opts, :type),
      parameters: Keyword.get(opts, :parameters, %{}),
      fingerprint: Keyword.get(opts, :fingerprint)
    }
    validate(pd)
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{type: t}) when t not in ~w(normal uniform beta gamma lognormal categorical empirical)a,
    do: {:error, "ProbabilityDistribution type must be one of: normal, uniform, beta, gamma, lognormal, categorical, empirical"}
  def validate(%__MODULE__{type: :normal, parameters: params} = pd) do
    cond do
      not is_map_key(params, :mean) -> {:error, "normal distribution requires :mean parameter"}
      not is_map_key(params, :std_dev) -> {:error, "normal distribution requires :std_dev parameter"}
      true -> {:ok, pd}
    end
  end
  def validate(%__MODULE__{type: :uniform, parameters: params} = pd) do
    cond do
      not is_map_key(params, :lower) -> {:error, "uniform distribution requires :lower parameter"}
      not is_map_key(params, :upper) -> {:error, "uniform distribution requires :upper parameter"}
      true -> {:ok, pd}
    end
  end
  def validate(%__MODULE__{} = pd), do: {:ok, pd}
  def validate(_), do: {:error, "invalid ProbabilityDistribution"}
end

defmodule TiannaraRuntime.WorldModel.Ontology.Interval do
  @moduledoc """
  Phase 17 — Interval: a confidence interval for prediction uncertainty.
  """
  defstruct [:lower, :upper, :confidence_level]

  @type t :: %__MODULE__{
          lower: float(),
          upper: float(),
          confidence_level: float()
        }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    iv = %__MODULE__{
      lower: Keyword.get(opts, :lower),
      upper: Keyword.get(opts, :upper),
      confidence_level: Keyword.get(opts, :confidence_level, 0.95)
    }
    validate(iv)
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{lower: l, upper: u}) when l > u,
    do: {:error, "Interval lower must be <= upper"}
  def validate(%__MODULE__{confidence_level: c}) when not is_nil(c) and (c <= 0.0 or c >= 1.0),
    do: {:error, "Interval confidence_level must be in (0.0, 1.0)"}
  def validate(%__MODULE__{} = iv), do: {:ok, iv}
  def validate(_), do: {:error, "invalid Interval"}
end
