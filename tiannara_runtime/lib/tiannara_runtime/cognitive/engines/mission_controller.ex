defmodule TiannaraRuntime.Cognitive.Engines.MissionController do
  @moduledoc "Phase 18.2 — Mission lifecycle controller"

  alias TiannaraRuntime.Cognitive.Mission

  @valid_transitions %{
    submitted: [:running],
    running: [:paused, :completed, :failed],
    paused: [:running],
    completed: [:archived],
    failed: [:archived],
    archived: []
  }

  def create_mission(params) do
    Mission.new(params)
  end

  def transition(mission, from_status, to_status) do
    allowed = Map.get(@valid_transitions, from_status, [])
    if mission.status == from_status and to_status in allowed do
      :ok
    else
      {:error, :invalid_transition}
    end
  end

  def set_status(mission, new_status) do
    {:ok, %{mission | status: new_status}}
  end

  def get_goals(mission) do
    {:ok, mission.goals}
  end

  def get_tasks(mission) do
    {:ok, mission.tasks}
  end

  def get_fingerprint(mission) do
    {:ok, mission.fingerprint}
  end
end
