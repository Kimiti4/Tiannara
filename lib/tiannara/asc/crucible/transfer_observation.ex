defmodule Tiannara.ASC.Crucible.TransferObservation do
  @moduledoc """
  Transfer Observation — first-class scientific record of a transfer attempt.

  Every transfer becomes an observation that can be studied, measured, and used
  to generate engineering laws.
  """

  defstruct [
    :id,
    :source_pattern_id,
    :target_failure_id,
    :source_project,
    :target_project,
    :source_classification,
    :target_classification,
    :semantic_distance,
    :adaptation_strategy,
    :success,
    :fitness_before,
    :fitness_after,
    :generation,
    :target_constraints, # Phase 5E
    :number_of_steps,    # Phase 5E
    :reuse_count,        # Phase 5E
    :created_at
  ]

  @typedoc "Transfer observation record"
  @type t :: %__MODULE__{
          id: String.t(),
          source_pattern_id: String.t(),
          target_failure_id: String.t(),
          source_project: String.t(),
          target_project: String.t(),
          source_classification: map(),
          target_classification: map(),
          semantic_distance: float(),
          adaptation_strategy: atom(),
          success: boolean(),
          fitness_before: float(),
          fitness_after: float(),
          generation: non_neg_integer(),
          target_constraints: [atom()],
          number_of_steps: non_neg_integer(),
          reuse_count: non_neg_integer(),
          created_at: DateTime.t()
        }

  @doc """
  Create a transfer observation from a transfer adaptation record.
  """
  def from_adaptation_record(adaptation_record, source_project, target_project, generation) do
    %__MODULE__{
      id: "transfer_obs_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
      source_pattern_id: adaptation_record.source_pattern_id,
      target_failure_id: adaptation_record.target_failure_id,
      source_project: source_project,
      target_project: target_project,
      source_classification: adaptation_record.source_classification,
      target_classification: adaptation_record.target_classification,
      semantic_distance: adaptation_record.transfer_distance,
      adaptation_strategy: adaptation_record.adaptation_strategy,
      success: adaptation_record.success,
      fitness_before: adaptation_record.fitness_before,
      fitness_after: adaptation_record.fitness_after,
      generation: generation,
      target_constraints: adaptation_record.target_constraints || [],
      number_of_steps: adaptation_record.number_of_steps || 0,
      reuse_count: adaptation_record.reuse_count || 0,
      created_at: DateTime.utc_now()
    }
  end
end
