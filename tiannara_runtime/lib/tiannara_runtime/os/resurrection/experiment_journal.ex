defmodule TiannaraRuntime.OS.Resurrection.ExperimentJournal do
  @moduledoc """
  Experiment Journaling System

  Every experiment maintains its own journal.

  Structure:
  - Experiment ID
  - Current Stage
  - Inputs
  - Intermediate Results
  - Output
  - Hash
  - Checkpoint

  If shutdown occurs during stage 7 of 12,
  the runtime resumes from stage 7 instead of repeating stages 1-6.
  """

  @type experiment_stage :: %{
    stage_number: integer(),
    stage_name: String.t(),
    status: :pending | :running | :completed | :failed,
    started_at: integer() | nil,
    completed_at: integer() | nil,
    inputs: map(),
    outputs: map() | nil,
    hash: String.t() | nil
  }

  @type experiment_journal :: %{
    experiment_id: String.t(),
    experiment_name: String.t(),
    total_stages: integer(),
    current_stage: integer(),
    stages: [experiment_stage()],
    inputs: map(),
    output: map() | nil,
    status: :pending | :running | :completed | :failed | :interrupted,
    created_at: integer(),
    last_checkpoint_at: integer() | nil,
    hash: String.t()
  }

  @doc """
  Creates a new experiment journal with the specified stages.
  """
  @spec create_journal(String.t(), String.t(), integer(), map()) :: experiment_journal()
  def create_journal(experiment_id, experiment_name, total_stages, inputs) do
    stages = Enum.map(1..total_stages, fn n ->
      %{
        stage_number: n,
        stage_name: "stage_#{n}",
        status: :pending,
        started_at: nil,
        completed_at: nil,
        inputs: %{},
        outputs: nil,
        hash: nil
      }
    end)

    journal = %{
      experiment_id: experiment_id,
      experiment_name: experiment_name,
      total_stages: total_stages,
      current_stage: 1,
      stages: stages,
      inputs: inputs,
      output: nil,
      status: :pending,
      created_at: System.system_time(:millisecond),
      last_checkpoint_at: nil,
      hash: ""
    }

    %{journal | hash: compute_journal_hash(journal)}
  end

  @doc """
  Starts a specific stage in the experiment.
  """
  @spec start_stage(experiment_journal(), integer()) :: experiment_journal()
  def start_stage(journal, stage_number) when stage_number >= 1 and stage_number <= journal.total_stages do
    stages = Enum.map(journal.stages, fn stage ->
      if stage.stage_number == stage_number do
        %{stage | status: :running, started_at: System.system_time(:millisecond)}
      else
        stage
      end
    end)

    journal = %{journal | stages: stages, current_stage: stage_number, status: :running}
    %{journal | hash: compute_journal_hash(journal)}
  end

  @doc """
  Completes a stage with outputs.
  """
  @spec complete_stage(experiment_journal(), integer(), map()) :: experiment_journal()
  def complete_stage(journal, stage_number, outputs) do
    stages = Enum.map(journal.stages, fn stage ->
      if stage.stage_number == stage_number do
        hash = :crypto.hash(:sha256, :erlang.term_to_binary(outputs)) |> Base.encode16(case: :lower)
        %{stage | status: :completed, completed_at: System.system_time(:millisecond), outputs: outputs, hash: hash}
      else
        stage
      end
    end)

    next_stage = min(stage_number + 1, journal.total_stages)
    journal = %{journal | stages: stages, current_stage: next_stage, last_checkpoint_at: System.system_time(:millisecond)}
    %{journal | hash: compute_journal_hash(journal)}
  end

  @doc """
  Marks a stage as failed.
  """
  @spec fail_stage(experiment_journal(), integer(), String.t()) :: experiment_journal()
  def fail_stage(journal, stage_number, reason) do
    stages = Enum.map(journal.stages, fn stage ->
      if stage.stage_number == stage_number do
        %{stage | status: :failed, completed_at: System.system_time(:millisecond), outputs: %{error: reason}}
      else
        stage
      end
    end)

    journal = %{journal | stages: stages, status: :failed}
    %{journal | hash: compute_journal_hash(journal)}
  end

  @doc """
  Completes the entire experiment with final output.
  """
  @spec complete_experiment(experiment_journal(), map()) :: experiment_journal()
  def complete_experiment(journal, output) do
    hash = :crypto.hash(:sha256, :erlang.term_to_binary(output)) |> Base.encode16(case: :lower)
    journal = %{journal | output: output, status: :completed, last_checkpoint_at: System.system_time(:millisecond)}
    %{journal | hash: compute_journal_hash(journal)}
  end

  @doc """
  Returns the stage to resume from after an interruption.
  """
  @spec get_resume_stage(experiment_journal()) :: integer() | nil
  def get_resume_stage(journal) do
    # Find the first non-completed stage
    Enum.find_value(journal.stages, nil, fn stage ->
      if stage.status in [:pending, :running], do: stage.stage_number
    end)
  end

  @doc """
  Returns the completed stages that can be skipped on resume.
  """
  @spec get_completed_stages(experiment_journal()) :: [experiment_stage()]
  def get_completed_stages(journal) do
    Enum.filter(journal.stages, fn stage -> stage.status == :completed end)
  end

  @doc """
  Checks if the journal can be resumed.
  """
  @spec can_resume?(experiment_journal()) :: boolean()
  def can_resume?(journal) do
    journal.status in [:running, :interrupted] and get_resume_stage(journal) != nil
  end

  @doc """
  Marks the journal as interrupted (e.g., due to shutdown).
  """
  @spec mark_interrupted(experiment_journal()) :: experiment_journal()
  def mark_interrupted(journal) do
    # Mark current running stage as interrupted
    stages = Enum.map(journal.stages, fn stage ->
      if stage.status == :running do
        %{stage | status: :pending} # Reset to pending for resume
      else
        stage
      end
    end)

    journal = %{journal | stages: stages, status: :interrupted}
    %{journal | hash: compute_journal_hash(journal)}
  end

  defp compute_journal_hash(journal) do
    :crypto.hash(:sha256, :erlang.term_to_binary(Map.delete(journal, :hash))) |> Base.encode16(case: :lower)
  end
end
