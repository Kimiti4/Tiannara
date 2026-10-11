defmodule Tiannara.AAL.CommandLoom do
  @moduledoc """
  The Jarvis-tier command orchestrator.

  Extraction failures and invalid blueprints remain visible to the caller.
  Workspace artifacts are written only when every requested domain returns a
  structurally valid blueprint. A successful write is not reported as a Git
  commit or as hardware deployment.
  """

  use GenServer
  require Logger

  alias Tiannara.AAL.LexicalTensegrityField, as: LTF
  alias Tiannara.BaseReality.Workspace

  @task_timeout_ms 500
  @call_timeout_ms 30_000

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @doc "Process a command and return its observed outcome to the caller."
  def execute_command(human_input) do
    GenServer.call(__MODULE__, {:process_command, human_input}, @call_timeout_ms)
  end

  @impl true
  def init(_opts) do
    {:ok, %{task_sup: Tiannara.ExtrusionTaskSupervisor}}
  end

  @impl true
  def handle_call({:process_command, human_input}, _from, state)
      when is_binary(human_input) do
    if String.trim(human_input) == "" do
      {:reply, {:error, :empty_command}, state}
    else
      process_command(human_input, state)
    end
  end

  def handle_call({:process_command, _human_input}, _from, state) do
    {:reply, {:error, :invalid_command}, state}
  end

  defp process_command(human_input, state) do
    Logger.info("[HUMAN COMMAND] #{human_input}")

    {primary_intent, required_domains} = LTF.map_intent_vectors(human_input)

    cond do
      primary_intent in [:unknown, :ambiguous] ->
        failure = %{
          status: :unroutable,
          intent: primary_intent,
          reason: if(primary_intent == :ambiguous, do: :ambiguous_intent, else: :unknown_intent),
          artifacts_written: false
        }

        Logger.warning("Command intent is #{primary_intent}; no workspace artifacts written.")
        {:reply, {:error, failure}, state}

      required_domains == [] ->
        failure = %{
          status: :unroutable,
          intent: primary_intent,
          reason: :no_supported_domain_match,
          artifacts_written: false
        }

        Logger.warning("Command has no supported domain match; no workspace artifacts written.")
        {:reply, {:error, failure}, state}

      true ->
        process_supported_domains(human_input, primary_intent, required_domains, state)
    end
  end

  defp process_supported_domains(_human_input, primary_intent, required_domains, state) do
    extraction_tasks =
      Enum.map(required_domains, fn domain ->
        task =
          Task.Supervisor.async_nolink(state.task_sup, fn ->
            Tiannara.Domains.Extruder.extract_blueprint(domain, primary_intent)
          end)

        {domain, task}
      end)

    task_results =
      extraction_tasks
      |> Enum.map(fn {domain, task} ->
        result = Task.yield(task, @task_timeout_ms)
        {domain, parse_task_result(task, result)}
      end)

    extraction_failures =
      Enum.flat_map(task_results, fn
        {domain, {:error, reason}} -> [%{domain: domain, reason: reason}]
        _ -> []
      end)

    extracted_blueprints =
      Enum.flat_map(task_results, fn
        {_domain, {:ok, blueprint}} -> [blueprint]
        _ -> []
      end)

    validated_blueprints = Tiannara.AAL.BlueprintValidator.validate(extracted_blueprints)

    cond do
      extraction_failures != [] ->
        failure = %{
          status: :incomplete,
          intent: primary_intent,
          required_domains: required_domains,
          failed_domains: extraction_failures,
          validated_blueprints: length(validated_blueprints)
        }

        Logger.warning("Command incomplete; no workspace artifacts written: #{inspect(failure)}")
        {:reply, {:error, failure}, state}

      length(validated_blueprints) != length(required_domains) ->
        failure = %{
          status: :validation_failed,
          intent: primary_intent,
          required_domains: required_domains,
          extracted_blueprints: length(extracted_blueprints),
          validated_blueprints: length(validated_blueprints)
        }

        Logger.warning("Blueprint validation incomplete; no workspace artifacts written: #{inspect(failure)}")
        {:reply, {:error, failure}, state}

      true ->
        case Workspace.write_blueprints(validated_blueprints, primary_intent) do
          {:ok, workspace_result} ->
            result = %{
              status: :artifacts_written,
              intent: primary_intent,
              domains: required_domains,
              workspace: workspace_result
            }

            speak_confirmation(result)
            {:reply, {:ok, result}, state}

          {:error, reason} ->
            Logger.error("Workspace write failed: #{inspect(reason)}")
            {:reply, {:error, %{status: :workspace_failed, reason: reason}}, state}
        end
    end
  end

  defp parse_task_result(_task, {:ok, %{status: :failed, reason: reason}}),
    do: {:error, reason}

  defp parse_task_result(_task, {:ok, blueprint}) when is_map(blueprint),
    do: {:ok, blueprint}

  defp parse_task_result(task, nil) do
    Task.shutdown(task, :brutal_kill)
    {:error, :timeout}
  end

  defp parse_task_result(_task, {:exit, reason}), do: {:error, {:task_exit, reason}}
  defp parse_task_result(_task, _result), do: {:error, :invalid_extraction_result}

  defp speak_confirmation(%{domains: domains, workspace: workspace}) do
    domain_list = Enum.map(domains, &to_string/1) |> Enum.join(", ")

    response =
      "Validated artifacts for #{domain_list} were written to #{workspace.directory}. " <>
        "Manifest SHA-256: #{workspace.manifest_sha256}. " <>
        "No Git commit or hardware deployment was performed."

    Logger.info("[TIANNARA RESULT] #{response}")
  end
end
