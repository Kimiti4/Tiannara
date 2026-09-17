defmodule TiannaraRuntime.CCOS.ExecutiveKernel do
  @moduledoc """
  Phase 18.2 Constitutional Cognitive Kernel.

  The kernel orchestrates certified subsystems. It does not plan, reason, learn,
  optimize, execute subsystem logic, or create hidden runtime state.
  """

  alias TiannaraRuntime.CCOS.{
    ArchaeologyRecorder,
    Artifact,
    AttentionCoordinator,
    ContextBuilder,
    EvidenceCollector,
    MissionController,
    ReplayCoordinator,
    TaskDispatcher
  }

  @spec initialize(map()) :: {:ok, map()} | {:error, String.t()}
  def initialize(opts) when is_map(opts) do
    with {:ok, certified_subsystems} <- Artifact.require_list(opts, :certified_subsystems),
         {:ok, replay_timestamp} <- Artifact.require_binary(opts, :replay_timestamp) do
      state = %{
        status: :initialized,
        certified_subsystems: certified_subsystems,
        missions: %{},
        replay_timestamp: replay_timestamp,
        evidence_ledger: [],
        replay_roots: [],
        archaeology_ledger: []
      }

      {:ok, Map.put(state, :kernel_id, Artifact.content_id("cckernel", state))}
    end
  end

  def initialize(_opts), do: {:error, "ExecutiveKernel.initialize requires an options map"}

  @spec submit_mission(map(), map(), map()) :: {:ok, map()} | {:error, String.t()}
  def submit_mission(kernel_state, mission, context_inputs)
      when is_map(kernel_state) and is_map(mission) and is_map(context_inputs) do
    with {:ok, replay_timestamp} <- Artifact.require_binary(kernel_state, :replay_timestamp),
         {:ok, mission_state} <- MissionController.create(mission, replay_timestamp),
         {:ok, running_mission} <- MissionController.transition(mission_state, :running, replay_timestamp),
         {:ok, context} <- ContextBuilder.build(running_mission, context_inputs),
         {:ok, attention_state} <- AttentionCoordinator.allocate(running_mission, context),
         {:ok, dispatch_root} <-
           TaskDispatcher.dispatch(attention_state, Map.fetch!(kernel_state, :certified_subsystems)),
         {:ok, mission_evidence} <-
           EvidenceCollector.collect_transition(:mission_running, running_mission, replay_timestamp),
         {:ok, context_evidence} <-
           EvidenceCollector.collect_transition(:context_built, context, replay_timestamp),
         {:ok, attention_evidence} <-
           EvidenceCollector.collect_transition(:attention_allocated, attention_state, replay_timestamp),
         {:ok, dispatch_evidence} <-
           EvidenceCollector.collect_transition(:dispatch_intents_created, dispatch_root, replay_timestamp),
         evidence_chain <- [mission_evidence, context_evidence, attention_evidence, dispatch_evidence],
         {:ok, replay_root} <- ReplayCoordinator.build(evidence_chain),
         {:ok, archaeology} <-
           ArchaeologyRecorder.record(%{
             mission_state: running_mission,
             dispatch_root: dispatch_root,
             evidence_chain: evidence_chain,
             replay_root: replay_root
           }) do
      updated_state =
        kernel_state
        |> put_in([:missions, running_mission.mission_id], running_mission)
        |> Map.update!(:evidence_ledger, &(&1 ++ evidence_chain))
        |> Map.update!(:replay_roots, &(&1 ++ [replay_root]))
        |> Map.update!(:archaeology_ledger, &(&1 ++ [archaeology]))

      {:ok,
       %{
         kernel_state: updated_state,
         mission_state: running_mission,
         context: context,
         attention_state: attention_state,
         dispatch_root: dispatch_root,
         evidence_chain: evidence_chain,
         replay_root: replay_root,
         archaeology: archaeology
       }}
    end
  end

  def submit_mission(_kernel_state, _mission, _context_inputs),
    do: {:error, "ExecutiveKernel.submit_mission requires kernel state, mission, and context inputs"}

  @spec pause(map(), String.t(), String.t()) :: {:ok, map()} | {:error, String.t()}
  def pause(kernel_state, mission_id, replay_timestamp),
    do: transition_mission(kernel_state, mission_id, :paused, replay_timestamp)

  @spec resume(map(), String.t(), String.t()) :: {:ok, map()} | {:error, String.t()}
  def resume(kernel_state, mission_id, replay_timestamp),
    do: transition_mission(kernel_state, mission_id, :running, replay_timestamp)

  @spec cancel(map(), String.t(), String.t()) :: {:ok, map()} | {:error, String.t()}
  def cancel(kernel_state, mission_id, replay_timestamp),
    do: transition_mission(kernel_state, mission_id, :cancelled, replay_timestamp)

  @spec status(map()) :: {:ok, map()} | {:error, String.t()}
  def status(kernel_state) when is_map(kernel_state) do
    {:ok,
     %{
       kernel_id: Map.fetch!(kernel_state, :kernel_id),
       status: Map.fetch!(kernel_state, :status),
       mission_count: map_size(Map.fetch!(kernel_state, :missions)),
       evidence_count: length(Map.fetch!(kernel_state, :evidence_ledger)),
       replay_root_count: length(Map.fetch!(kernel_state, :replay_roots)),
       archaeology_count: length(Map.fetch!(kernel_state, :archaeology_ledger))
     }}
  end

  def status(_kernel_state), do: {:error, "ExecutiveKernel.status requires kernel state"}

  @spec shutdown(map(), String.t()) :: {:ok, map()} | {:error, String.t()}
  def shutdown(kernel_state, replay_timestamp)
      when is_map(kernel_state) and is_binary(replay_timestamp) do
    {:ok, Map.put(kernel_state, :status, :shutdown) |> Map.put(:shutdown_at, replay_timestamp)}
  end

  def shutdown(_kernel_state, _replay_timestamp),
    do: {:error, "ExecutiveKernel.shutdown requires kernel state and replay timestamp"}

  defp transition_mission(kernel_state, mission_id, status, replay_timestamp)
       when is_map(kernel_state) and is_binary(mission_id) and is_binary(replay_timestamp) do
    missions = Map.fetch!(kernel_state, :missions)

    with {:ok, mission_state} <- fetch_mission(missions, mission_id),
         {:ok, transitioned} <- MissionController.transition(mission_state, status, replay_timestamp),
         {:ok, evidence} <- EvidenceCollector.collect_transition(status, transitioned, replay_timestamp) do
      updated_state =
        kernel_state
        |> put_in([:missions, mission_id], transitioned)
        |> Map.update!(:evidence_ledger, &(&1 ++ [evidence]))

      {:ok, updated_state}
    end
  end

  defp transition_mission(_kernel_state, _mission_id, _status, _replay_timestamp),
    do: {:error, "mission transition requires kernel state, mission_id, and replay timestamp"}

  defp fetch_mission(missions, mission_id) do
    case Map.fetch(missions, mission_id) do
      {:ok, mission_state} -> {:ok, mission_state}
      :error -> {:error, "mission #{mission_id} is not present in kernel state"}
    end
  end
end
