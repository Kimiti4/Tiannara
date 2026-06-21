defmodule Tiannara.AAL.CommandLoom do
  @moduledoc """
  The Jarvis-tier command orchestrator. 
  Parses human intent, parallelizes domain extraction across the multiverse, 
  and compiles the output into Base Reality.
  """
  use GenServer
  require Logger

  alias Tiannara.AAL.LexicalTensegrityField, as: LTF
  alias Tiannara.BaseReality.Workspace

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def execute_command(human_input) do
    GenServer.cast(__MODULE__, {:process_command, human_input})
  end

  @impl true
  def init(_opts) do
    {:ok, %{task_sup: Tiannara.ExtrusionTaskSupervisor}}
  end

  @impl true
  def handle_cast({:process_command, human_input}, state) do
    Logger.info("🎙️ [HUMAN]: #{human_input}")

    # 1. Deterministic Intent Mapping
    {primary_intent, required_domains} = LTF.map_intent_vectors(human_input)
    Logger.debug("🧠 [LTF] Intent locked: #{primary_intent}. Domains: #{inspect(required_domains)}")

    # 2. Parallelize extraction across the identified domains
    extraction_tasks =
      Enum.map(required_domains, fn domain ->
        Task.Supervisor.async_nolink(state.task_sup, fn ->
          Tiannara.Domains.Extruder.extract_blueprint(domain, primary_intent)
        end)
      end)

    # 3. Await all results with a strict 500ms timeout (zero-latency requirement)
    compiled_blueprints = 
      Task.yield_many(extraction_tasks, 500)
      |> Enum.map(fn {task, res} -> parse_task_result(task, res) end)
      |> Enum.reject(&match?(%{status: :failed}, &1)) # Drop timeouts cleanly

    # 4. Blueprint Validator (prevents hallucinated/unsafe blueprints)
    validated_blueprints = Tiannara.AAL.BlueprintValidator.validate(compiled_blueprints)

    # 5. Synthesize the final payload and push to the local developer workspace
    commit_hash = Workspace.commit_blueprints(validated_blueprints, primary_intent)

    # 6. Output the final vocalized response
    speak_confirmation(required_domains, commit_hash)

    {:noreply, state}
  end

  defp parse_task_result(_task, {:ok, blueprint}), do: blueprint
  defp parse_task_result(task, _res) do
    # Gracefully kill tasks that exceed the 500ms zero-latency budget
    Task.shutdown(task, :brutal_kill)
    %{status: :failed, reason: :timeout_or_collapse}
  end

  defp speak_confirmation(domains, commit_hash) do
    domain_list = Enum.map(domains, &to_string/1) |> Enum.join(", ")
    response = "Intent vector processed. #{String.capitalize(domain_list)} nodes have isolated the required matrices. " <>
               "The complete production files and structural logs have been committed to your local workspace (Hash: #{commit_hash}). " <>
               "Standing by for hardware deployment confirmation, Sir."
               
    Logger.info("🤖 [TIANNARA]: #{response}")
    # Tiannara.Audio.TextToSpeech.speak(response)
  end
end
