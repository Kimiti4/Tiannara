defmodule TiannaraRuntime.WorldEventProcessor do
  use GenServer
  require Logger

  defstruct [
    world_id: nil,
    nats_connection: nil
  ]

  def start_link(world_config) do
    GenServer.start_link(__MODULE__, world_config)
  end

  def publish_cal_event(pid, event_data) do
    GenServer.cast(pid, {:publish_cal_event, event_data})
  end

  def publish_cis_event(pid, event_data) do
    GenServer.cast(pid, {:publish_cis_event, event_data})
  end

  def publish_state_update(pid, state_data) do
    GenServer.cast(pid, {:publish_state_update, state_data})
  end

  def publish_memory_snapshot(pid, snapshot_data) do
    GenServer.cast(pid, {:publish_memory_snapshot, snapshot_data})
  end

  def publish_world_event(pid, event_type, payload) do
    GenServer.cast(pid, {:publish_world_event, event_type, payload})
  end

  @impl true
  def init(world_config) do
    world_id = world_config.id
    {:ok, %__MODULE__{
      world_id: world_id,
      nats_connection: nil
    }}
  end

  @impl true
  def handle_cast({:publish_cal_event, event_data}, state) do
    topic = "tiannara.world.#{state.world_id}.cal"
    message = %{
      world_id: state.world_id,
      type: "cal_decision",
      payload: event_data,
      timestamp: :erlang.unique_integer([:positive])
    }
    publish_to_nats(topic, message)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:publish_cis_event, event_data}, state) do
    topic = "tiannara.world.#{state.world_id}.cis"
    message = %{
      world_id: state.world_id,
      type: "cis_intervention",
      payload: event_data,
      timestamp: :erlang.unique_integer([:positive])
    }
    publish_to_nats(topic, message)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:publish_state_update, state_data}, state) do
    topic = "tiannara.world.#{state.world_id}.state"
    message = %{
      world_id: state.world_id,
      type: "state_update",
      payload: state_data,
      timestamp: :erlang.unique_integer([:positive])
    }
    publish_to_nats(topic, message)
    publish_to_nats("tiannara.worlds.all.state", message)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:publish_memory_snapshot, snapshot_data}, state) do
    topic = "tiannara.world.#{state.world_id}.memory"
    message = %{
      world_id: state.world_id,
      type: "memory_snapshot",
      payload: snapshot_data,
      timestamp: :erlang.unique_integer([:positive])
    }
    publish_to_nats(topic, message)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:publish_world_event, event_type, payload}, state) do
    topic = "tiannara.world.#{state.world_id}.event"
    message = %{
      world_id: state.world_id,
      type: event_type,
      payload: payload,
      timestamp: :erlang.unique_integer([:positive])
    }
    publish_to_nats(topic, message)
    {:noreply, state}
  end

  defp publish_to_nats(topic, message) do
    json_payload = Jason.encode!(message)
    TiannaraRuntime.NATS.Bus.publish(topic, json_payload)
  end
end
