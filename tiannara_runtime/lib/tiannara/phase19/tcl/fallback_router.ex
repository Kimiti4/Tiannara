defmodule Tiannara.Phase19.TCL.FallbackRouter do
  @moduledoc """
  Baseline reversion & Phase 18 quarantine routing.
  """
  use GenServer
  require Logger

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(opts), do: {:ok, %{conn_name: opts[:connection_name]}}

  @spec trigger_rollback(sync_id :: String.t(), reason :: atom()) :: :ok
  def trigger_rollback(sync_id, reason), do: GenServer.cast(__MODULE__, {:rollback, sync_id, reason})

  @impl true
  def handle_cast({:rollback, sync_id, reason}, state) do
    Logger.warning("🔄 TCL: Triggering baseline rollback for #{sync_id} (reason: #{inspect(reason)})")
    Gnat.pub(state.conn_name, "tiannara.phase19.tcl.rollback.#{sync_id}",
             Jason.encode!(%{sync_id: sync_id, action: :revert_to_phase18, reason: reason}))
    {:noreply, state}
  end
end