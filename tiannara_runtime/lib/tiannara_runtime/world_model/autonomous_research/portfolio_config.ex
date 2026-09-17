defmodule TiannaraRuntime.WorldModel.AutonomousResearch.PortfolioConfig do
  @moduledoc """
  Phase 17.8.4 — PortfolioConfig: the epoch-frozen configuration artifact
  that governs portfolio selection and optimization in the ARPEPortfolioManager.

  Constitutional rules:
  - All thresholds, objective weights, and constraints come from this config.
  - No numeric threshold or weight is hardcoded anywhere in the system.
  - If this artifact is absent, ARPEPortfolioManager fails closed.
  - content-addressed ID via TiannaraRuntime.Shared.Canonical.
  - Immutable after creation.

  The five optimization objectives and their relative weights must all be
  supplied. They must sum to 1.0 (same constraint as ScoringConfig).

  min_domain_diversity_threshold and min_value_threshold are required
  and come from this config — not from the program or context map.
  """

  alias TiannaraRuntime.Shared.Canonical

  @id_prefix "pcfg"
  @id_field :config_id

  # Named constant — not an inline literal
  @weight_sum_tolerance 1.0e-9

  defstruct [
    :config_id,
    :epoch_id,
    :schema_version,
    # Objective weights — must sum to 1.0
    :w_information_gain,
    :w_scientific_diversity,
    :w_constitutional_priority,
    :w_resource_utilization,
    :w_long_term_impact,
    # Selection constraints — all required
    :min_domain_diversity_threshold,
    :min_value_threshold,
    :max_portfolio_size,
    :optimization_algorithm_version
  ]

  @type t :: %__MODULE__{
          config_id: String.t() | nil,
          epoch_id: String.t() | nil,
          schema_version: String.t() | nil,
          w_information_gain: float() | nil,
          w_scientific_diversity: float() | nil,
          w_constitutional_priority: float() | nil,
          w_resource_utilization: float() | nil,
          w_long_term_impact: float() | nil,
          min_domain_diversity_threshold: float() | nil,
          min_value_threshold: float() | nil,
          max_portfolio_size: pos_integer() | nil,
          optimization_algorithm_version: String.t() | nil
        }

  @doc """
  Constructs and validates a PortfolioConfig. All values must be supplied.

  Required keys:
  - :epoch_id (String.t)
  - :schema_version (String.t)
  - :w_information_gain (float, >= 0.0)
  - :w_scientific_diversity (float, >= 0.0)
  - :w_constitutional_priority (float, >= 0.0)
  - :w_resource_utilization (float, >= 0.0)
  - :w_long_term_impact (float, >= 0.0)
    (all five weights must sum to 1.0)
  - :min_domain_diversity_threshold (float in [0.0, 1.0])
  - :min_value_threshold (float >= 0.0)
  - :max_portfolio_size (pos_integer)
  - :optimization_algorithm_version (String.t)

  The :config_id is computed from the other fields; do not supply it.
  """
  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts) when is_list(opts) do
    config = %__MODULE__{
      epoch_id: Keyword.get(opts, :epoch_id),
      schema_version: Keyword.get(opts, :schema_version),
      w_information_gain: Keyword.get(opts, :w_information_gain),
      w_scientific_diversity: Keyword.get(opts, :w_scientific_diversity),
      w_constitutional_priority: Keyword.get(opts, :w_constitutional_priority),
      w_resource_utilization: Keyword.get(opts, :w_resource_utilization),
      w_long_term_impact: Keyword.get(opts, :w_long_term_impact),
      min_domain_diversity_threshold: Keyword.get(opts, :min_domain_diversity_threshold),
      min_value_threshold: Keyword.get(opts, :min_value_threshold),
      max_portfolio_size: Keyword.get(opts, :max_portfolio_size),
      optimization_algorithm_version: Keyword.get(opts, :optimization_algorithm_version)
    }

    with :ok <- validate(config) do
      id = Canonical.generate_id(config, @id_field, @id_prefix)
      {:ok, %{config | config_id: id}}
    end
  end

  @spec verify_id(t()) :: :ok | {:error, String.t()}
  def verify_id(%__MODULE__{} = config) do
    Canonical.verify_id(config, @id_field, @id_prefix)
  end

  @spec weight_sum_tolerance() :: float()
  def weight_sum_tolerance, do: @weight_sum_tolerance

  @spec validate(t()) :: :ok | {:error, String.t()}
  defp validate(%__MODULE__{epoch_id: nil}),
    do: {:error, "PortfolioConfig: epoch_id is required"}

  defp validate(%__MODULE__{epoch_id: v}) when not is_binary(v) or v == "",
    do: {:error, "PortfolioConfig: epoch_id must be a non-empty string"}

  defp validate(%__MODULE__{schema_version: nil}),
    do: {:error, "PortfolioConfig: schema_version is required"}

  defp validate(%__MODULE__{schema_version: v}) when not is_binary(v) or v == "",
    do: {:error, "PortfolioConfig: schema_version must be a non-empty string"}

  for field <- [
        :w_information_gain,
        :w_scientific_diversity,
        :w_constitutional_priority,
        :w_resource_utilization,
        :w_long_term_impact
      ] do
    defp validate(%__MODULE__{unquote(field) => nil}),
      do: {:error, "PortfolioConfig: #{unquote(field)} is required"}

    defp validate(%__MODULE__{unquote(field) => v}) when not is_float(v) or v < 0.0,
      do: {:error, "PortfolioConfig: #{unquote(field)} must be a non-negative float"}
  end

  defp validate(%__MODULE__{} = config) do
    sum =
      config.w_information_gain +
        config.w_scientific_diversity +
        config.w_constitutional_priority +
        config.w_resource_utilization +
        config.w_long_term_impact

    if abs(sum - 1.0) <= @weight_sum_tolerance do
      validate_constraints(config)
    else
      {:error,
       "PortfolioConfig: objective weights must sum to 1.0; " <>
         "got #{sum} (delta=#{abs(sum - 1.0)})"}
    end
  end

  defp validate_constraints(%__MODULE__{min_domain_diversity_threshold: nil}),
    do: {:error, "PortfolioConfig: min_domain_diversity_threshold is required"}

  defp validate_constraints(%__MODULE__{min_domain_diversity_threshold: v})
       when not is_float(v) or v < 0.0 or v > 1.0,
       do: {:error,
            "PortfolioConfig: min_domain_diversity_threshold must be a float in [0.0, 1.0]"}

  defp validate_constraints(%__MODULE__{min_value_threshold: nil}),
    do: {:error, "PortfolioConfig: min_value_threshold is required"}

  defp validate_constraints(%__MODULE__{min_value_threshold: v})
       when not is_float(v) or v < 0.0,
       do: {:error, "PortfolioConfig: min_value_threshold must be a non-negative float"}

  defp validate_constraints(%__MODULE__{max_portfolio_size: nil}),
    do: {:error, "PortfolioConfig: max_portfolio_size is required"}

  defp validate_constraints(%__MODULE__{max_portfolio_size: v})
       when not is_integer(v) or v < 1,
       do: {:error, "PortfolioConfig: max_portfolio_size must be a positive integer"}

  defp validate_constraints(%__MODULE__{optimization_algorithm_version: nil}),
    do: {:error, "PortfolioConfig: optimization_algorithm_version is required"}

  defp validate_constraints(%__MODULE__{optimization_algorithm_version: v})
       when not is_binary(v) or v == "",
       do: {:error,
            "PortfolioConfig: optimization_algorithm_version must be a non-empty string"}

  defp validate_constraints(%__MODULE__{}), do: :ok
end
