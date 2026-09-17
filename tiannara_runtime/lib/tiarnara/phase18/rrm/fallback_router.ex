defmodule Tiarnara.Phase18.RRM.FallbackRouter do
  @moduledoc """
  Baseline reversion & Phase 17 quarantine routing.
  """
  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(opts) do
    {:ok, %{conn_name: opts[:connection_name], baseline_cache: %{}}}
  end

  @spec trigger_rollback(proposal_id :: String.t(), surface_id :: String.t(), baseline :: map()) :: :ok
  def trigger_rollback(id, surface, baseline), do: GenServer.cast(__MODULE__, {:rollback, id, surface, baseline})

  @impl true
  def handle_cast({:rollback, id, surface, baseline}, state) do
    Gnat.pub(state.conn_name, "tiarnara.phase18.rrm.rollback.#{id}",
             Jason.encode!(%{proposal_id: id, surface: surface, fallback_rules: baseline}))
    {:noreply, %{state | baseline_cache: Map.put(state.baseline_cache, surface, baseline)}}
  end
end