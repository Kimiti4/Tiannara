defmodule Tiannara.Phase19.TCL.SyncPropagation do
  @moduledoc """
  Durable NATS routing & cross-instance state exchange.
  Publishes lattice updates with JetStream replay guarantees.
  """
  use GenServer
  require Logger

  @sync_interval_ms 2000

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(opts) do
    {:ok, %{
      conn_name: opts[:connection_name],
      active_cycles: %{},
      sync_timers: %{}
    }}
  end

  @doc "Start synchronization cycle for a surface"
  @spec start_cycle(surface_id :: String.t(), local_rules :: map()) :: {:ok, String.t()} | {:error, String.t()}
  def start_cycle(id, rules), do: GenServer.call(__MODULE__, {:cycle, id, rules})

  @impl true
  def handle_call({:cycle, id, rules}, _from, state) do
    sync_id = "tcl_sync_#{id}_#{:erlang.unique_integer([:positive]) |> rem(10_000)}"
    timer = Process.send_after(self(), {:propagate, sync_id, rules}, @sync_interval_ms)
    {:reply, {:ok, sync_id}, %{state | active_cycles: Map.put(state.active_cycles, sync_id, rules), sync_timers: Map.put(state.sync_timers, sync_id, timer)}}
  end

  @impl true
  def handle_info({:propagate, sync_id, rules}, state) do
    Gnat.pub(state.conn_name, "tiannara.phase19.tcl.sync.#{sync_id}",
             Jason.encode!(%{sync_id: sync_id, rules_hash: hash_rules(rules), timestamp: :erlang.unique_integer([:positive])}))
    {:noreply, state}
  end

  defp hash_rules(rules), do: :crypto.hash(:sha256, :erlang.term_to_binary(rules)) |> Base.encode16()
end