defmodule TiannaraRuntime.WorldModel.AutonomousResearch.ScoringConfig do
  @moduledoc """
  Phase 17.8.2 — ScoringConfig: the epoch-frozen configuration artifact that
  carries all scoring weights for the ARPEPriorityScorer.

  Constitutional rules:
  - This struct is the single source of truth for all scoring weights.
  - No weight has a hardcoded default anywhere in the system.
  - If this artifact is absent, the ARPEPriorityScorer fails closed.
  - content-addressed ID computed via TiannaraRuntime.Shared.Canonical.
  - Immutable after creation; weight changes require a new ScoringConfig artifact.

  All weights must sum to exactly 1.0 (validated at construction time).
  This constraint is constitutional — a scoring function whose weights do not
  sum to 1.0 is not a proper probability-weighted linear combination and
  cannot be deterministically reproduced across implementations.
  """

  alias TiannaraRuntime.Shared.Canonical

  @id_prefix "scfg"
  @id_field :config_id

  # Weight sum tolerance for floating-point arithmetic.
  # Expressed as a named constant — not hardcoded inline.
  @weight_sum_tolerance 1.0e-9

  defstruct [
    :config_id,
    :epoch_id,
    :schema_version,
    :w_uncertainty,
    :w_impact,
    :w_feasibility,
    :w_civilization_relevance,
    :w_information_gain,
    :tie_break_field,
    :tie_break_direction
  ]

  @type t :: %__MODULE__{
          config_id: String.t() | nil,
          epoch_id: String.t() | nil,
          schema_version: String.t() | nil,
          w_uncertainty: float() | nil,
          w_impact: float() | nil,
          w_feasibility: float() | nil,
          w_civilization_relevance: float() | nil,
          w_information_gain: float() | nil,
          tie_break_field: String.t() | nil,
          tie_break_direction: :asc | :desc | nil
        }

  @doc """
  Constructs and validates a ScoringConfig. All weights must be supplied by the
  caller. They must sum to 1.0 within floating-point tolerance.

  Required keys:
  - :epoch_id (String.t)
  - :schema_version (String.t)
  - :w_uncertainty (float, >= 0.0)
  - :w_impact (float, >= 0.0)
  - :w_feasibility (float, >= 0.0)
  - :w_civilization_relevance (float, >= 0.0)
  - :w_information_gain (float, >= 0.0)
  - :tie_break_field (String.t — the field name used for lexicographic tie-breaking)
  - :tie_break_direction (:asc | :desc)

  The :config_id is computed from the other fields; do not supply it.
  """
  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts) when is_list(opts) do
    config = %__MODULE__{
      epoch_id: Keyword.get(opts, :epoch_id),
      schema_version: Keyword.get(opts, :schema_version),
      w_uncertainty: Keyword.get(opts, :w_uncertainty),
      w_impact: Keyword.get(opts, :w_impact),
      w_feasibility: Keyword.get(opts, :w_feasibility),
      w_civilization_relevance: Keyword.get(opts, :w_civilization_relevance),
      w_information_gain: Keyword.get(opts, :w_information_gain),
      tie_break_field: Keyword.get(opts, :tie_break_field),
      tie_break_direction: Keyword.get(opts, :tie_break_direction)
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

  @doc """
  Returns the weight sum tolerance constant. Used by validators to check
  that weights sum to 1.0 without embedding the tolerance as a magic number.
  """
  @spec weight_sum_tolerance() :: float()
  def weight_sum_tolerance, do: @weight_sum_tolerance

  @spec validate(t()) :: :ok | {:error, String.t()}
  defp validate(%__MODULE__{epoch_id: nil}),
    do: {:error, "ScoringConfig: epoch_id is required"}

  defp validate(%__MODULE__{epoch_id: v}) when not is_binary(v) or v == "",
    do: {:error, "ScoringConfig: epoch_id must be a non-empty string"}

  defp validate(%__MODULE__{schema_version: nil}),
    do: {:error, "ScoringConfig: schema_version is required"}

  defp validate(%__MODULE__{schema_version: v}) when not is_binary(v) or v == "",
    do: {:error, "ScoringConfig: schema_version must be a non-empty string"}

  for field <- [:w_uncertainty, :w_impact, :w_feasibility, :w_civilization_relevance, :w_information_gain] do
    defp validate(%__MODULE__{unquote(field) => nil}),
      do: {:error, "ScoringConfig: #{unquote(field)} is required"}

    defp validate(%__MODULE__{unquote(field) => v}) when not is_float(v) or v < 0.0,
      do: {:error, "ScoringConfig: #{unquote(field)} must be a non-negative float"}
  end

  defp validate(%__MODULE__{tie_break_field: nil}),
    do: {:error, "ScoringConfig: tie_break_field is required"}

  defp validate(%__MODULE__{tie_break_field: v}) when not is_binary(v) or v == "",
    do: {:error, "ScoringConfig: tie_break_field must be a non-empty string"}

  defp validate(%__MODULE__{tie_break_direction: nil}),
    do: {:error, "ScoringConfig: tie_break_direction is required"}

  defp validate(%__MODULE__{tie_break_direction: v}) when v not in [:asc, :desc],
    do: {:error, "ScoringConfig: tie_break_direction must be :asc or :desc"}

  defp validate(%__MODULE__{} = config) do
    sum =
      config.w_uncertainty +
        config.w_impact +
        config.w_feasibility +
        config.w_civilization_relevance +
        config.w_information_gain

    if abs(sum - 1.0) <= @weight_sum_tolerance do
      :ok
    else
      {:error,
       "ScoringConfig: weights must sum to 1.0; " <>
         "got #{sum} (delta=#{abs(sum - 1.0)}, tolerance=#{@weight_sum_tolerance})"}
    end
  end
end
