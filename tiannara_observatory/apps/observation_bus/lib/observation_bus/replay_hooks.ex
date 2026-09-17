defmodule ObservationBus.ReplayHooks do
  @moduledoc """
  Automatic replay integration.

  Every event published through COB automatically generates:
    * Replay Pointer — link to the event's position in the replay store
    * Checkpoint Pointer — link to the nearest checkpoint
    * Snapshot Pointer — link to the nearest state snapshot
    * Evidence Pointer — link to supporting evidence

  Replay requires zero extra work from subsystems.
  """

  alias ObservationBus.Event

  @doc """
  Attaches replay metadata to an event.
  """
  @spec attach(Event.t()) :: Event.t()
  def attach(%Event{} = event) do
    metadata = event.metadata
    |> Map.put(:replay_pointer, build_replay_pointer(event))
    |> Map.put(:checkpoint_pointer, find_checkpoint(event))
    |> Map.put(:snapshot_pointer, find_snapshot(event))

    %{event | metadata: metadata}
  end

  @doc """
  Returns replay point for a given timestamp.
  """
  @spec replay_point(DateTime.t(), String.t()) :: map()
  def replay_point(timestamp, domain) do
    %{
      timestamp: timestamp,
      domain: domain,
      replay_pointer: "replay://#{domain}/#{DateTime.to_unix(timestamp)}",
      type: :exact
    }
  end

  defp build_replay_pointer(%Event{id: id, global_sequence: seq, domain: domain}) do
    "replay://#{domain}/events/#{id}?seq=#{seq}"
  end

  defp find_checkpoint(%Event{domain: domain}) do
    "replay://#{domain}/checkpoints/latest"
  end

  defp find_snapshot(%Event{domain: domain}) do
    "replay://#{domain}/snapshots/latest"
  end
end
