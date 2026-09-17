defmodule ObservationBus.CIL.Mission.MissionReplay do
  @moduledoc """
  Replays an entire research campaign from mission inception to completion.

  Uses the timeline and event store to reconstruct the full mission
  narrative, including all milestones, discoveries, and decisions.
  """
  use GenServer

  defstruct [:total_replays]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %__MODULE__{total_replays: 0}}
  end

  @doc "Reconstruct a mission's full narrative."
  @spec reconstruct(String.t()) :: map()
  def reconstruct(mission_id) do
    GenServer.call(__MODULE__, {:reconstruct, mission_id})
  end

  @impl true
  def handle_call({:reconstruct, mission_id}, _from, state) do
    mission = ObservationBus.CIL.Mission.MissionRegistry.get(mission_id)
    timeline = ObservationBus.CIL.Mission.MissionTimeline.get_timeline(mission_id)

    result = %{
      mission: mission,
      events: timeline,
      event_count: length(timeline),
      reconstructed_at: DateTime.utc_now()
    }
    {:reply, result, %{state | total_replays: state.total_replays + 1}}
  end
end
