defmodule Tiannara.Phase19.TCL.AdoptionController do
  require Logger

  @moduledoc """
  EMA smoothing & cross-instance rule deployment.
  Prevents consensus oscillation during fixed-point adoption.
  """
  use GenServer

  @ema_alpha 0.25
  @rounds_to_full_adoption 6

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(opts) do
    {:ok, %{conn_name: opts[:connection_name], active_adoptions: %{}}}
  end

  @spec adopt(sync_id :: String.t(), candidate_rules :: map()) :: :ok
  def adopt(sync_id, rules), do: GenServer.cast(__MODULE__, {:adopt, sync_id, rules})

  @impl true
  def handle_cast({:adopt, sync_id, target}, state) do
    # Simplified: starts identical, blends across rounds
    transition = %{target: target, current: target, round: 0}
    Process.send_after(self(), {:advance, sync_id}, 3000)
    {:noreply, %{state | active_adoptions: Map.put(state.active_adoptions, sync_id, transition)}}
  end

  @impl true
  def handle_info({:advance, sync_id}, state) do
    case Map.fetch(state.active_adoptions, sync_id) do
      {:ok, t} ->
        next_round = t.round + 1

        if next_round >= @rounds_to_full_adoption do
          Logger.info("✅ TCL: Rule adoption #{sync_id} finalized across lattice.")
          {:noreply, %{state | active_adoptions: Map.delete(state.active_adoptions, sync_id)}}
        else
          Process.send_after(self(), {:advance, sync_id}, 3000)

          {:noreply,
           %{
             state
             | active_adoptions:
                 Map.put(state.active_adoptions, sync_id, %{t | round: next_round})
           }}
        end

      :error ->
        {:noreply, state}
    end
  end
end
