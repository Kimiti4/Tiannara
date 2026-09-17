defmodule Tiannara.Phase14.Formal.ViewChangeEngine do
  require Logger

  @moduledoc "Leader rotation & timeout handling for BFT liveness"
  use GenServer

  @view_timeout_ms 2000

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(opts) do
    {:ok, %{conn_name: opts[:connection_name], active_views: %{}, timers: %{}}}
  end

  @doc "Start view for a round"
  @spec start_view(round_id :: String.t(), leader :: String.t()) :: :ok
  def start_view(rid, leader), do: GenServer.cast(__MODULE__, {:view, rid, leader})

  @impl true
  def handle_cast({:view, rid, leader}, state) do
    timer = Process.send_after(self(), {:view_timeout, rid}, @view_timeout_ms)

    Gnat.pub(
      state.conn_name,
      "tiannara.reg.bft.view_start",
      Jason.encode!(%{round_id: rid, leader: leader})
    )

    {:noreply,
     %{
       state
       | active_views: Map.put(state.active_views, rid, leader),
         timers: Map.put(state.timers, rid, timer)
     }}
  end

  @impl true
  def handle_info({:view_timeout, rid}, state) do
    Logger.warning("⏳ BFT: View timeout for round #{rid}. Triggering leader rotation.")
    new_leader = select_next_leader(Map.get(state.active_views, rid))

    Gnat.pub(
      state.conn_name,
      "tiannara.reg.bft.view_change",
      Jason.encode!(%{round_id: rid, new_leader: new_leader})
    )

    {:noreply, Map.delete(state.active_views, rid) |> Map.delete(:timers)}
  end

  # Simplified; in prod: deterministic round-robin
  defp select_next_leader(current), do: current <> "_rotated"
end
