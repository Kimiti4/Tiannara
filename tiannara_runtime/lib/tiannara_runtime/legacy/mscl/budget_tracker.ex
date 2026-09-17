defmodule TiannaraRuntime.Legacy.Tiannara.MSCL.BudgetTracker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{cpu: 0, memory: 0, entropy_budget: 1.0}}
  end

  def handle_call(:consume, _from, state) do
    new = %{state | entropy_budget: state.entropy_budget - 0.01}
    {:reply, new, new}
  end
end
