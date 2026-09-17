defmodule Tiannara.GRCC.EntropyController do
  @moduledoc """
  Aggregates ongoing entropy ticks into the system state.
  """
  use GenServer
  alias Tiannara.EventBus

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{entropy: 0.5}}
  end

  def handle_info({:entropy_tick, delta}, state) do
    new_entropy = state.entropy + delta
    
    if new_entropy > 0.9 do
      EventBus.broadcast("immune.response", :entropy_spike)
    end
    
    {:noreply, %{state | entropy: new_entropy}}
  end
end
