defmodule TiannaraRuntime.WorldModel.AutonomousResearch.ResearchProgram do
  @moduledoc """
  Phase 17.8.1 — ResearchProgram: root entity representing an autonomous research program.

  Uses Phase 16.1 ResearchProgram schema extended with Phase 17.8 fields
  (simulation_scenario_template, pre-computed statistical power).

  Constitutional rules:
  - All field values come from the caller — no hardcoded defaults for domain values.
  - content-addressed ID computed via TiannaraRuntime.Shared.Canonical.
  - Immutable after creation; revisions produce new structs with new IDs.
  - Status and priority are owned exclusively by this module's creation contract;
    they must never be inferred or defaulted.
  """

  alias TiannaraRuntime.Shared.Canonical

  @id_prefix "rp"
  @id_field :program_id

  @valid_statuses [
    :active,
    :paused,
    :completed,
    :terminated,
    :provisional_archive,
    :constitutionally_archived
  ]

  defstruct [
    # Phase 16.1 fields
    :program_id,
    :schema_version,
    :primary_question_id,
    :portfolio_rank_hint,
    :objectives,
    :milestones,
    :experiments,
    :evidence_requirements,
    :statistical_requirements,
    :stopping_criteria,
    :resource_constraints,
    # Phase 17.8 extension fields
    :simulation_scenario_template,
    :statistical_power_precomputed,
    :status,
    :replay_fingerprint,
    :archaeology_root,
    :config_hash
  ]

  @type t :: %__MODULE__{
          program_id: String.t() | nil,
          schema_version: String.t() | nil,
          primary_question_id: String.t() | nil,
          portfolio_rank_hint: non_neg_integer() | nil,
          objectives: [map()] | nil,
          milestones: [map()] | nil,
          experiments: [String.t()] | nil,
          evidence_requirements: [map()] | nil,
          statistical_requirements: map() | nil,
          stopping_criteria: [map()] | nil,
          resource_constraints: map() | nil,
          simulation_scenario_template: map() | nil,
          statistical_power_precomputed: map() | nil,
          status: atom() | nil,
          replay_fingerprint: String.t() | nil,
          archaeology_root: String.t() | nil,
          config_hash: String.t() | nil
        }

  @doc """
  Constructs and validates a ResearchProgram. All domain values must be
  supplied by the caller.

  Required keys:
  - :schema_version (String.t)
  - :primary_question_id (String.t)
  - :portfolio_rank_hint (non_neg_integer)
  - :objectives ([map()])
  - :milestones ([map()])
  - :experiments ([String.t()] — list of experiment IDs)
  - :evidence_requirements ([map()])
  - :statistical_requirements (map — must include alpha, target_power, confidence_interval_target keys)
  - :stopping_criteria ([map()])
  - :resource_constraints (map — must include max_compute_units and max_experiments keys)
  - :status (atom — one of #{inspect(@valid_statuses)})
  - :config_hash (String.t)

  Optional:
  - :simulation_scenario_template (map | nil)
  - :statistical_power_precomputed (map | nil)
  - :replay_fingerprint (String.t | nil)
  - :archaeology_root (String.t | nil)

  The :program_id is computed from the other fields; do not supply it.
  """
  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts) when is_list(opts) do
    program = %__MODULE__{
      schema_version: Keyword.get(opts, :schema_version),
      primary_question_id: Keyword.get(opts, :primary_question_id),
      portfolio_rank_hint: Keyword.get(opts, :portfolio_rank_hint),
      objectives: Keyword.get(opts, :objectives),
      milestones: Keyword.get(opts, :milestones),
      experiments: Keyword.get(opts, :experiments),
      evidence_requirements: Keyword.get(opts, :evidence_requirements),
      statistical_requirements: Keyword.get(opts, :statistical_requirements),
      stopping_criteria: Keyword.get(opts, :stopping_criteria),
      resource_constraints: Keyword.get(opts, :resource_constraints),
      simulation_scenario_template: Keyword.get(opts, :simulation_scenario_template),
      statistical_power_precomputed: Keyword.get(opts, :statistical_power_precomputed),
      status: Keyword.get(opts, :status),
      replay_fingerprint: Keyword.get(opts, :replay_fingerprint),
      archaeology_root: Keyword.get(opts, :archaeology_root),
      config_hash: Keyword.get(opts, :config_hash)
    }

    with :ok <- validate(program) do
      id = Canonical.generate_id(program, @id_field, @id_prefix)
      {:ok, %{program | program_id: id}}
    end
  end

  @spec verify_id(t()) :: :ok | {:error, String.t()}
  def verify_id(%__MODULE__{} = program) do
    Canonical.verify_id(program, @id_field, @id_prefix)
  end

  @spec validate(t()) :: :ok | {:error, String.t()}
  defp validate(%__MODULE__{schema_version: nil}),
    do: {:error, "ResearchProgram: schema_version is required"}

  defp validate(%__MODULE__{schema_version: v}) when not is_binary(v) or v == "",
    do: {:error, "ResearchProgram: schema_version must be a non-empty string"}

  defp validate(%__MODULE__{primary_question_id: nil}),
    do: {:error, "ResearchProgram: primary_question_id is required"}

  defp validate(%__MODULE__{primary_question_id: v}) when not is_binary(v) or v == "",
    do: {:error, "ResearchProgram: primary_question_id must be a non-empty string"}

  defp validate(%__MODULE__{portfolio_rank_hint: nil}),
    do: {:error, "ResearchProgram: portfolio_rank_hint is required"}

  defp validate(%__MODULE__{portfolio_rank_hint: v}) when not is_integer(v) or v < 0,
    do: {:error, "ResearchProgram: portfolio_rank_hint must be a non-negative integer"}

  defp validate(%__MODULE__{objectives: nil}),
    do: {:error, "ResearchProgram: objectives is required"}

  defp validate(%__MODULE__{objectives: v}) when not is_list(v),
    do: {:error, "ResearchProgram: objectives must be a list"}

  defp validate(%__MODULE__{milestones: nil}),
    do: {:error, "ResearchProgram: milestones is required"}

  defp validate(%__MODULE__{milestones: v}) when not is_list(v),
    do: {:error, "ResearchProgram: milestones must be a list"}

  defp validate(%__MODULE__{experiments: nil}),
    do: {:error, "ResearchProgram: experiments is required"}

  defp validate(%__MODULE__{experiments: v}) when not is_list(v),
    do: {:error, "ResearchProgram: experiments must be a list"}

  defp validate(%__MODULE__{evidence_requirements: nil}),
    do: {:error, "ResearchProgram: evidence_requirements is required"}

  defp validate(%__MODULE__{evidence_requirements: v}) when not is_list(v),
    do: {:error, "ResearchProgram: evidence_requirements must be a list"}

  defp validate(%__MODULE__{statistical_requirements: nil}),
    do: {:error, "ResearchProgram: statistical_requirements is required"}

  defp validate(%__MODULE__{statistical_requirements: v}) when not is_map(v),
    do: {:error, "ResearchProgram: statistical_requirements must be a map"}

  defp validate(%__MODULE__{stopping_criteria: nil}),
    do: {:error, "ResearchProgram: stopping_criteria is required"}

  defp validate(%__MODULE__{stopping_criteria: v}) when not is_list(v),
    do: {:error, "ResearchProgram: stopping_criteria must be a list"}

  defp validate(%__MODULE__{resource_constraints: nil}),
    do: {:error, "ResearchProgram: resource_constraints is required"}

  defp validate(%__MODULE__{resource_constraints: v}) when not is_map(v),
    do: {:error, "ResearchProgram: resource_constraints must be a map"}

  defp validate(%__MODULE__{status: nil}),
    do: {:error, "ResearchProgram: status is required"}

  defp validate(%__MODULE__{status: v}) when v not in @valid_statuses,
    do: {:error,
         "ResearchProgram: status must be one of #{inspect(@valid_statuses)}"}

  defp validate(%__MODULE__{config_hash: nil}),
    do: {:error, "ResearchProgram: config_hash is required"}

  defp validate(%__MODULE__{config_hash: v}) when not is_binary(v) or v == "",
    do: {:error, "ResearchProgram: config_hash must be a non-empty string"}

  defp validate(%__MODULE__{}), do: :ok
end
