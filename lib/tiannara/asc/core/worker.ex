defmodule Tiannara.ASC.Core.Worker do
  @moduledoc """
  Generic ASC worker shell.

  Self-registers via the core Registry in init, so a supervisor restart
  re-populates the registry automatically — registry continuity is a
  property of the topology, not of the tests. Runs a handler module
  implementing `handle_request/2`.
  """

  use GenServer

  def name_for(role), do: :"asc_core_worker_#{role}"

  def start_link(%{role: role} = spec) do
    GenServer.start_link(__MODULE__, spec, name: name_for(role))
    |> case do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        {:ok, pid}

      other ->
        other
    end
  end

  @spec call(atom(), term(), timeout()) :: term()
  def call(role, request, timeout \\ 5_000),
    do: GenServer.call(name_for(role), {:handle, request}, timeout)

  def whereis(role) do
    case Process.whereis(name_for(role)) do
      nil -> {:error, :not_registered}
      pid -> {:ok, pid}
    end
  end

  @impl true
  def init(%{role: role, handler: handler, capabilities: capabilities}) do
    state = %{
      role: role,
      handler: handler,
      capabilities: capabilities,
      handler_state:
        if(function_exported?(handler, :init_state, 0), do: handler.init_state(), else: %{}),
      started_at: System.monotonic_time()
    }

    Tiannara.ASC.Core.Registry.register(role, name_for(role), capabilities, :core)

    {:ok, state}
  end

  @impl true
  def handle_call({:handle, request}, _from, %{handler: handler} = state) do
    case handler.handle_request(request, state.handler_state) do
      {:reply, reply, new_handler_state} ->
        {:reply, reply, %{state | handler_state: new_handler_state}}

      {:noreply, new_handler_state} ->
        {:noreply, %{state | handler_state: new_handler_state}}
    end
  end
end