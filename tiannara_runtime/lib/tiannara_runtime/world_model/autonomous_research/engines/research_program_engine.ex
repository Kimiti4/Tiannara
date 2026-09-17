defmodule TiannaraRuntime.WorldModel.AutonomousResearch.Engines.ResearchProgramEngine do
  @moduledoc """
  Phase 17.8.9 — Research Program Engine (Main Orchestrator).
  Manages the complete lifecycle of autonomous research programs:
  create, execute pipeline, pause, terminate, and compute replay fingerprints.

  Phase 17.8+ proof discipline:
  - no hardcoded domain defaults,
  - no placeholder status, metric, portfolio, theory, or evidence records,
  - no mock simulation output,
  - no wall-clock values generated inside the engine.

  Callers must supply real, content-addressed artifacts and replay timestamps.
  Missing artifacts fail closed.
  """

  alias TiannaraRuntime.WorldModel.AutonomousResearch.Engines.KnowledgeGapPrioritizer
  alias TiannaraRuntime.WorldModel.AutonomousResearch.Engines.ExperimentScheduler
  alias TiannaraRuntime.WorldModel.AutonomousResearch.Engines.TheoryUpdater
  alias TiannaraRuntime.WorldModel.AutonomousResearch.Engines.ResearchArchaeology
  alias TiannaraRuntime.WorldModel.AutonomousResearch.Engines.ResearchMathVerification
  alias TiannaraRuntime.WorldModel.AutonomousResearch.ResearchProgram

  def create_program(_objective, _knowledge_gaps, opts \\ [])

  def create_program(_objective, _knowledge_gaps, opts) when is_list(opts) do
    ResearchProgram.new(opts)
  end

  def execute_pipeline(program) when is_map(program) do
    with {:ok, priority_records} <- required_list(program, :priority_records),
         {:ok, scoring_config} <- required_struct(program, :scoring_config),
         {:ok, epoch_id} <- required_binary(program, :epoch_id),
         {:ok, experiments} <- required_list(program, :experiments),
         {:ok, portfolio} <- required_struct(program, :portfolio),
         {:ok, budget} <- required_struct(program, :budget),
         {:ok, schedule_config} <- required_struct(program, :schedule_config),
         {:ok, evidence} <- required_list(program, :evidence_ledger),
         {:ok, theory_updates} <- required_list(program, :theory_update_inputs),
         {:ok, replay_timestamp} <- required_binary(program, :replay_timestamp),
         {:ok, prioritized_gaps} <-
           KnowledgeGapPrioritizer.prioritize(priority_records, scoring_config, epoch_id),
         {:ok, verified_experiments} <- verify_experiments(experiments),
         {:ok, schedule} <- ExperimentScheduler.schedule(portfolio, budget, schedule_config),
         {:ok, updated_theories} <- apply_theory_updates(theory_updates, replay_timestamp),
         {:ok, archaeology_entries} <- record_archaeology(evidence ++ verified_experiments),
         fingerprint <- compute_fingerprint(program) do
      program
      |> Map.put(:priority_records, prioritized_gaps)
      |> Map.put(:experiments, verified_experiments)
      |> Map.put(:schedule, schedule)
      |> Map.put(:theories, updated_theories)
      |> Map.put(:archaeology_entries, archaeology_entries)
      |> Map.put(:replay_fingerprint, fingerprint)
      |> Map.put(:pipeline_executed_at, replay_timestamp)
      |> then(fn p -> {:ok, p} end)
    end
  end

  def get_program_status(program) when is_map(program) do
    with {:ok, program_id} <- required_binary(program, :program_id),
         {:ok, status} <- required_atom(program, :status),
         {:ok, metrics} <- required_map(program, :metrics) do
      {:ok, %{program_id: program_id, status: status, metrics: metrics}}
    end
  end

  def pause_program(program, replay_timestamp) when is_map(program) and is_binary(replay_timestamp) do
    {:ok,
     program
     |> Map.put(:status, :paused)
     |> Map.put(:paused_at, replay_timestamp)}
  end

  def terminate_program(program, replay_timestamp, reason)
      when is_map(program) and is_binary(replay_timestamp) and is_atom(reason) do
    termination_record = %{
      terminated_at: replay_timestamp,
      experiments_completed: length(Map.get(program, :evidence_ledger) || []),
      reason: reason
    }

    {:ok,
     program
     |> Map.put(:status, :terminated)
     |> Map.put(:termination_record, termination_record)}
  end

  def get_portfolio(program) when is_map(program) do
    required_map(program, :portfolio)
  end

  def get_metrics(program) when is_map(program) do
    required_map(program, :metrics)
  end

  def compute_fingerprint(program) when is_map(program) do
    canonical =
      program
      |> Map.drop([:replay_fingerprint, :archaeology_root, :created_at, :timestamp, :evidence_ledger])
      |> deep_struct_to_map()
      |> Enum.sort_by(fn {k, _} -> to_string(k) end)
      |> Enum.map(fn {k, v} -> "#{k}:#{Jason.encode!(v)}" end)
      |> Enum.join("|")

    "rf_" <> (:crypto.hash(:sha256, canonical) |> Base.encode16(case: :lower))
  end

  def deep_struct_to_map(value) do
    case value do
      %{__struct__: _} ->
        value
        |> Map.from_struct()
        |> Enum.map(fn {k, v} -> {k, deep_struct_to_map(v)} end)
        |> Map.new()
      map when is_map(map) ->
        Enum.map(map, fn {k, v} -> {k, deep_struct_to_map(v)} end) |> Map.new()
      list when is_list(list) ->
        Enum.map(list, &deep_struct_to_map/1)
      other ->
        other
    end
  end

  defp verify_experiments(experiments) do
    Enum.reduce_while(experiments, {:ok, []}, fn experiment, {:ok, acc} ->
      case ResearchMathVerification.verify_experiment(experiment) do
        {:ok, proof_hash, details} ->
          verified =
            experiment
            |> Map.put(:proof_hash, proof_hash)
            |> Map.put(:verification_details, details)

          {:cont, {:ok, [verified | acc]}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, verified} -> {:ok, Enum.reverse(verified)}
      error -> error
    end
  end

  defp apply_theory_updates(update_inputs, replay_timestamp) do
    Enum.reduce_while(update_inputs, {:ok, []}, fn input, {:ok, acc} ->
      with {:ok, theory} <- required_map(input, :theory),
           {:ok, evidence} <- required_map(input, :evidence),
           {:ok, config} <- required_struct(input, :config) do
        case TheoryUpdater.update(theory, evidence, config, replay_timestamp) do
          {:ok, updated, record} -> {:cont, {:ok, [%{theory: updated, record: record} | acc]}}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      else
        error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, updates} -> {:ok, Enum.reverse(updates)}
      error -> error
    end
  end

  defp record_archaeology(artifacts) do
    Enum.reduce_while(artifacts, {:ok, []}, fn artifact, {:ok, acc} ->
      case ResearchArchaeology.record(artifact) do
        {:ok, entry} -> {:cont, {:ok, [entry | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, entries} -> {:ok, Enum.reverse(entries)}
      error -> error
    end
  end

  defp required_list(map, field) do
    case get_field(map, field) do
      value when is_list(value) -> {:ok, value}
      nil -> {:error, "ResearchProgramEngine: #{field} is required"}
      _ -> {:error, "ResearchProgramEngine: #{field} must be a list"}
    end
  end

  defp required_map(map, field) do
    case get_field(map, field) do
      value when is_map(value) -> {:ok, value}
      nil -> {:error, "ResearchProgramEngine: #{field} is required"}
      _ -> {:error, "ResearchProgramEngine: #{field} must be a map"}
    end
  end

  defp required_struct(map, field) do
    case get_field(map, field) do
      %{__struct__: _} = value -> {:ok, value}
      nil -> {:error, "ResearchProgramEngine: #{field} is required"}
      _ -> {:error, "ResearchProgramEngine: #{field} must be a struct"}
    end
  end

  defp required_binary(map, field) do
    case get_field(map, field) do
      value when is_binary(value) and value != "" -> {:ok, value}
      nil -> {:error, "ResearchProgramEngine: #{field} is required"}
      _ -> {:error, "ResearchProgramEngine: #{field} must be a non-empty string"}
    end
  end

  defp required_atom(map, field) do
    case get_field(map, field) do
      value when is_atom(value) -> {:ok, value}
      nil -> {:error, "ResearchProgramEngine: #{field} is required"}
      _ -> {:error, "ResearchProgramEngine: #{field} must be an atom"}
    end
  end

  defp get_field(map, field), do: Map.get(map, field) || Map.get(map, to_string(field))
end
