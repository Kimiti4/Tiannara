defmodule Tiannara.Sentinel.Immune.StabilizationAuditor do
  @moduledoc """
  An append-only immutable store of all formulated recommendations.
  Provides Sentinel with constitutional memory.
  """
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def record(intervention) do
    GenServer.cast(__MODULE__, {:record, intervention})
  end

  def get_history() do
    GenServer.call(__MODULE__, :get_history)
  end
  
  def get_pending() do
    GenServer.call(__MODULE__, :get_pending)
  end

  @impl true
  def init(_opts) do
    {:ok, %{history: [], pending: []}}
  end

  @impl true
  def handle_cast({:record, intervention}, state) do
    # Append-only. Never modify an existing record.
    new_history = [intervention | state.history]
    new_pending = [intervention | state.pending]
    {:noreply, %{state | history: new_history, pending: new_pending}}
  end

  @impl true
  def handle_call(:get_history, _from, state) do
    {:reply, state.history, state}
  end

  @impl true
  def handle_call(:get_pending, _from, state) do
    {:reply, state.pending, state}
  end
end
