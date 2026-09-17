defmodule TiannaraRuntime.WorldModel.AutonomousResearch.ExperimentDesignRecord do
  @moduledoc """
  Phase 17.8.3 — ExperimentDesignRecord: the complete experiment design artifact
  produced by the ARPEExperimentPlanner for a single ResearchProgram.

  This is the Phase 17.8 realisation of the Phase 16.1 ResearchExperiment schema
  combined with the SimulationScenarioBinding. It contains:
  - the full experiment specification (variables, controls, treatments, power)
  - the binding to the Digital Twin scenario
  - the required validation types derived from the originating gap type
  - the stopping conditions
  - all lineage references (program, gap, priority record)

  Constitutional rules:
  - All field values come from the caller — no hardcoded defaults.
  - content-addressed ID via TiannaraRuntime.Shared.Canonical.
  - Immutable after creation.
  - An empty evidence_observable_mappings list is rejected at construction time.
  - The deterministic_seed must be explicitly supplied (derived from program
    and gap IDs by the planner, not generated here).
  """

  alias TiannaraRuntime.Shared.Canonical

  @id_prefix "edr"
  @id_field :design_record_id

  @valid_validation_types [:statistical, :robustness, :replay, :audit]
  @valid_stopping_condition_types [:confidence_reached, :budget_exhausted, :effect_size_met, :max_ticks_reached]

  defstruct [
    :design_record_id,
    :program_id,
    :knowledge_gap_id,
    :priority_record_id,
    :epoch_id,
    :design_config_id,
    :schema_version,
    # Experiment specification
    :measurement_definitions,
    :sampling_plan,
    :robustness_design,
    :evidence_to_measurement_mapping,
    :required_validation_types,
    :stopping_criteria,
    # Scenario binding fields (from SimulationScenarioBinding)
    :scenario_name,
    :variable_mappings,
    :evidence_observable_mappings,
    :stopping_condition_mappings,
    :deterministic_seed,
    :total_ticks
  ]

  @type measurement_definition :: %{
          measurement_key: String.t(),
          observable: String.t(),
          units: String.t()
        }

  @type evidence_mapping :: %{
          evidence_field: String.t(),
          measurement_key: String.t(),
          transform_spec: String.t()
        }

  @type stopping_criterion :: %{
          criterion_type: atom(),
          threshold_ref: String.t(),
          direction: :up | :down | :reach
        }

  @type t :: %__MODULE__{
          design_record_id: String.t() | nil,
          program_id: String.t() | nil,
          knowledge_gap_id: String.t() | nil,
          priority_record_id: String.t() | nil,
          epoch_id: String.t() | nil,
          design_config_id: String.t() | nil,
          schema_version: String.t() | nil,
          measurement_definitions: [measurement_definition()] | nil,
          sampling_plan: map() | nil,
          robustness_design: map() | nil,
          evidence_to_measurement_mapping: [evidence_mapping()] | nil,
          required_validation_types: [atom()] | nil,
          stopping_criteria: [stopping_criterion()] | nil,
          scenario_name: String.t() | nil,
          variable_mappings: [map()] | nil,
          evidence_observable_mappings: [map()] | nil,
          stopping_condition_mappings: [map()] | nil,
          deterministic_seed: String.t() | nil,
          total_ticks: pos_integer() | nil
        }

  @doc """
  Constructs and validates an ExperimentDesignRecord. All domain values must
  be supplied by the caller.

  Required keys:
  - :program_id (String.t)
  - :knowledge_gap_id (String.t)
  - :priority_record_id (String.t)
  - :epoch_id (String.t)
  - :design_config_id (String.t)
  - :schema_version (String.t)
  - :measurement_definitions ([measurement_definition()])
  - :sampling_plan (map)
  - :robustness_design (map)
  - :evidence_to_measurement_mapping ([evidence_mapping()])
  - :required_validation_types ([atom()] — subset of #{inspect(@valid_validation_types)})
  - :stopping_criteria ([stopping_criterion()] — non-empty)
  - :scenario_name (String.t)
  - :variable_mappings ([map()])
  - :evidence_observable_mappings ([map()] — non-empty: empty means no evidence)
  - :stopping_condition_mappings ([map()])
  - :deterministic_seed (String.t — content-addressed, not random)
  - :total_ticks (pos_integer)

  The :design_record_id is computed from the other fields; do not supply it.
  """
  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts) when is_list(opts) do
    record = %__MODULE__{
      program_id: Keyword.get(opts, :program_id),
      knowledge_gap_id: Keyword.get(opts, :knowledge_gap_id),
      priority_record_id: Keyword.get(opts, :priority_record_id),
      epoch_id: Keyword.get(opts, :epoch_id),
      design_config_id: Keyword.get(opts, :design_config_id),
      schema_version: Keyword.get(opts, :schema_version),
      measurement_definitions: Keyword.get(opts, :measurement_definitions),
      sampling_plan: Keyword.get(opts, :sampling_plan),
      robustness_design: Keyword.get(opts, :robustness_design),
      evidence_to_measurement_mapping: Keyword.get(opts, :evidence_to_measurement_mapping),
      required_validation_types: Keyword.get(opts, :required_validation_types),
      stopping_criteria: Keyword.get(opts, :stopping_criteria),
      scenario_name: Keyword.get(opts, :scenario_name),
      variable_mappings: Keyword.get(opts, :variable_mappings),
      evidence_observable_mappings: Keyword.get(opts, :evidence_observable_mappings),
      stopping_condition_mappings: Keyword.get(opts, :stopping_condition_mappings),
      deterministic_seed: Keyword.get(opts, :deterministic_seed),
      total_ticks: Keyword.get(opts, :total_ticks)
    }

    with :ok <- validate(record) do
      id = Canonical.generate_id(record, @id_field, @id_prefix)
      {:ok, %{record | design_record_id: id}}
    end
  end

  @spec verify_id(t()) :: :ok | {:error, String.t()}
  def verify_id(%__MODULE__{} = record) do
    Canonical.verify_id(record, @id_field, @id_prefix)
  end

  @spec validate(t()) :: :ok | {:error, String.t()}
  defp validate(%__MODULE__{program_id: nil}),
    do: {:error, "ExperimentDesignRecord: program_id is required"}

  defp validate(%__MODULE__{program_id: v}) when not is_binary(v) or v == "",
    do: {:error, "ExperimentDesignRecord: program_id must be a non-empty string"}

  defp validate(%__MODULE__{knowledge_gap_id: nil}),
    do: {:error, "ExperimentDesignRecord: knowledge_gap_id is required"}

  defp validate(%__MODULE__{knowledge_gap_id: v}) when not is_binary(v) or v == "",
    do: {:error, "ExperimentDesignRecord: knowledge_gap_id must be a non-empty string"}

  defp validate(%__MODULE__{priority_record_id: nil}),
    do: {:error, "ExperimentDesignRecord: priority_record_id is required"}

  defp validate(%__MODULE__{priority_record_id: v}) when not is_binary(v) or v == "",
    do: {:error, "ExperimentDesignRecord: priority_record_id must be a non-empty string"}

  defp validate(%__MODULE__{epoch_id: nil}),
    do: {:error, "ExperimentDesignRecord: epoch_id is required"}

  defp validate(%__MODULE__{epoch_id: v}) when not is_binary(v) or v == "",
    do: {:error, "ExperimentDesignRecord: epoch_id must be a non-empty string"}

  defp validate(%__MODULE__{design_config_id: nil}),
    do: {:error, "ExperimentDesignRecord: design_config_id is required"}

  defp validate(%__MODULE__{design_config_id: v}) when not is_binary(v) or v == "",
    do: {:error, "ExperimentDesignRecord: design_config_id must be a non-empty string"}

  defp validate(%__MODULE__{schema_version: nil}),
    do: {:error, "ExperimentDesignRecord: schema_version is required"}

  defp validate(%__MODULE__{schema_version: v}) when not is_binary(v) or v == "",
    do: {:error, "ExperimentDesignRecord: schema_version must be a non-empty string"}

  defp validate(%__MODULE__{measurement_definitions: nil}),
    do: {:error, "ExperimentDesignRecord: measurement_definitions is required"}

  defp validate(%__MODULE__{measurement_definitions: v}) when not is_list(v),
    do: {:error, "ExperimentDesignRecord: measurement_definitions must be a list"}

  defp validate(%__MODULE__{sampling_plan: nil}),
    do: {:error, "ExperimentDesignRecord: sampling_plan is required"}

  defp validate(%__MODULE__{sampling_plan: v}) when not is_map(v),
    do: {:error, "ExperimentDesignRecord: sampling_plan must be a map"}

  defp validate(%__MODULE__{robustness_design: nil}),
    do: {:error, "ExperimentDesignRecord: robustness_design is required"}

  defp validate(%__MODULE__{robustness_design: v}) when not is_map(v),
    do: {:error, "ExperimentDesignRecord: robustness_design must be a map"}

  defp validate(%__MODULE__{evidence_to_measurement_mapping: nil}),
    do: {:error, "ExperimentDesignRecord: evidence_to_measurement_mapping is required"}

  defp validate(%__MODULE__{evidence_to_measurement_mapping: v}) when not is_list(v),
    do: {:error, "ExperimentDesignRecord: evidence_to_measurement_mapping must be a list"}

  defp validate(%__MODULE__{required_validation_types: nil}),
    do: {:error, "ExperimentDesignRecord: required_validation_types is required"}

  defp validate(%__MODULE__{required_validation_types: v}) when not is_list(v),
    do: {:error, "ExperimentDesignRecord: required_validation_types must be a list"}

  defp validate(%__MODULE__{required_validation_types: vts} = r) do
    invalid = Enum.reject(vts, &(&1 in @valid_validation_types))

    if invalid != [] do
      {:error,
       "ExperimentDesignRecord: unknown validation types #{inspect(invalid)}; " <>
         "valid: #{inspect(@valid_validation_types)}"}
    else
      validate_stopping_criteria(r)
    end
  end

  defp validate_stopping_criteria(%__MODULE__{stopping_criteria: nil}),
    do: {:error, "ExperimentDesignRecord: stopping_criteria is required"}

  defp validate_stopping_criteria(%__MODULE__{stopping_criteria: v}) when not is_list(v) or v == [],
    do: {:error, "ExperimentDesignRecord: stopping_criteria must be a non-empty list"}

  defp validate_stopping_criteria(%__MODULE__{stopping_criteria: criteria} = r) do
    invalid =
      Enum.reject(criteria, fn c ->
        is_map(c) and Map.has_key?(c, :criterion_type) and
          c.criterion_type in @valid_stopping_condition_types
      end)

    if invalid != [] do
      {:error,
       "ExperimentDesignRecord: stopping_criteria contains invalid entries; " <>
         "each must be a map with criterion_type one of " <>
         inspect(@valid_stopping_condition_types)}
    else
      validate_scenario_fields(r)
    end
  end

  defp validate_scenario_fields(%__MODULE__{scenario_name: nil}),
    do: {:error, "ExperimentDesignRecord: scenario_name is required"}

  defp validate_scenario_fields(%__MODULE__{scenario_name: v}) when not is_binary(v) or v == "",
    do: {:error, "ExperimentDesignRecord: scenario_name must be a non-empty string"}

  defp validate_scenario_fields(%__MODULE__{variable_mappings: nil}),
    do: {:error, "ExperimentDesignRecord: variable_mappings is required"}

  defp validate_scenario_fields(%__MODULE__{variable_mappings: v}) when not is_list(v),
    do: {:error, "ExperimentDesignRecord: variable_mappings must be a list"}

  defp validate_scenario_fields(%__MODULE__{evidence_observable_mappings: nil}),
    do: {:error, "ExperimentDesignRecord: evidence_observable_mappings is required"}

  defp validate_scenario_fields(%__MODULE__{evidence_observable_mappings: v})
       when not is_list(v) or v == [],
       do: {:error,
            "ExperimentDesignRecord: evidence_observable_mappings must be a non-empty list — " <>
              "an experiment with no observable mappings produces no evidence"}

  defp validate_scenario_fields(%__MODULE__{stopping_condition_mappings: nil}),
    do: {:error, "ExperimentDesignRecord: stopping_condition_mappings is required"}

  defp validate_scenario_fields(%__MODULE__{stopping_condition_mappings: v}) when not is_list(v),
    do: {:error, "ExperimentDesignRecord: stopping_condition_mappings must be a list"}

  defp validate_scenario_fields(%__MODULE__{deterministic_seed: nil}),
    do: {:error, "ExperimentDesignRecord: deterministic_seed is required"}

  defp validate_scenario_fields(%__MODULE__{deterministic_seed: v})
       when not is_binary(v) or v == "",
       do: {:error, "ExperimentDesignRecord: deterministic_seed must be a non-empty string"}

  defp validate_scenario_fields(%__MODULE__{total_ticks: nil}),
    do: {:error, "ExperimentDesignRecord: total_ticks is required"}

  defp validate_scenario_fields(%__MODULE__{total_ticks: v}) when not is_integer(v) or v < 1,
    do: {:error, "ExperimentDesignRecord: total_ticks must be a positive integer"}

  defp validate_scenario_fields(%__MODULE__{}), do: :ok
end
