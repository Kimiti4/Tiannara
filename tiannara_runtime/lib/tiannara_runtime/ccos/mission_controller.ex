defmodule TiannaraRuntime.CCOS.MissionController do
  @moduledoc """
  Phase 18.2 Mission Controller.

  Owns mission lifecycle state. It creates deterministic mission state from
  caller-supplied mission artifacts and replay timestamps.
  """

  alias TiannaraRuntime.CCOS.Artifact

  @valid_statuses [:submitted, :running, :paused, :completed, :failed, :archived, :cancelled]

  @spec create(map(), String.t()) :: {:ok, map()} | {:error, String.t()}
  def create(mission, replay_timestamp) when is_map(mission) and is_binary(replay_timestamp) do
    with {:ok, objective} <- Artifact.require_binary(mission, :objective),
         {:ok, goal_graph} <- Artifact.require_map(mission, :goal_graph),
         {:ok, task_graph} <- Artifact.require_list(mission, :task_graph),
         {:ok, dependencies} <- Artifact.require_list(mission, :dependencies) do
      base = %{
        objective: objective,
        goal_graph: goal_graph,
        task_graph: task_graph,
        dependencies: dependencies,
        source_mission: mission
      }

      mission_id = Artifact.content_id("cckmission", base)

      state = %{
        mission_id: mission_id,
        status: :submitted,
        goal_graph: goal_graph,
        task_graph: task_graph,
        dependencies: dependencies,
        mission_fingerprint: Artifact.fingerprint(base),
        lifecycle: [%{status: :submitted, timestamp: replay_timestamp}],
        source_mission: mission
      }

      {:ok, state}
    end
  end

  def create(_mission, _replay_timestamp),
    do: {:error, "MissionController.create requires a mission map and replay timestamp"}

  @spec transition(map(), atom(), String.t()) :: {:ok, map()} | {:error, String.t()}
  def transition(mission_state, status, replay_timestamp)
      when is_map(mission_state) and status in @valid_statuses and is_binary(replay_timestamp) do
    lifecycle = Map.fetch!(mission_state, :lifecycle)

    {:ok,
     mission_state
     |> Map.put(:status, status)
     |> Map.put(:lifecycle, lifecycle ++ [%{status: status, timestamp: replay_timestamp}])}
  end

  def transition(_mission_state, _status, _replay_timestamp),
    do: {:error, "MissionController.transition received invalid transition input"}
end
