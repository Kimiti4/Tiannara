defmodule Tiannara.A10.AttractorMemory do
  @moduledoc """
  Historical attractor memory for A10.
  Maintains phase history, drift lineages, and prior collapse signatures.
  Prevents Tiannara from repeatedly relearning the same failures.
  """
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{
      phase_history: [],
      collapse_signatures: [],
      recovery_archetypes: []
    }}
  end

  def handle_cast({:record_phase, phase}, state) do
    # Keep last 100 phases
    history = [phase | state.phase_history] |> Enum.take(100)
    {:noreply, %{state | phase_history: history}}
  end

  def handle_cast({:record_collapse, signature}, state) do
    {:noreply, %{state | collapse_signatures: [signature | state.collapse_signatures]}}
  end

  def handle_call(:get_history, _from, state) do
    {:reply, state, state}
  end
end
