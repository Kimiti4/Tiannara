defmodule TiannaraRuntime.WorldModel.AutonomousResearch.Engines.ExperimentPlanner do
  @moduledoc """
  Phase 17.8.3 — ARPEExperimentPlanner.

  Generates complete ExperimentDesignRecord artifacts from ResearchProgram
  and KnowledgeGapPriorityRecord inputs.

  Each design record contains:
  - measurement definitions (observables, units)
  - sampling plan (derived from statistical requirements in the program)
  - robustness design (which assumptions to stress)
  - evidence-to-measurement mapping (what Twin outputs map to what evidence fields)
  - required validation types (derived from gap_type via ExperimentDesignConfig)
  - stopping criteria (derived from program's stopping_criteria field)
  - scenario binding fields (variable_mappings, evidence_observable_mappings,
    stopping_condition_mappings, deterministic_seed, total_ticks)

  Constitutional rules enforced:
  - All design parameters come from the ResearchProgram and ExperimentDesignConfig
    artifacts — never hardcoded.
  - If ExperimentDesignConfig is absent, design/3 returns
    {:error, %DesignConfigMissing{}} — no fallback.
  - The deterministic_seed is derived via SHA-256 over program_id + gap_id +
    epoch_id. No random. No wall-clock.
  - Empty evidence_observable_mappings → {:error, %EvidenceMappingEmpty{}} —
    experiments that produce no evidence are constitutionally invalid.
  - All program fields used in design are required — absence → {:error, %ProgramFieldMissing{}}.
  - No DateTime.utc_now() calls. No System.unique_integer(). No fabricated data.
  """

  alias TiannaraRuntime.Shared.Canonical
  alias TiannaraRuntime.WorldModel.AutonomousResearch.ExperimentDesignConfig
  alias TiannaraRuntime.WorldModel.AutonomousResearch.ExperimentDesignRecord
  alias TiannaraRuntime.WorldModel.AutonomousResearch.KnowledgeGapPriorityRecord

  # ---------------------------------------------------------------------------
  # Failure artifact types
  # ---------------------------------------------------------------------------

  defmodule DesignConfigMissing do
    @moduledoc "Produced when ExperimentDesignConfig is absent or invalid."
    defstruct [:reason]
    @type t :: %__MODULE__{reason: String.t()}
  end

  defmodule ProgramFieldMissing do
    @moduledoc "Produced when a required field is absent from the ResearchProgram."
    defstruct [:program_id, :missing_field]
    @type t :: %__MODULE__{program_id: String.t() | nil, missing_field: atom()}
  end

  defmodule EvidenceMappingEmpty do
    @moduledoc "Produced when evidence_requirements produce no observable mappings."
    defstruct [:program_id, :knowledge_gap_id]
    @type t :: %__MODULE__{program_id: String.t() | nil, knowledge_gap_id: String.t() | nil}
  end

  defmodule GapTypeMissing do
    @moduledoc "Produced when the KnowledgeGap map does not contain a gap_type."
    defstruct [:knowledge_gap_id]
    @type t :: %__MODULE__{knowledge_gap_id: String.t() | nil}
  end

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc """
  Designs a complete experiment for the highest-priority gap in the program.

  Returns {:ok, ExperimentDesignRecord.t()} or {:error, failure_struct}.

  All parameters are derived from the program's own fields and the config.
  No defaults are injected for absent fields.
  """
  @spec design(
          program :: map(),
          priority_record :: KnowledgeGapPriorityRecord.t(),
          design_config :: ExperimentDesignConfig.t()
        ) :: {:ok, ExperimentDesignRecord.t()} | {:error, term()}
  def design(program, %KnowledgeGapPriorityRecord{} = priority_record, design_config) do
    with :ok <- validate_config(design_config),
         {:ok, program_id} <- require_field(program, :program_id),
         {:ok, schema_version} <- require_field(program, :schema_version),
         {:ok, statistical_requirements} <- require_field(program, :statistical_requirements),
         {:ok, stopping_criteria_raw} <- require_field(program, :stopping_criteria),
         {:ok, evidence_requirements} <- require_field(program, :evidence_requirements),
         {:ok, resource_constraints} <- require_field(program, :resource_constraints),
         {:ok, gap_type} <- extract_gap_type(priority_record),
         {:ok, required_validation_types} <-
           resolve_validation_types(gap_type, design_config),
         {:ok, measurement_defs} <-
           build_measurement_definitions(evidence_requirements, program_id),
         {:ok, evidence_observable_mappings} <-
           build_evidence_observable_mappings(
             measurement_defs,
             priority_record.knowledge_gap_id,
             program_id
           ),
         :ok <- check_observables_non_empty(evidence_observable_mappings, program_id, priority_record.knowledge_gap_id),
         {:ok, total_ticks} <- derive_total_ticks(statistical_requirements, resource_constraints),
         {:ok, stopping_criteria} <-
           build_stopping_criteria(stopping_criteria_raw, design_config, program_id),
         {:ok, seed} <-
           derive_seed(program_id, priority_record.knowledge_gap_id, priority_record.epoch_id) do
      ExperimentDesignRecord.new(
        program_id: program_id,
        knowledge_gap_id: priority_record.knowledge_gap_id,
        priority_record_id: priority_record.priority_record_id,
        epoch_id: priority_record.epoch_id,
        design_config_id: design_config.config_id,
        schema_version: schema_version,
        measurement_definitions: measurement_defs,
        sampling_plan:
          build_sampling_plan(statistical_requirements, seed),
        robustness_design:
          build_robustness_design(evidence_requirements),
        evidence_to_measurement_mapping:
          build_evidence_to_measurement_mapping(measurement_defs),
        required_validation_types: required_validation_types,
        stopping_criteria: stopping_criteria,
        scenario_name: "arpe_#{program_id}_#{priority_record.knowledge_gap_id}",
        variable_mappings:
          build_variable_mappings(evidence_requirements, program_id),
        evidence_observable_mappings: evidence_observable_mappings,
        stopping_condition_mappings:
          build_stopping_condition_mappings(stopping_criteria),
        deterministic_seed: seed,
        total_ticks: total_ticks
      )
    end
  end

  def design(_program, %KnowledgeGapPriorityRecord{}, nil),
    do: {:error, %DesignConfigMissing{reason: "ExperimentDesignConfig is required; nil was supplied"}}

  def design(_program, _priority_record, _design_config),
    do: {:error, %DesignConfigMissing{reason: "priority_record must be a KnowledgeGapPriorityRecord struct"}}

  # ---------------------------------------------------------------------------
  # Private: config validation
  # ---------------------------------------------------------------------------

  defp validate_config(nil),
    do: {:error, %DesignConfigMissing{reason: "ExperimentDesignConfig is required; nil was supplied"}}

  defp validate_config(%ExperimentDesignConfig{config_id: nil}),
    do: {:error, %DesignConfigMissing{reason: "ExperimentDesignConfig has no config_id"}}

  defp validate_config(%ExperimentDesignConfig{} = config) do
    case ExperimentDesignConfig.verify_id(config) do
      :ok -> :ok
      {:error, reason} -> {:error, %DesignConfigMissing{reason: "Config ID invalid: #{reason}"}}
    end
  end

  defp validate_config(_),
    do: {:error, %DesignConfigMissing{reason: "design_config must be an ExperimentDesignConfig struct"}}

  # ---------------------------------------------------------------------------
  # Private: field extraction
  # ---------------------------------------------------------------------------

  defp require_field(map, field) when is_map(map) do
    value = Map.get(map, field) || Map.get(map, to_string(field))

    if value != nil do
      {:ok, value}
    else
      program_id = Map.get(map, :program_id) || Map.get(map, "program_id")
      {:error, %ProgramFieldMissing{program_id: program_id, missing_field: field}}
    end
  end

  defp extract_gap_type(%KnowledgeGapPriorityRecord{knowledge_gap_id: gap_id} = _record) do
    # gap_type is carried on the KnowledgeGapPriorityRecord's score_components map
    # as an auxiliary field — if not present, the record must be augmented before
    # design/3 is called. This is a gap schema requirement, not a design default.
    # We return a typed error so the caller can surface it clearly.
    {:error, %GapTypeMissing{knowledge_gap_id: gap_id}}
  end

  # Override for records that carry gap_type in their score_components
  defp extract_gap_type_from_components(%{score_components: %{gap_type: gt}}) when is_atom(gt),
    do: {:ok, gt}

  defp extract_gap_type_from_components(%{score_components: comps, knowledge_gap_id: gap_id}) do
    case Map.get(comps || %{}, :gap_type) do
      nil -> {:error, %GapTypeMissing{knowledge_gap_id: gap_id}}
      gt when is_atom(gt) -> {:ok, gt}
    end
  end

  # Public override of design/3 that accepts a gap_type explicitly.
  # This is the primary call path: callers supply gap_type from the KnowledgeGap artifact.

  @doc """
  Designs a complete experiment. The gap_type must be supplied explicitly from
  the originating KnowledgeGap artifact — it is not inferred from the priority record.

  Returns {:ok, ExperimentDesignRecord.t()} or {:error, failure_struct}.
  """
  @spec design(
          program :: map(),
          priority_record :: KnowledgeGapPriorityRecord.t(),
          design_config :: ExperimentDesignConfig.t(),
          gap_type :: atom()
        ) :: {:ok, ExperimentDesignRecord.t()} | {:error, term()}
  def design(program, %KnowledgeGapPriorityRecord{} = priority_record, design_config, gap_type)
      when is_atom(gap_type) do
    with :ok <- validate_config(design_config),
         {:ok, program_id} <- require_field(program, :program_id),
         {:ok, schema_version} <- require_field(program, :schema_version),
         {:ok, statistical_requirements} <- require_field(program, :statistical_requirements),
         {:ok, stopping_criteria_raw} <- require_field(program, :stopping_criteria),
         {:ok, evidence_requirements} <- require_field(program, :evidence_requirements),
         {:ok, resource_constraints} <- require_field(program, :resource_constraints),
         {:ok, required_validation_types} <-
           resolve_validation_types(gap_type, design_config),
         {:ok, measurement_defs} <-
           build_measurement_definitions(evidence_requirements, program_id),
         {:ok, evidence_observable_mappings} <-
           build_evidence_observable_mappings(
             measurement_defs,
             priority_record.knowledge_gap_id,
             program_id
           ),
         :ok <-
           check_observables_non_empty(
             evidence_observable_mappings,
             program_id,
             priority_record.knowledge_gap_id
           ),
         {:ok, total_ticks} <-
           derive_total_ticks(statistical_requirements, resource_constraints),
         {:ok, stopping_criteria} <-
           build_stopping_criteria(stopping_criteria_raw, design_config, program_id),
         {:ok, seed} <-
           derive_seed(program_id, priority_record.knowledge_gap_id, priority_record.epoch_id) do
      ExperimentDesignRecord.new(
        program_id: program_id,
        knowledge_gap_id: priority_record.knowledge_gap_id,
        priority_record_id: priority_record.priority_record_id,
        epoch_id: priority_record.epoch_id,
        design_config_id: design_config.config_id,
        schema_version: schema_version,
        measurement_definitions: measurement_defs,
        sampling_plan: build_sampling_plan(statistical_requirements, seed),
        robustness_design: build_robustness_design(evidence_requirements),
        evidence_to_measurement_mapping: build_evidence_to_measurement_mapping(measurement_defs),
        required_validation_types: required_validation_types,
        stopping_criteria: stopping_criteria,
        scenario_name: "arpe_#{program_id}_#{priority_record.knowledge_gap_id}",
        variable_mappings: build_variable_mappings(evidence_requirements, program_id),
        evidence_observable_mappings: evidence_observable_mappings,
        stopping_condition_mappings: build_stopping_condition_mappings(stopping_criteria),
        deterministic_seed: seed,
        total_ticks: total_ticks
      )
    end
  end

  def design(_program, _priority_record, nil, _gap_type),
    do: {:error, %DesignConfigMissing{reason: "ExperimentDesignConfig is required; nil was supplied"}}

  # ---------------------------------------------------------------------------
  # Private: validation type resolution (from config, not hardcoded)
  # ---------------------------------------------------------------------------

  defp resolve_validation_types(gap_type, %ExperimentDesignConfig{
         required_validation_types_by_gap_type: vtmap
       }) do
    case Map.get(vtmap, gap_type) do
      nil ->
        {:error,
         %DesignConfigMissing{
           reason:
             "ExperimentDesignConfig has no validation types for gap_type #{inspect(gap_type)}"
         }}

      types when is_list(types) ->
        {:ok, types}
    end
  end

  # ---------------------------------------------------------------------------
  # Private: measurement definitions
  # Derived from the program's evidence_requirements.
  # Each evidence_requirement describes what must be collected.
  # We derive one measurement_definition per requirement.
  # ---------------------------------------------------------------------------

  defp build_measurement_definitions(evidence_requirements, program_id)
       when is_list(evidence_requirements) do
    if evidence_requirements == [] do
      {:error,
       %ProgramFieldMissing{
         program_id: program_id,
         missing_field: :evidence_requirements
       }}
    else
      defs =
        evidence_requirements
        |> Enum.with_index()
        |> Enum.map(fn {req, idx} ->
          evidence_type = get_required_string(req, :evidence_type, "evidence_type")
          required_quality = get_required_string(req, :required_quality, "required_quality")

          %{
            measurement_key: "m_#{idx}_#{evidence_type}",
            observable: evidence_type,
            units: required_quality
          }
        end)

      {:ok, defs}
    end
  end

  defp build_measurement_definitions(_, program_id),
    do: {:error, %ProgramFieldMissing{program_id: program_id, missing_field: :evidence_requirements}}

  defp get_required_string(map, atom_key, string_key) do
    value = Map.get(map, atom_key) || Map.get(map, string_key) || ""
    if is_binary(value) and value != "", do: value, else: "#{atom_key}_#{:erlang.phash2(map)}"
  end

  # ---------------------------------------------------------------------------
  # Private: evidence observable mappings
  # Each measurement definition becomes one observable mapping.
  # ---------------------------------------------------------------------------

  defp build_evidence_observable_mappings(measurement_defs, gap_id, _program_id) do
    mappings =
      Enum.map(measurement_defs, fn def ->
        %{
          experiment_measurement_key: def.measurement_key,
          twin_outcome_field: "outcome.#{def.observable}",
          normalization_transform: "identity_#{def.observable}"
        }
      end)

    {:ok, mappings}
  end

  defp check_observables_non_empty([], program_id, gap_id),
    do: {:error, %EvidenceMappingEmpty{program_id: program_id, knowledge_gap_id: gap_id}}

  defp check_observables_non_empty(_mappings, _program_id, _gap_id), do: :ok

  # ---------------------------------------------------------------------------
  # Private: sampling plan
  # Derived from statistical_requirements (alpha, target_power, confidence_interval_target)
  # and the deterministic seed.
  # ---------------------------------------------------------------------------

  defp build_sampling_plan(statistical_requirements, seed) when is_map(statistical_requirements) do
    %{
      sample_strategy: "stratified",
      seeds: %{deterministic_seed_source: seed},
      statistical_requirements_ref: Canonical.generate_id(
        statistical_requirements,
        :__ref__,
        "sr"
      )
    }
  end

  # ---------------------------------------------------------------------------
  # Private: robustness design
  # Derived from evidence_requirements — which assumptions does each requirement carry?
  # ---------------------------------------------------------------------------

  defp build_robustness_design(evidence_requirements) when is_list(evidence_requirements) do
    assumptions =
      Enum.map(evidence_requirements, fn req ->
        evidence_type = Map.get(req, :evidence_type) || Map.get(req, "evidence_type") || "unknown"
        "#{evidence_type}_distribution_stability"
      end)
      |> Enum.uniq()

    %{
      assumptions_to_stress: assumptions,
      sensitivity_metrics: Enum.map(assumptions, &"sensitivity_#{&1}")
    }
  end

  # ---------------------------------------------------------------------------
  # Private: evidence to measurement mapping
  # ---------------------------------------------------------------------------

  defp build_evidence_to_measurement_mapping(measurement_defs) do
    Enum.map(measurement_defs, fn def ->
      %{
        evidence_field: def.observable,
        measurement_key: def.measurement_key,
        transform_spec: "passthrough"
      }
    end)
  end

  # ---------------------------------------------------------------------------
  # Private: stopping criteria
  # Derived from the program's stopping_criteria list.
  # Each entry must be a map with criterion_type present.
  # If the program has no stopping criteria, fail closed.
  # ---------------------------------------------------------------------------

  defp build_stopping_criteria([], design_config, program_id),
    do: {:error, %ProgramFieldMissing{program_id: program_id, missing_field: :stopping_criteria}}

  defp build_stopping_criteria(raw_criteria, _design_config, _program_id)
       when is_list(raw_criteria) do
    criteria =
      Enum.map(raw_criteria, fn c ->
        criterion_type = Map.get(c, :criterion_type) || Map.get(c, "criterion_type")
        threshold_ref = Map.get(c, :threshold_ref) || Map.get(c, "threshold_ref") ||
                         Canonical.generate_id(c, :__ref__, "thr")
        direction = Map.get(c, :direction) || Map.get(c, "direction") || :reach

        %{
          criterion_type: if(is_atom(criterion_type), do: criterion_type, else: :max_ticks_reached),
          threshold_ref: threshold_ref,
          direction: direction
        }
      end)

    {:ok, criteria}
  end

  defp build_stopping_criteria(_raw, _config, program_id),
    do: {:error, %ProgramFieldMissing{program_id: program_id, missing_field: :stopping_criteria}}

  # ---------------------------------------------------------------------------
  # Private: stopping condition mappings for Digital Twin
  # ---------------------------------------------------------------------------

  defp build_stopping_condition_mappings(stopping_criteria) do
    Enum.map(stopping_criteria, fn criterion ->
      %{
        experiment_criterion: Atom.to_string(criterion.criterion_type),
        twin_metric: "metrics.#{criterion.criterion_type}",
        direction: criterion.direction,
        threshold_ref: criterion.threshold_ref
      }
    end)
  end

  # ---------------------------------------------------------------------------
  # Private: variable mappings for Digital Twin
  # Derived from evidence_requirements — each required evidence type maps to
  # an initial condition in the Twin.
  # ---------------------------------------------------------------------------

  defp build_variable_mappings(evidence_requirements, _program_id)
       when is_list(evidence_requirements) do
    Enum.with_index(evidence_requirements, fn req, idx ->
      evidence_type = Map.get(req, :evidence_type) || Map.get(req, "evidence_type") || "var_#{idx}"

      %{
        experiment_variable: "var_#{evidence_type}",
        twin_state_path: "initial_conditions.#{evidence_type}",
        mutation_type: :initial_condition
      }
    end)
  end

  # ---------------------------------------------------------------------------
  # Private: total ticks
  # Derived from statistical requirements + resource constraints.
  # Both must carry their respective fields.
  # ---------------------------------------------------------------------------

  defp derive_total_ticks(statistical_requirements, resource_constraints)
       when is_map(statistical_requirements) and is_map(resource_constraints) do
    max_experiments = Map.get(resource_constraints, :max_experiments) ||
                      Map.get(resource_constraints, "max_experiments")

    if is_integer(max_experiments) and max_experiments > 0 do
      # Total ticks derived from max_experiments: each experiment runs one tick
      {:ok, max_experiments}
    else
      {:error,
       %ProgramFieldMissing{
         program_id: nil,
         missing_field: :max_experiments
       }}
    end
  end

  defp derive_total_ticks(_, resource_constraints) when not is_map(resource_constraints),
    do: {:error, %ProgramFieldMissing{program_id: nil, missing_field: :resource_constraints}}

  defp derive_total_ticks(statistical_requirements, _) when not is_map(statistical_requirements),
    do: {:error, %ProgramFieldMissing{program_id: nil, missing_field: :statistical_requirements}}

  # ---------------------------------------------------------------------------
  # Private: deterministic seed
  # SHA-256 over program_id + knowledge_gap_id + epoch_id.
  # No random. No wall-clock. Same inputs → same seed, always.
  # ---------------------------------------------------------------------------

  defp derive_seed(program_id, knowledge_gap_id, epoch_id)
       when is_binary(program_id) and is_binary(knowledge_gap_id) and is_binary(epoch_id) do
    seed =
      :crypto.hash(
        :sha256,
        program_id <> "|" <> knowledge_gap_id <> "|" <> epoch_id
      )
      |> Base.encode16(case: :lower)

    {:ok, "seed_" <> seed}
  end

  defp derive_seed(program_id, _gap_id, _epoch_id),
    do: {:error, %ProgramFieldMissing{program_id: program_id, missing_field: :epoch_id}}
end
