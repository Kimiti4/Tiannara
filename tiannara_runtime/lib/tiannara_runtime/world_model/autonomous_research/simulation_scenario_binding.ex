defmodule TiannaraRuntime.WorldModel.AutonomousResearch.SimulationScenarioBinding do
  @moduledoc """
  Phase 17.8.1 — SimulationScenarioBinding: binds a ResearchExperiment to a
  Digital Twin SimulationScenario.

  This is the constitutional bridge between the ARPE experiment design and the
  Phase 17.7 DigitalTwinEngine. It maps experiment variables to Twin state
  mutations, stopping conditions to Twin termination rules, and evidence
  collection requirements to Twin outcome observables.

  Constitutional rules:
  - All field values come from the caller — no hardcoded defaults.
  - content-addressed ID computed via TiannaraRuntime.Shared.Canonical.
  - Immutable after creation.
  - Ambiguous mappings must be rejected at construction time, not at execution time.
  - The deterministic_seed is content-hash-derived, never random.
  """

  alias TiannaraRuntime.Shared.Canonical

  @id_prefix "ssb"
  @id_field :binding_id

  @valid_mutation_types [:initial_condition, :event, :intervention]

  defstruct [
    :binding_id,
    :experiment_id,
    :program_id,
    :scenario,
    :variable_mappings,
    :evidence_observable_mappings,
    :stopping_condition_mappings,
    :deterministic_seed
  ]

  @type scenario :: %{
          name: String.t(),
          initial_conditions: map(),
          events: [map()],
          interventions: [map()],
          total_ticks: non_neg_integer(),
          metrics_config: [String.t()]
        }

  @type variable_mapping :: %{
          experiment_variable: String.t(),
          twin_state_path: String.t(),
          mutation_type: :initial_condition | :event | :intervention
        }

  @type evidence_observable_mapping :: %{
          experiment_measurement_key: String.t(),
          twin_outcome_field: String.t(),
          normalization_transform: String.t()
        }

  @type stopping_condition_mapping :: %{
          experiment_criterion: String.t(),
          twin_metric: String.t(),
          direction: :up | :down | :reach,
          threshold_ref: String.t()
        }

  @type t :: %__MODULE__{
          binding_id: String.t() | nil,
          experiment_id: String.t() | nil,
          program_id: String.t() | nil,
          scenario: scenario() | nil,
          variable_mappings: [variable_mapping()] | nil,
          evidence_observable_mappings: [evidence_observable_mapping()] | nil,
          stopping_condition_mappings: [stopping_condition_mapping()] | nil,
          deterministic_seed: String.t() | nil
        }

  @doc """
  Constructs and validates a SimulationScenarioBinding. All domain values must be
  supplied by the caller.

  Required keys:
  - :experiment_id (String.t)
  - :program_id (String.t)
  - :scenario (scenario() map)
  - :variable_mappings ([variable_mapping()])
  - :evidence_observable_mappings ([evidence_observable_mapping()])
  - :stopping_condition_mappings ([stopping_condition_mapping()])
  - :deterministic_seed (String.t — must be a content-addressed hash, not a random value)

  The :binding_id is computed from the other fields; do not supply it.

  Returns {:error, reason} if any evidence mapping is ambiguous (missing keys).
  Ambiguous mappings must not produce a partial binding.
  """
  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts) when is_list(opts) do
    binding = %__MODULE__{
      experiment_id: Keyword.get(opts, :experiment_id),
      program_id: Keyword.get(opts, :program_id),
      scenario: Keyword.get(opts, :scenario),
      variable_mappings: Keyword.get(opts, :variable_mappings),
      evidence_observable_mappings: Keyword.get(opts, :evidence_observable_mappings),
      stopping_condition_mappings: Keyword.get(opts, :stopping_condition_mappings),
      deterministic_seed: Keyword.get(opts, :deterministic_seed)
    }

    with :ok <- validate(binding) do
      id = Canonical.generate_id(binding, @id_field, @id_prefix)
      {:ok, %{binding | binding_id: id}}
    end
  end

  @spec verify_id(t()) :: :ok | {:error, String.t()}
  def verify_id(%__MODULE__{} = binding) do
    Canonical.verify_id(binding, @id_field, @id_prefix)
  end

  @spec validate(t()) :: :ok | {:error, String.t()}
  defp validate(%__MODULE__{experiment_id: nil}),
    do: {:error, "SimulationScenarioBinding: experiment_id is required"}

  defp validate(%__MODULE__{experiment_id: v}) when not is_binary(v) or v == "",
    do: {:error, "SimulationScenarioBinding: experiment_id must be a non-empty string"}

  defp validate(%__MODULE__{program_id: nil}),
    do: {:error, "SimulationScenarioBinding: program_id is required"}

  defp validate(%__MODULE__{program_id: v}) when not is_binary(v) or v == "",
    do: {:error, "SimulationScenarioBinding: program_id must be a non-empty string"}

  defp validate(%__MODULE__{scenario: nil}),
    do: {:error, "SimulationScenarioBinding: scenario is required"}

  defp validate(%__MODULE__{scenario: v}) when not is_map(v),
    do: {:error, "SimulationScenarioBinding: scenario must be a map"}

  defp validate(%__MODULE__{variable_mappings: nil}),
    do: {:error, "SimulationScenarioBinding: variable_mappings is required"}

  defp validate(%__MODULE__{variable_mappings: v}) when not is_list(v),
    do: {:error, "SimulationScenarioBinding: variable_mappings must be a list"}

  defp validate(%__MODULE__{evidence_observable_mappings: nil}),
    do: {:error, "SimulationScenarioBinding: evidence_observable_mappings is required"}

  defp validate(%__MODULE__{evidence_observable_mappings: v}) when not is_list(v),
    do: {:error, "SimulationScenarioBinding: evidence_observable_mappings must be a list"}

  defp validate(%__MODULE__{evidence_observable_mappings: []}),
    do: {:error,
         "SimulationScenarioBinding: evidence_observable_mappings must not be empty — " <>
           "an experiment with no observable mappings produces no evidence"}

  defp validate(%__MODULE__{stopping_condition_mappings: nil}),
    do: {:error, "SimulationScenarioBinding: stopping_condition_mappings is required"}

  defp validate(%__MODULE__{stopping_condition_mappings: v}) when not is_list(v),
    do: {:error, "SimulationScenarioBinding: stopping_condition_mappings must be a list"}

  defp validate(%__MODULE__{deterministic_seed: nil}),
    do: {:error, "SimulationScenarioBinding: deterministic_seed is required"}

  defp validate(%__MODULE__{deterministic_seed: v}) when not is_binary(v) or v == "",
    do: {:error, "SimulationScenarioBinding: deterministic_seed must be a non-empty string"}

  defp validate(%__MODULE__{variable_mappings: vms, evidence_observable_mappings: eoms} = b) do
    with :ok <- validate_variable_mappings(vms),
         :ok <- validate_evidence_mappings(eoms) do
      validate_scenario(b)
    end
  end

  defp validate_variable_mappings([]), do: :ok

  defp validate_variable_mappings([%{mutation_type: mt} | _])
       when mt not in @valid_mutation_types,
       do: {:error,
            "SimulationScenarioBinding: mutation_type must be one of " <>
              "#{inspect(@valid_mutation_types)}"}

  defp validate_variable_mappings([%{experiment_variable: ev} | _])
       when not is_binary(ev) or ev == "",
       do: {:error,
            "SimulationScenarioBinding: each variable_mapping requires a non-empty experiment_variable"}

  defp validate_variable_mappings([%{twin_state_path: tp} | _])
       when not is_binary(tp) or tp == "",
       do: {:error,
            "SimulationScenarioBinding: each variable_mapping requires a non-empty twin_state_path"}

  defp validate_variable_mappings([_ | rest]), do: validate_variable_mappings(rest)

  defp validate_evidence_mappings([]), do: :ok

  defp validate_evidence_mappings([%{experiment_measurement_key: k} | _])
       when not is_binary(k) or k == "",
       do: {:error,
            "SimulationScenarioBinding: each evidence_observable_mapping requires a " <>
              "non-empty experiment_measurement_key"}

  defp validate_evidence_mappings([%{twin_outcome_field: f} | _])
       when not is_binary(f) or f == "",
       do: {:error,
            "SimulationScenarioBinding: each evidence_observable_mapping requires a " <>
              "non-empty twin_outcome_field"}

  defp validate_evidence_mappings([%{normalization_transform: t} | _])
       when not is_binary(t) or t == "",
       do: {:error,
            "SimulationScenarioBinding: each evidence_observable_mapping requires a " <>
              "non-empty normalization_transform"}

  defp validate_evidence_mappings([_ | rest]), do: validate_evidence_mappings(rest)

  defp validate_scenario(%__MODULE__{scenario: scenario}) do
    cond do
      not is_map_key(scenario, :name) and not is_map_key(scenario, "name") ->
        {:error, "SimulationScenarioBinding: scenario must have a name field"}

      not is_map_key(scenario, :total_ticks) and not is_map_key(scenario, "total_ticks") ->
        {:error, "SimulationScenarioBinding: scenario must have a total_ticks field"}

      true ->
        :ok
    end
  end
end
