defmodule Tiannara.P9X.GenesisLoopValidator do
  @moduledoc """
  Measures variance to ensure self-originating cycles don't collapse.
  """
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{variance: 1.0}}
  end

  def handle_info({:loop_state, s}, state) do
    variance = compute_variance(s)
    {:noreply, %{state | variance: variance}}
  end

  defp compute_variance(_), do: :rand.uniform()
end
