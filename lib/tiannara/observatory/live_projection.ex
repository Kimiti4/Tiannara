defmodule Tiannara.Observatory.LiveProjection do
  @moduledoc """
  Read-only observation projection for the world event stream.

  The projection is rebuilt from EventBus messages and exposes a snapshot plus
  ordered events for framework-neutral observers. It never issues commands or
  mutates world state.
  """

  use GenServer

  alias Tiannara.CEL.Services.EventBus

  @topics ["world.entity.created", "world.mutation.executed"]
  @retry_ms 250

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @spec snapshot() :: {:ok, map()} | {:error, term()}
  def snapshot, do: GenServer.call(__MODULE__, :snapshot)

  @spec events_since(non_neg_integer()) :: {:ok, [map()]} | {:error, term()}
  def events_since(sequence), do: GenServer.call(__MODULE__, {:events_since, sequence})

  @spec status() :: map()
  def status, do: GenServer.call(__MODULE__, :status)

  @impl true
  def init(_opts) do
    state = %{sequence: 0, events: [], entities: %{}, subscribed: false}
    send(self(), :subscribe)
    {:ok, state}
  end

  @impl true
  def handle_info(:subscribe, state) do
    case subscribe_topics() do
      :ok -> {:noreply, %{state | subscribed: true}}
      {:error, _reason} ->
        Process.send_after(self(), :subscribe, @retry_ms)
        {:noreply, state}
    end
  end

  def handle_info({:event, event}, state) do
    sequence = state.sequence + 1
    projection_event = %{sequence: sequence, topic: topic_for(event), event: event}
    entities = apply_observation(state.entities, projection_event)

    {:noreply, %{state | sequence: sequence, events: state.events ++ [projection_event], entities: entities}}
  end

  @impl true
  def handle_call(:snapshot, _from, state) do
    {:reply, {:ok, %{sequence: state.sequence, entities: state.entities}}, state}
  end

  def handle_call({:events_since, sequence}, _from, state) when is_integer(sequence) and sequence >= 0 do
    {:reply, {:ok, Enum.filter(state.events, &(&1.sequence > sequence))}, state}
  end

  def handle_call({:events_since, _sequence}, _from, state),
    do: {:reply, {:error, :invalid_sequence}, state}

  def handle_call(:status, _from, state) do
    {:reply, %{sequence: state.sequence, event_count: length(state.events), subscribed: state.subscribed}, state}
  end

  defp subscribe_topics do
    if Process.whereis(EventBus) do
      Enum.each(@topics, &EventBus.subscribe/1)
      :ok
    else
      {:error, :event_bus_unavailable}
    end
  rescue
    error -> {:error, error}
  end

  defp topic_for(%{routing_destination: topic}), do: topic
  defp topic_for(_event), do: :unknown

  defp apply_observation(entities, %{topic: "world.entity.created", event: event}) do
    payload = Map.get(event, :raw_payload, %{})
    entity_id = Map.get(payload, :entity_id)
    if is_nil(entity_id), do: entities, else: Map.put(entities, entity_id, payload)
  end

  defp apply_observation(entities, _event), do: entities
end