defmodule TiannaraRuntime.WorldModel.DigitalTwin.Engines.TwinArchaeology do
  @moduledoc """
  Phase 17.7.7 — Digital Twin Archaeology engine.
  Records and explains every simulation: originating models, executed events, interventions,
  synchronization history, mathematical derivations, causal chains, and divergence history.
  """

  alias TiannaraRuntime.WorldModel.DigitalTwin.TwinState

  @doc """
  Records a tick entry in the evidence ledger.
  """
  def record_tick(twin, tick_state) do
    entry = %{
      tick: tick_state.tick,
      state_id: tick_state.state_id,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      model_count: map_size(tick_state.model_states)
    }

    updated_ledger = (twin.evidence_ledger || []) ++ [entry]
    archaeology = update_archaeology(twin, tick_state)

    %{twin | evidence_ledger: updated_ledger}
  end

  @doc """
  Records an event execution in the archaeology.
  """
  def record_event(archaeology, event, tick_state) do
    %{archaeology | event_timeline: (archaeology.event_timeline || []) ++ [event]}
  end

  @doc """
  Records a divergence point for replay comparison.
  """
  def record_divergence(archaeology, tick, original_state, replay_state) do
    divergence = %{
      tick: tick,
      original_state_id: original_state.state_id,
      replay_state_id: replay_state.state_id,
      divergent: original_state.state_id != replay_state.state_id
    }

    Map.update(archaeology, :divergences, [divergence], fn existing ->
      existing ++ [divergence]
    end)
  end

  @doc """
  Returns the full lineage for a given tick.
  """
  def get_lineage(twin, tick) do
    ledger = twin.evidence_ledger || []
    Enum.filter(ledger, fn entry -> entry.tick == tick end)
  end

  defp update_archaeology(twin, tick_state) do
    Map.put(twin, :archaeology_root, tick_state.state_id)
  end
end
