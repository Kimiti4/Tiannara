defmodule TiannaraRuntime.OS.Persistence.ExperimentJournal do
  @moduledoc """
  Experiment Journal

  Every experiment maintains its own journal tracking:
  - Current stage
  - Inputs
  - Intermediate results
  - Output
  - Hash
  - Checkpoint

  If shutdown occurs during stage N of M, the runtime resumes from stage N
  instead of repeating stages 1 through N-1.
  """

  require Logger

  @type journal_entry :: %{
    stage: integer(),
    action: String.t(),
    inputs: map(),
    results: map(),
    hash: String.t(),
    timestamp: integer()
  }

  @type experiment_journal :: %{
    experiment_id: String.t(),
    hypothesis_id: String.t(),
    total_stages: integer(),
    current_stage: integer(),
    status: :running | :paused | :completed | :failed,
    entries: [journal_entry()],
    created_at: integer(),
    checkpoint_stage: integer() | nil
  }

  @doc """
  Creates a new experiment journal.
  """
  @spec create_journal(String.t(), String.t(), integer()) :: {:ok, experiment_journal()}
  def create_journal(experiment_id, hypothesis_id, total_stages) do
    journal = %{
      experiment_id: experiment_id,
      hypothesis_id: hypothesis_id,
      total_stages: total_stages,
      current_stage: 0,
      status: :running,
      entries: [],
      created_at: System.system_time(:millisecond),
      checkpoint_stage: nil
    }

    persist_journal(journal)
    {:ok, journal}
  end

  @doc """
  Records a stage completion in the experiment journal.
  """
  @spec record_stage(String.t(), integer(), String.t(), map(), map()) :: {:ok, journal_entry()}
  def record_stage(experiment_id, stage, action, inputs, results) do
    entry = %{
      stage: stage,
      action: action,
      inputs: inputs,
      results: results,
      hash: compute_entry_hash(stage, action, inputs, results),
      timestamp: System.system_time(:millisecond)
    }

    journal = load_journal(experiment_id)

    updated_journal = %{
      journal |
      current_stage: stage,
      entries: [entry | journal.entries]
    }

    persist_journal(updated_journal)
    {:ok, entry}
  end

  @doc """
  Sets a checkpoint at the current stage, allowing resume from here.
  """
  @spec set_checkpoint(String.t()) :: {:ok, experiment_journal()}
  def set_checkpoint(experiment_id) do
    journal = load_journal(experiment_id)
    updated_journal = %{journal | checkpoint_stage: journal.current_stage}
    persist_journal(updated_journal)
    {:ok, updated_journal}
  end

  @doc """
  Marks the experiment as completed.
  """
  @spec complete(String.t(), map()) :: {:ok, experiment_journal()}
  def complete(experiment_id, _final_output) do
    journal = load_journal(experiment_id)
    updated_journal = %{journal | status: :completed, current_stage: journal.total_stages}
    persist_journal(updated_journal)
    {:ok, updated_journal}
  end

  @doc """
  Marks the experiment as failed.
  """
  @spec fail(String.t(), String.t()) :: {:ok, experiment_journal()}
  def fail(experiment_id, reason) do
    journal = load_journal(experiment_id)
    updated_journal = %{journal | status: :failed}
    persist_journal(updated_journal)
    Logger.warning("Experiment #{experiment_id} failed at stage #{journal.current_stage}: #{reason}")
    {:ok, updated_journal}
  end

  @doc """
  Gets the resume point for an experiment.
  Returns the stage to resume from (0 if no checkpoint).
  """
  @spec get_resume_stage(String.t()) :: {:ok, integer()}
  def get_resume_stage(experiment_id) do
    journal = load_journal(experiment_id)
    resume_stage = if journal.checkpoint_stage, do: journal.checkpoint_stage, else: 0
    {:ok, resume_stage}
  end

  @doc """
  Loads an experiment journal from storage, creating a fresh one if missing.
  """
  @spec load_journal(String.t()) :: experiment_journal()
  def load_journal(experiment_id) do
    file_path = journal_file_path(experiment_id)

    if File.exists?(file_path) do
      case File.read(file_path) do
        {:ok, content} ->
          Jason.decode!(content, keys: :atoms)

        {:error, _} ->
          %{experiment_id: experiment_id, status: :unknown, entries: [], current_stage: 0, total_stages: 0}
      end
    else
      %{experiment_id: experiment_id, status: :unknown, entries: [], current_stage: 0, total_stages: 0}
    end
  rescue
    _ -> %{experiment_id: experiment_id, status: :unknown, entries: [], current_stage: 0, total_stages: 0}
  end

  defp compute_entry_hash(stage, action, inputs, results) do
    content = %{stage: stage, action: action, inputs: inputs, results: results}
    :crypto.hash(:sha256, :erlang.term_to_binary(content)) |> Base.encode16(case: :lower)
  end

  defp journal_file_path(experiment_id) do
    storage_path = Application.get_env(:tiannara_runtime, :cpl_storage_path, "data/cpl")
    Path.join([storage_path, "experiments", "#{experiment_id}.journal.json"])
  end

  defp persist_journal(journal) do
    file_path = journal_file_path(journal.experiment_id)
    File.mkdir_p!(Path.dirname(file_path))
    File.write!(file_path, Jason.encode!(journal))
  rescue
    e -> Logger.warning("Failed to persist journal for #{journal.experiment_id}: #{inspect(e)}")
  end
end
