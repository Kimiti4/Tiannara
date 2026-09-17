defmodule TiannaraRuntime.Legacy.Tiannara.MSCL.DivergenceAnalyzer do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{divergence: 0.0}}
  end

  def handle_info({:analyze, data}, state) do
    divergence = compute_divergence(data)
    {:noreply, %{state | divergence: divergence}}
  end

  defp compute_divergence(data), do: :math.log(length(data) + 1)
end
