defmodule Tiannara.Phase19.TCL.FixedPointVerifier do
  @moduledoc """
  Equivalence sampling & Banach convergence tracking.
  Enforces $\|\theta^{(n+1)} - \theta^{(n)}\| < \epsilon_{tcl}$.
  """
  use GenServer

  @epsilon_tcl 1.0e-5
  @sample_size 500
  @convergence_window 8

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts), do: {:ok, %{history: %{}}}

  @spec record_step(sync_id :: String.t(), instance_a :: String.t(), instance_b :: String.t(), diff :: float()) :: :ok
  def record_step(sync_id, a, b, diff), do: GenServer.cast(__MODULE__, {:record, sync_id, a, b, diff})

  @spec converged?(sync_id :: String.t()) :: boolean()
  def converged?(sync_id), do: GenServer.call(__MODULE__, {:check, sync_id})

  @impl true
  def handle_cast({:record, sync_id, _a, _b, diff}, state) do
    history = Map.get(state.history, sync_id, [])
    new_history = [diff | Enum.take(history, @convergence_window - 1)]
    :telemetry.execute([:tiannara, :phase19, :tcl, :convergence_step], %{diff: diff}, %{sync_id: sync_id})
    {:noreply, %{state | history: Map.put(state.history, sync_id, new_history)}}
  end

  @impl true
  def handle_call({:check, sync_id}, _from, state) do
    history = Map.get(state.history, sync_id, [])
    converged = length(history) >= 3 and Enum.max(history) < @epsilon_tcl
    {:reply, converged, state}
  end
end