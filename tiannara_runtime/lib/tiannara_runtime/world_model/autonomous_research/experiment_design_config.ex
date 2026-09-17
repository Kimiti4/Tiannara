defmodule TiannaraRuntime.WorldModel.AutonomousResearch.ExperimentDesignConfig do
  @moduledoc """
  Phase 17.8.3 — ExperimentDesignConfig: the epoch-frozen configuration artifact
  that governs experiment design decisions in the ARPEExperimentPlanner.

  Constitutional rules:
  - All design thresholds and constraints come from this config — never hardcoded.
  - If this artifact is absent, ARPEExperimentPlanner fails closed.
  - content-addressed ID via TiannaraRuntime.Shared.Canonical.
  - Immutable after creation.

  This config covers:
  - statistical requirements (which validation types are required per gap_type)
  - evidence observable requirements (minimum observables per experiment)
  - stopping condition requirements (which condition types are required)
  - deterministic seed derivation strategy name (frozen string label)
  """

  alias TiannaraRuntime.Shared.Canonical

  @id_prefix "edcfg"
  @id_field :config_id

  @valid_gap_types [
    :uncertainty,
    :contradiction,
    :missing_evidence,
    :failed_prediction,
    :engineering_blocker
  ]

  @valid_validation_types [:statistical, :robustness, :replay, :audit]

  defstruct [
    :config_id,
    :epoch_id,
    :schema_version,
    # Map from gap_type atom to list of required validation type atoms
    :required_validation_types_by_gap_type,
    # Minimum number of observable mappings per experiment
    :min_evidence_observables,
    # Required stopping condition types (list of string labels)
    :required_stopping_condition_types,
    # Label identifying the seed derivation strategy (e.g. "blake3_from_experiment_id")
    :seed_derivation_strategy
  ]

  @type t :: %__MODULE__{
          config_id: String.t() | nil,
          epoch_id: String.t() | nil,
          schema_version: String.t() | nil,
          required_validation_types_by_gap_type: %{atom() => [atom()]} | nil,
          min_evidence_observables: pos_integer() | nil,
          required_stopping_condition_types: [String.t()] | nil,
          seed_derivation_strategy: String.t() | nil
        }

  @doc """
  Constructs and validates an ExperimentDesignConfig.

  Required keys:
  - :epoch_id (String.t)
  - :schema_version (String.t)
  - :required_validation_types_by_gap_type (map — keys are gap_type atoms,
    values are lists of validation type atoms)
  - :min_evidence_observables (pos_integer)
  - :required_stopping_condition_types ([String.t()] — non-empty list)
  - :seed_derivation_strategy (String.t)

  The :config_id is computed from the other fields; do not supply it.
  """
  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts) when is_list(opts) do
    config = %__MODULE__{
      epoch_id: Keyword.get(opts, :epoch_id),
      schema_version: Keyword.get(opts, :schema_version),
      required_validation_types_by_gap_type:
        Keyword.get(opts, :required_validation_types_by_gap_type),
      min_evidence_observables: Keyword.get(opts, :min_evidence_observables),
      required_stopping_condition_types:
        Keyword.get(opts, :required_stopping_condition_types),
      seed_derivation_strategy: Keyword.get(opts, :seed_derivation_strategy)
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

  @doc "Returns the set of valid gap types this config recognises."
  @spec valid_gap_types() :: [atom()]
  def valid_gap_types, do: @valid_gap_types

  @doc "Returns the set of valid validation type labels."
  @spec valid_validation_types() :: [atom()]
  def valid_validation_types, do: @valid_validation_types

  @spec validate(t()) :: :ok | {:error, String.t()}
  defp validate(%__MODULE__{epoch_id: nil}),
    do: {:error, "ExperimentDesignConfig: epoch_id is required"}

  defp validate(%__MODULE__{epoch_id: v}) when not is_binary(v) or v == "",
    do: {:error, "ExperimentDesignConfig: epoch_id must be a non-empty string"}

  defp validate(%__MODULE__{schema_version: nil}),
    do: {:error, "ExperimentDesignConfig: schema_version is required"}

  defp validate(%__MODULE__{schema_version: v}) when not is_binary(v) or v == "",
    do: {:error, "ExperimentDesignConfig: schema_version must be a non-empty string"}

  defp validate(%__MODULE__{required_validation_types_by_gap_type: nil}),
    do: {:error, "ExperimentDesignConfig: required_validation_types_by_gap_type is required"}

  defp validate(%__MODULE__{required_validation_types_by_gap_type: v}) when not is_map(v),
    do: {:error,
         "ExperimentDesignConfig: required_validation_types_by_gap_type must be a map"}

  defp validate(%__MODULE__{required_validation_types_by_gap_type: vtmap} = c) do
    invalid_keys = Map.keys(vtmap) |> Enum.reject(&(&1 in @valid_gap_types))

    if invalid_keys != [] do
      {:error,
       "ExperimentDesignConfig: unknown gap types in required_validation_types_by_gap_type: " <>
         inspect(invalid_keys)}
    else
      invalid_values =
        Enum.flat_map(vtmap, fn {_gap_type, vts} ->
          if is_list(vts) do
            Enum.reject(vts, &(&1 in @valid_validation_types))
          else
            [:not_a_list]
          end
        end)

      if invalid_values != [] do
        {:error,
         "ExperimentDesignConfig: unknown validation types: #{inspect(invalid_values)}"}
      else
        validate_remaining(c)
      end
    end
  end

  defp validate_remaining(%__MODULE__{min_evidence_observables: nil}),
    do: {:error, "ExperimentDesignConfig: min_evidence_observables is required"}

  defp validate_remaining(%__MODULE__{min_evidence_observables: v})
       when not is_integer(v) or v < 1,
       do: {:error, "ExperimentDesignConfig: min_evidence_observables must be a positive integer"}

  defp validate_remaining(%__MODULE__{required_stopping_condition_types: nil}),
    do: {:error, "ExperimentDesignConfig: required_stopping_condition_types is required"}

  defp validate_remaining(%__MODULE__{required_stopping_condition_types: v})
       when not is_list(v) or v == [],
       do: {:error,
            "ExperimentDesignConfig: required_stopping_condition_types must be a non-empty list"}

  defp validate_remaining(%__MODULE__{seed_derivation_strategy: nil}),
    do: {:error, "ExperimentDesignConfig: seed_derivation_strategy is required"}

  defp validate_remaining(%__MODULE__{seed_derivation_strategy: v})
       when not is_binary(v) or v == "",
       do: {:error,
            "ExperimentDesignConfig: seed_derivation_strategy must be a non-empty string"}

  defp validate_remaining(%__MODULE__{}), do: :ok
end
