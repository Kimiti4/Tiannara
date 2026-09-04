defmodule Tiannara.ASC.Civilization.SustainabilityEngine do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def evaluate(world_state) do
    GenServer.call(__MODULE__, {:evaluate, world_state})
  end

  @impl true
  def init(_opts), do: {:ok, %{evaluations: 0}}

  @impl true
  def handle_call({:evaluate, world_state}, _from, state) do
    ecology = Map.get(world_state, :ecology, 0.4)
    energy = Map.get(world_state, :energy, 0.4)
    score = ecology * 0.4 + energy * 0.3 + Map.get(world_state, :sustainability_index, 0.4) * 0.3

    result = %{
      score: score, dimensions: %{ecology: ecology, energy: energy, resources: (ecology + energy) / 2},
      status: classify(score), recommendations: recs(ecology, energy), evaluated_at: DateTime.utc_now()
    }
    {:reply, {:ok, result}, %{state | evaluations: state.evaluations + 1}}
  end

  def handle_info(_, state), do: {:noreply, state}

  defp classify(s) when s > 0.7, do: :sustainable
  defp classify(s) when s > 0.5, do: :transitional
  defp classify(s) when s > 0.3, do: :at_risk
  defp classify(_), do: :critical

  defp recs(ecology, energy) do
    (if ecology < 0.5, do: [%{priority: :high, action: "Ecological restoration programs"}], else: [])
    ++ (if energy < 0.5, do: [%{priority: :high, action: "Accelerate renewable energy transition"}], else: [])
  end
end
