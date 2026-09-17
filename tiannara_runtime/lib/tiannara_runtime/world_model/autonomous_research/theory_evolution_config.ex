defmodule TiannaraRuntime.WorldModel.AutonomousResearch.TheoryEvolutionConfig do
  @moduledoc """
  Phase 17.8.6 — TheoryEvolutionConfig: the epoch-frozen configuration artifact that
  carries all thresholds, factors, and weights for autonomous theory evolution.

  Constitutional rules:
  - This struct is the single source of truth for all theory evolution criteria.
  - No threshold, boost factor, or penalty has a hardcoded default anywhere in the system.
  - If this artifact is absent, the TheoryUpdater fails closed.
  - content-addressed ID computed via TiannaraRuntime.Shared.Canonical.
  - Immutable after creation; updates require a new TheoryEvolutionConfig artifact.
  """

  alias TiannaraRuntime.Shared.Canonical

  @id_prefix "tecfg"
  @id_field :config_id

  @weight_sum_tolerance 1.0e-9

  defstruct [
    :config_id,
    :epoch_id,
    :schema_version,
    :support_threshold,
    :strength_threshold,
    :reject_support_threshold,
    :boost_factor,
    :penalty_factor,
    :rejection_confidence_threshold,
    :rejection_contradiction_score_threshold,
    :rejection_contradiction_confidence_threshold,
    :contradiction_difference_limit,
    :support_match_difference_limit,
    :min_sample_size,
    :sample_size_normalization_base,
    :w_confidence,
    :w_size,
    :w_effect
  ]

  @type t :: %__MODULE__{
          config_id: String.t() | nil,
          epoch_id: String.t() | nil,
          schema_version: String.t() | nil,
          support_threshold: float() | nil,
          strength_threshold: float() | nil,
          reject_support_threshold: float() | nil,
          boost_factor: float() | nil,
          penalty_factor: float() | nil,
          rejection_confidence_threshold: float() | nil,
          rejection_contradiction_score_threshold: float() | nil,
          rejection_contradiction_confidence_threshold: float() | nil,
          contradiction_difference_limit: float() | nil,
          support_match_difference_limit: float() | nil,
          min_sample_size: integer() | nil,
          sample_size_normalization_base: float() | nil,
          w_confidence: float() | nil,
          w_size: float() | nil,
          w_effect: float() | nil
        }

  @doc """
  Constructs and validates a TheoryEvolutionConfig. All parameters must be supplied by the caller.
  """
  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts) when is_list(opts) do
    config = %__MODULE__{
      epoch_id: Keyword.get(opts, :epoch_id),
      schema_version: Keyword.get(opts, :schema_version),
      support_threshold: Keyword.get(opts, :support_threshold),
      strength_threshold: Keyword.get(opts, :strength_threshold),
      reject_support_threshold: Keyword.get(opts, :reject_support_threshold),
      boost_factor: Keyword.get(opts, :boost_factor),
      penalty_factor: Keyword.get(opts, :penalty_factor),
      rejection_confidence_threshold: Keyword.get(opts, :rejection_confidence_threshold),
      rejection_contradiction_score_threshold: Keyword.get(opts, :rejection_contradiction_score_threshold),
      rejection_contradiction_confidence_threshold: Keyword.get(opts, :rejection_contradiction_confidence_threshold),
      contradiction_difference_limit: Keyword.get(opts, :contradiction_difference_limit),
      support_match_difference_limit: Keyword.get(opts, :support_match_difference_limit),
      min_sample_size: Keyword.get(opts, :min_sample_size),
      sample_size_normalization_base: Keyword.get(opts, :sample_size_normalization_base),
      w_confidence: Keyword.get(opts, :w_confidence),
      w_size: Keyword.get(opts, :w_size),
      w_effect: Keyword.get(opts, :w_effect)
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

  @spec validate(t()) :: :ok | {:error, String.t()}
  defp validate(%__MODULE__{epoch_id: nil}),
    do: {:error, "TheoryEvolutionConfig: epoch_id is required"}

  defp validate(%__MODULE__{epoch_id: v}) when not is_binary(v) or v == "",
    do: {:error, "TheoryEvolutionConfig: epoch_id must be a non-empty string"}

  defp validate(%__MODULE__{schema_version: nil}),
    do: {:error, "TheoryEvolutionConfig: schema_version is required"}

  defp validate(%__MODULE__{schema_version: v}) when not is_binary(v) or v == "",
    do: {:error, "TheoryEvolutionConfig: schema_version must be a non-empty string"}

  for field <- [
        :support_threshold,
        :strength_threshold,
        :reject_support_threshold,
        :boost_factor,
        :penalty_factor,
        :rejection_confidence_threshold,
        :rejection_contradiction_score_threshold,
        :rejection_contradiction_confidence_threshold,
        :contradiction_difference_limit,
        :support_match_difference_limit,
        :sample_size_normalization_base,
        :w_confidence,
        :w_size,
        :w_effect
      ] do
    defp validate(%__MODULE__{unquote(field) => nil}),
      do: {:error, "TheoryEvolutionConfig: #{unquote(field)} is required"}

    defp validate(%__MODULE__{unquote(field) => v}) when not is_float(v) or v < 0.0,
      do: {:error, "TheoryEvolutionConfig: #{unquote(field)} must be a non-negative float"}
  end

  defp validate(%__MODULE__{min_sample_size: nil}),
    do: {:error, "TheoryEvolutionConfig: min_sample_size is required"}

  defp validate(%__MODULE__{min_sample_size: v}) when not is_integer(v) or v <= 0,
    do: {:error, "TheoryEvolutionConfig: min_sample_size must be a positive integer"}

  defp validate(%__MODULE__{} = config) do
    sum = config.w_confidence + config.w_size + config.w_effect

    if abs(sum - 1.0) <= @weight_sum_tolerance do
      :ok
    else
      {:error,
       "TheoryEvolutionConfig: evidence strength weights must sum to 1.0; got #{sum} (delta=#{abs(sum - 1.0)}, tolerance=#{@weight_sum_tolerance})"}
    end
  end
end
