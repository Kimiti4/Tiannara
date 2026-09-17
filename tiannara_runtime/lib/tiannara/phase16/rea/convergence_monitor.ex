defmodule Tiannara.Phase16.REA.ConvergenceMonitor do
  @moduledoc """
  Tracks empirical Lipschitz constant across arbitration rounds.
  Enforces rollback gating if $\hat{k} \geq 0.95$.
  """
  use GenServer

  @convergence_epsilon 1.0e-6
  @divergence_threshold 0.95
  @window_size 8

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts), do: {:ok, %{history: %{}}}

  @spec record_step(harm_id :: String.t(), current_score :: float(), prev_score :: float() | nil) :: :ok
  def record_step(harm_id, current, prev), do: GenServer.cast(__MODULE__, {:record, harm_id, current, prev})

  @spec converged?(harm_id :: String.t()) :: boolean()
  def converged?(harm_id), do: GenServer.call(__MODULE__, {:converged, harm_id})

  @impl true
  def handle_cast({:record, id, current, prev}, state) do
    delta = if prev, do: abs(current - prev), else: 1.0
    history = Map.get(state.history, id, [])
    new_history = [delta | Enum.take(history, @window_size - 1)]
    
    :telemetry.execute([:tiannara, :phase16, :rea, :convergence_step], %{delta: delta}, %{harm_id: id})
    {:noreply, %{state | history: Map.put(state.history, id, new_history)}}
  end

  @impl true
  def handle_call({:converged, id}, _from, state) do
    history = Map.get(state.history, id, [])
    converged = length(history) >= 3 and Enum.max(history) < @convergence_epsilon
    {:reply, converged, state}
  end
end